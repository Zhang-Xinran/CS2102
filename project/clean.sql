create or replace procedure add_course_package 
	(package_name text, num_of_free_sessions integer, start_date date, end_date date, price decimal(5, 2))
as $$
begin
insert into Course_packages (name, sale_start_date, sale_end_date, num_free_registration, price)
	values (package_name, start_date, end_date, num_of_free_sessions, price);
end;
$$ language plpgsql;

create or replace function get_available_course_packages()
returns table (id int, name text, num_free_registration int, sale_end_date date, price decimal(5, 2)) as $$
	select C.package_id, C.name, C.num_free_registration, C.sale_end_date, C.price
	from Course_packages C
	where sale_end_date >= (select current_date);
$$ language sql;

create or replace procedure buy_course_package 
	(cid integer, pid integer)
as $$
declare 
	buy_date date;
	card text;
	num_free_registration int;
begin
	buy_date := (select current_date);
	card := (select card_number from Owns C where C.cust_id = cid);
	num_free_registration := (select CP.num_free_registration from Course_packages CP where CP.package_id = pid);
	insert into Buys (buy_date, package_id, card_number, cust_id, num_remaining_redemptions) 
		values (buy_date, pid, card, cid, num_free_registration);
end;
$$ language plpgsql;

create or replace function check_refundable
	(in buy_d date, in cid int, in card text, in pid int, out res int)
returns integer as $$
declare
	curs cursor for (select * from Redeems R where R.buy_date = buy_d and R.cust_id = cid and R.card_number = card and R.pid = package_id);
	r record;
begin
	res := 1;
	open curs;
	loop
		fetch curs into r;
		exit when not found;
		if ((select current_date) - (select session_date from Sessons S where S.sid = r.sid and S.offering_id = r.offering_id) < 7) then
			res := 0; 
		end if;
	end loop;
end;	
$$ language plpgsql;

create or replace function get_redeemed_session
	(in buy_d date, in cid int, in card text, in pid int)
returns table (session_name text, session_date date, session_start_hour int) as $$
declare
	cur cursor for (select * from Redeems R where R.buy_date = buy_d and R.cust_id = cid and R.card_number = card and R.package_id = pid);
	r record;

begin
	open cur;
	loop
		fetch cur into r;
		exit when not found;
		session_name := (select title from Courses where course_id = (select course_id from Offerings O where O.offering_id = r.offering_id));
		session_date := (select S.session_date from Sessions S where S.sid = r.sid and S.offering_id = r.offering_id);
		session_start_hour := (select start_time from Sessions S where S.sid = r.sid and S.offering_id = r.offering_id);
		return next;
	end loop;
	close cur;
end;
$$ language plpgsql;

create or replace function get_redeemed_session_in_json
	(in buy_d date, in cid int, in card text, in pid int)
returns json[] as $$
declare
	c cursor for (select * from get_redeemed_session(buy_d, cid, card, pid) order by (session_date, session_start_hour) asc);
	temp json;
	r record;
	res json[];
begin
	res := array[]::json[];
	open c;
	loop
		fetch c into r;
		exit when not found;
		temp := json_build_object(
			'session_name', r.session_name,
			'session_dates', r.session_date,
			'session_start_hour', r.session_start_hour
		);
		res := array_append(res, temp);
	end loop;
	close c;
	return res;
end;
$$ language plpgsql;

create or replace function get_my_course_package 
	(in cid int, out res json)
returns json as $$
declare
	name text;
	purchase_date date;
	package_price decimal(5, 2);
	num_free_sessions int;
	num_available_sessions int;
	curs cursor for (select * from Buys where cust_id = cid);
	r record;
	redeemed_sessions json[];
begin
	open curs;
	loop
		fetch curs into r;
		exit when not found;
		if (r.num_remaining_redemptions > 0 or 
			(select check_refundable(r.buy_date, r.cust_id, r.card_number, r.package_id)) = 1) then
			name := (select CP.name from Course_packages CP where CP.package_id = r.package_id);
			purchase_date := r.buy_date;
			package_price := (select price from Course_packages CP where CP.package_id = r.package_id);
			num_free_sessions := (select num_free_registration from Course_packages CP where CP.package_id = r.package_id);
			num_available_sessions := r.num_remaining_redemptions; 
			redeemed_sessions := (select get_redeemed_session_in_json(r.buy_date, r.cust_id, r.card_number, r.package_id));
			res := json_build_object(
				'package_name', name, 
				'purchase_date', purchase_date, 
				'package_price', package_price,
				'num_free_sessions', num_free_sessions,
				'num_available_sessions', num_available_sessions,
				'redeemed_sessions', redeemed_sessions
			);

		end if;
	end loop;
	close curs;

end;
$$ language plpgsql;

create or replace function get_my_active_course_package
	(in cid int, out res record)
returns record as $$
declare
	curs cursor for (select * from Buys where cust_id = cid);
	r record;
begin
	open curs;
	loop
		fetch curs into r;
		if (r.num_remaining_redemptions > 0) then
			res := r;
			return;
		end if;
	end loop;
	close curs;
end;
$$ language plpgsql;

create or replace procedure register_session
	(cid int, coid int, session_id int, paymentMethod int)
as $$
declare
	available_package record;
begin
	if (paymentMethod = 1) then
		insert into Registers (registration_date, card_number, cust_id, offering_id, sid)
			values ((select current_date),
				(select card_number from Owns where cust_id = cid),
				cid, coid, session_id);
	else
		available_package := (select get_my_active_course_package(cid));
		if (available_package = null) then
			raise notice 'No active package.';
		else
			insert into Redeems (redemption_date, buy_date, package_id, card_number, cust_id, offering_id, sid)
				values ((select current_date),
					available_package.buy_date,
					available_package.package_id,
					available_package.card_number,
					available_package.cust_id,
					coid, session_id);
			if (select count(*) from Redeems R where R.cust_id = cid and R.offering_id = coid) = 1 then
				update Buys
			 		set num_remaining_redemptions = num_remaining_redemptions - 1
					where buy_date = available_package.buy_date and 
						package_id = available_package.package_id and
						card_number = available_package.card_number and
						cust_id = available_package.cust_id;
			end if;
		end if;
	end if;
end;
$$ language plpgsql;


create or replace function get_my_registered_sessions
	(in cid int)
returns table 
(course_name text, course_fee decimal(5, 2), session_date date, start_hour integer, duration integer, instructor text) as $$
declare
	curs_registers cursor for (select * from Registers where cust_id = cid);
	curs_redeems cursor for (select * from Redeems where cust_id = cid);
	r record;
	deadline date;
begin
	open curs_registers;
	loop
		fetch curs_registers into r;
		exit when not found;
		deadline := (select registration_deadline from Offerings O where O.offering_id = r.offering_id);
		if (deadline >= (select current_date)) then
			course_name := (select title from Courses C where C.course_id = (select course_id from Offerings O where O.offering_id = r.offering_id));
			course_fee := (select fees from Offerings O where O.offering_id = r.offering_id);
			session_date := (select S.session_date from Sessions S where S.offering_id = r.offering_id and S.sid = r.sid);
			start_hour := (select start_time from Sessions S where S.offering_id = r.offering_id and S.sid = r.sid);
			duration := (select end_time from Sessions S where S.offering_id = r.offering_id and S.sid = r.sid) - start_hour;
			instructor := (select name from Employees E where E.eid = (select eid from Sessions S where S.offering_id = r.offering_id and S.sid = r.sid));
			return next;
		end if;
	end loop;
	close curs_registers;
	open curs_redeems;
	loop
		fetch curs_redeems into r;
		exit when not found;
		deadline := (select registration_deadline from Offerings O where O.offering_id = r.offering_id);
		if (deadline >= (select current_date)) then
			course_name := (select title from Courses C where C.course_id = (select course_id from Offerings O where O.offering_id = r.offering_id));
			course_fee := (select fees from Offerings O where O.offering_id = r.offering_id);
			session_date := (select S.session_date from Sessions S where S.offering_id = r.offering_id and S.sid = r.sid);
			start_hour := (select start_time from Sessions S where S.offering_id = r.offering_id and S.sid = r.sid);
			duration := (select end_time from Sessions S where S.offering_id = r.offering_id and S.sid = r.sid) - start_hour;
			instructor := (select name from Employees E where E.eid = (select eid from Sessions S where S.offering_id = r.offering_id and S.sid = r.sid));
			return next;
		end if;
	end loop;
	close curs_redeems;
end; 
$$ language plpgsql;

create or replace function get_my_registrations
	(in cid int)
returns table (course_name text, course_fee decimal(5, 2), 
	session_date date, start_hour integer, duration integer, instructor text) as $$
begin
	return query select * 
	from (select * from get_my_registered_sessions(cid)) as T
	order by (T.session_date, T.start_hour) asc;
end;
$$ language plpgsql;

create or replace function get_payment_type
	(in cid int, in coid int, out payment_type int)
as $$
begin
	if (select count(*) from Registers where cid = cust_id and coid = offering_id) = 1 then
		payment_type = 1;
	else 
		if (select count(*) from Redeems where cid = cust_id and coid = offering_id) = 1 then
			payment_type = 2;
		else
			payment_type = 0;
		end if;
	end if;

end;
$$ language plpgsql;

create or replace procedure update_course_session
	(cid int, coid int, new_sid int)
as $$
declare payment_type int;
begin
	payment_type := (select get_payment_type(cid, coid));
	if payment_type = 0 then
		raise notice 'No registered session.';
	end if;
	if  payment_type = 1 then
		update Registers
			set sid = new_sid
			where cust_id = cid and coid = offering_id;
	end if;
	if payment_type = 2 then
		update Redeems
			set sid = new_sid
			where cust_id = cid and coid = offering_id;
	end if;
end;
$$ language plpgsql;

create or replace function top_packages_sales
	(N int)
returns table (package_id int, count int) as $$
begin
	return query select * 
	from (
		select B.package_id, count(*)::int as count
		from Buys B
		where (select sale_start_date from Course_packages CP where CP.package_id = B.package_id) >= '2021-01-01'
			and (select sale_start_date from Course_packages CP where CP.package_id = B.package_id) <= '2021-12-31'
		group by B.package_id
		order by count desc
	) as T
	where T.count >= coalesce((
		select R.count 
		from (
			select B.package_id, count(*)::int as count
			from Buys B
			where (select sale_start_date from Course_packages CP where CP.package_id = B.package_id) >= '2021-01-01'
				and (select sale_start_date from Course_packages CP where CP.package_id = B.package_id) <= '2021-12-31'
			group by B.package_id
			order by count desc
			offset N - 1
			limit 1
		) as R 
	), 0);
end;
$$ language plpgsql;

create or replace function top_packages_unsorted
	(N int)
returns table (package_id int, num_free_sessions int, price decimal(5, 2), start_date date, end_date date, num_of_sales int) as $$
begin
	return query
	select T.package_id, CP.num_free_registration, CP.price, CP.sale_start_date, CP.sale_end_date, T.count
	from (select * from top_packages_sales(N)) as T, Course_packages CP
	where T.package_id = CP.package_id;
end;
$$ language plpgsql;

create or replace function top_packages
	(N int)
returns table (package_id int, num_free_sessions int, price decimal(5, 2), start_date date, end_date date, num_of_sales int) as $$
begin
	return query select * 
	from (select * from top_packages_unsorted(N)) as T
	order by (T.num_free_sessions, T.price) desc;
end;
$$ language plpgsql;

create or replace function limit_session_quota()
returns trigger as $$
declare
	num_of_registrations int;
	num_of_redemptions int;
	num_of_capacity int;
begin
	num_of_registrations := (select count(*) from Registers R where new.offering_id = R.offering_id and new.sid = R.sid);
	num_of_redemptions := (select count(*) from Redeems R where new.offering_id = R.offering_id and new.sid = R.sid);
	num_of_capacity := (select seating_capacity from Rooms R where R.rid = (select rid from Sessions S where new.offering_id = S.offering_id and new.sid = S.sid ));
	if (num_of_capacity > num_of_registrations + num_of_redemptions) then
		return new;
	else
		return null;
	end if;
end;
$$ language plpgsql;

create trigger limit_session_quota_in_registers
before insert or update on Registers
for each row execute function limit_session_quota();

create trigger limit_session_quota_in_redeems
before insert or update on Redeems
for each row execute function limit_session_quota();

create or replace function limit_session_time()
returns trigger as $$
declare registration_deadline date;
begin
	registration_deadline := (select O.registration_deadline from Offerings O where O.offering_id = new.offering_id);
	if (registration_deadline >= (select current_date)) then
		return new;
	else
		raise notice 'The registration has eneded.';
		return null;
	end if;
end;
$$ language plpgsql;

create trigger limit_session_time_in_registers
before insert or update on Registers
for each row execute function limit_session_time();

create trigger limit_session_time_in_redeems
before insert or update on Redeems
for each row execute function limit_session_time();


create or replace function limit_session_per_person()
returns trigger as $$
declare
	num_in_registers int;
	num_in_redeems int;
begin
	num_in_registers := (select count(*) from Registers R where R.cust_id = new.cust_id and R.offering_id = new.offering_id);
	num_in_redeems := (select count(*) from Redeems R where R.cust_id = new.cust_id and R.offering_id = new.offering_id);
	if (num_in_redeems + num_in_registers) > 0 then
		raise notice 'The customer has already registered for a session under the offering';
		return null;
	else
		return new;
	end if;
end;
$$ language plpgsql;

create trigger limit_session_per_person_in_registers
before insert on Registers
for each row execute function limit_session_per_person();

create trigger limit_session_per_person_in_redeems
before insert on Redeems
for each row execute function limit_session_per_person();

create or replace function limit_active_package_per_person()
returns trigger as $$
begin
	if (select * from get_my_course_package(new.cust_id)) is null then
		return new;
	else
		raise notice 'The customer has already owned an active or pactially active package.';
		return null;
	end if;
end;
$$ language plpgsql;

create trigger limit_active_package_per_person_in_course_package
before insert on Buys
for each row execute function limit_active_package_per_person();