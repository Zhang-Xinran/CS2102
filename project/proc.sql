-- drop
drop procedure if exists add_course_package, buy_course_package, register_session, update_course_session;
drop function if exists get_available_course_packages, check_refundable, get_redeemed_session, get_redeemed_session_in_json, get_my_course_package;
drop function if exists get_my_active_course_package, get_my_registered_sessions, get_my_registrations, get_payment_type, top_packages_sales, top_packages_unsorted, top_packages;
drop function if exists limit_session_quota, limit_session_time, limit_session_per_person, limit_active_package_per_person;
drop function if exists update_offerings_seating_capacity, update_offerings_date;
drop function if exists add_course, find_rooms, get_available_rooms, get_available_course_sessions;
drop function if exists update_room, remove_session, add_session, view_manager_report;
drop procedure if exists add_employee;
drop procedure if exists remove_employee;
drop function if exists update_depart_date;
drop function if exists get_work_hour;
drop function if exists get_work_day;
drop function if exists all_em_work_hour;
drop function if exists find_instructors;
drop function if exists get_available_instructors;
drop function if exists cancel_registration;
drop function if exists update_instructor;
drop function if exists update_session_eid;
drop function if exists pay_salary;
drop function if exists reject_delete_employee;

drop trigger if exists limit_session_quota_in_registers on Registers;
drop trigger if exists limit_session_quota_in_redeems on Redeems;
drop trigger if exists limit_session_time_in_registers on Registers;
drop trigger if exists limit_session_time_in_redeems on Redeems;
drop trigger if exists limit_active_package_per_person_in_course_package on Course_packages;
drop trigger if exists update_offerings_date_trigger on Sessions;
drop trigger if exists update_offerings_seating_capacity_trigger on Sessions;
drop trigger if exists update_instructor_trigger on Sessions;
drop trigger if exists remove_employee_trigger on Employees;
drop trigger if exists delete_employee_trigger on Employees;

-- 1. add_employee
CREATE OR REPLACE PROCEDURE add_employee (e_name TEXT, home_address text, phone_num integer, email_add text, salary_info decimal(5,2), join_d date, cat text, area text[], status integer)  AS $$
DECLARE i text;
	e_id integer;
BEGIN
	IF (cat not in ('Manager','Instructor','Administrator') 
		or (status=0 and cat='Manager')
		or ((array_length(area,1) is not null or status =0) and cat='Administrator') 
		or ((array_length(area,1) is null or status =0) and cat='Instructor')) 
	THEN RAISE NOTICE 'Invalid input.';
		RETURN;
	END IF;
	INSERT into Employees(phone, name, address,email,join_date) values (phone_num, e_name, home_address, email_add, join_d);
	e_id:= (select eid from Employees where phone=phone_num);
	IF cat='Manager' 
	THEN 
		INSERT into Full_time_emp(eid,monthly_salary) values (e_id, salary_info);
		INSERT into Managers(eid) values (e_id);
		FOREACH i in array area
		LOOP 
			INSERT INTO Course_areas(area_name,eid) values(i,e_id);
		END LOOP;

	ELSEIF cat='Instructor'
	THEN INSERT INTO Instructors(eid) values(e_id);
		FOREACH i in array area
		LOOP 
			INSERT INTO Specializes(eid,area_name) values(e_id,i);
		END LOOP;
		IF status=1
		-- The instructor is full-timer if status is 1
		THEN 
			INSERT INTO Full_time_emp(eid,monthly_salary) values(e_id,salary_info);
			INSERT INTO Full_time_instructors(eid) values(e_id);
		ELSE 
			INSERT INTO Part_time_emp(eid,hourly_rate) values(e_id,salary_info);
			INSERT INTO Part_time_instructors(eid) values(e_id);
		END IF;

	ELSE
		INSERT INTO Full_time_emp(eid,monthly_salary) values(e_id,salary_info);
		INSERT INTO Administrators(eid) values(e_id);
	END IF;
END;
$$ LANGUAGE plpgsql;

-- 2. remove_employee
CREATE OR REPLACE PROCEDURE remove_employee(employee_id integer,d_date date) AS $$
BEGIN
	UPDATE employees set depart_date=d_date where eid=employee_id;
END;
$$ LANGUAGE plpgsql;

-- 3. add_customer
CREATE OR REPLACE PROCEDURE add_customer(name1 IN TEXT, home_address1 IN TEXT, contact_number1 IN TEXT, email1 IN TEXT, card_number1 IN TEXT, expiry_date1 IN DATE, cvv1 IN INTEGER)
AS $$

BEGIN
INSERT INTO customers(address,phone,name,email)
values(home_address1,contact_number1,name1,email1);

INSERT INTO credit_cards(card_number,expiry_date,cvv)
values(card_number1,expiry_date1,cvv1);

INSERT INTO owns(from_date,card_number,cust_id)
values(current_date,card_number1,(select currval(pg_get_serial_sequence('customers', 'cust_id'))));

RAISE NOTICE'New customer and credit card information successfully recorded.';
END;
$$ LANGUAGE plpgsql;

-- 4. update_credit_card
CREATE OR REPLACE PROCEDURE update_credit_card(cid INTEGER, card_number_new TEXT, expiry_date1 DATE, cvv1 INTEGER) AS $$

BEGIN

IF cid not in (select cid from customers) THEN
    RAISE NOTICE 'Customer does not exist.';
    return;
END IF;

IF card_number_new not in (select card_number from credit_cards) THEN
    INSERT INTO credit_cards(card_number,expiry_date,cvv)
    values(card_number_new,expiry_date1,cvv1);
END IF;

INSERT INTO Owns(from_date, cust_id,card_number)
   values (current_date, cid,card_number_new);
RAISE NOTICE 'Ownership information updated.';
END;
$$ LANGUAGE plpgsql;

-- 5. add_course
CREATE OR REPLACE FUNCTION add_course(title text,  duration int, description text, area_name text)
RETURNS void AS $$
BEGIN
    INSERT INTO Courses(course_id, title, duration, description, area_name)
    VALUES (default, title,  duration, description, area_name);
END;
$$ LANGUAGE plpgsql;

-- 6. find_instructors
--Helper function to get employee's working hour/day of the current month
CREATE OR REPLACE FUNCTION get_work_hour (IN employee_id INT, OUT work_hour numeric)
RETURNS NUMERIC AS $$
BEGIN
	IF employee_id in (
		select eid from Full_time_emp)
	THEN work_hour:= null;
	ELSE work_hour:= (
		select coalesce(sum(end_time-start_time),0)
		from Sessions
		where eid=employee_id
		and (select extract(month from session_date))=(select extract(month from current_date))
		and (select extract(year from session_date))=(select extract(year from current_date))
		);
	END IF;
END;
$$ LANGUAGE plpgsql;



CREATE OR REPLACE FUNCTION get_work_day (IN employee_id INT, OUT work_day INT)
RETURNS INTEGER AS $$
DECLARE first_work_day integer;
	last_work_day integer;
BEGIN
	IF employee_id in (
		select eid from Part_time_emp)
	THEN work_day:= null;
	ELSE 
		first_work_day:=(
			select case 
			when ( (select extract(month from join_date))=(select extract(month from current_date))
				and (select extract(year from join_date))=(select extract(year from current_date)) )
			then (select extract(day from join_date))
			else 1 end
			from Employees
			where eid=employee_id
			);
		last_work_day:=(
			select case 
			when depart_date is null
			then (select extract(days FROM date_trunc('month', now()) + interval '1 month - 1 day'))
			else (select extract(days from depart_date)) end
			from Employees
			where eid=employee_id
			);
		work_day:= last_work_day - first_work_day + 1;
	END IF;
END;
$$ LANGUAGE plpgsql;


-- helper function to get the number of working hours for all employees in the month of the session_date
CREATE OR REPLACE FUNCTION all_em_work_hour (IN employee_id INT, IN d date, OUT work_hour numeric)
RETURNS NUMERIC AS $$
BEGIN
	work_hour:= (
		select coalesce(sum(end_time-start_time),0)
		from Sessions
		where eid=employee_id
		and (select extract(month from session_date))=(select extract(month from d))
		and (select extract(year from session_date))=(select extract(year from d))
		);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION find_instructors(c_id integer,s_date date,s_time integer)
RETURNS Table(employee_id integer,employee_name text) AS $$
DECLARE 
	curs CURSOR FOR (select distinct eid
		from Specializes
		natural join Sessions
		where area_name=(select area_name from Courses where c_id=course_id));
	r RECORD;
	dur integer;
BEGIN
	OPEN curs;
	select duration into dur from Courses where c_id=course_id;
	LOOP
		FETCH curs INTO r;
		EXIT WHEN NOT FOUND;
		IF (
			(s_date not in (select session_date from Sessions where eid=r.eid)) 
			or exists (
				select 1
				from Sessions
				where ((s_time<=start_time-dur-1) or (s_time>=end_time+1))
				and s_date=session_date
				and eid=r.eid
			)
			and ( (get_work_hour(r.eid) is null) or (get_work_hour(r.eid)+dur<=30) )
			and ((select depart_date from Employees where eid=r.eid) is null
				or s_date<(select depart_date from Employees where eid=r.eid))
			)
		THEN employee_id:=r.eid;
			 employee_name:=(select name from Employees where eid=r.eid);
			 RETURN NEXT; 
		END IF;
	END LOOP;
	CLOSE curs;
END;
$$ LANGUAGE plpgsql;

-- 7. get_available_instructors
CREATE OR REPLACE FUNCTION get_available_instructors(c_id integer,s_date date, e_date date)
RETURNS TABLE(employee_id int, employee_name text, num_hours numeric, days date, hours int[ ]) AS $$
	with Days AS
    ( 
      SELECT t.day::date specific_day
      FROM   generate_series(s_date, e_date, '1 day') AS t(day)
     ),
    Instructor_in_area AS(
    	select eid
    	from Specializes
    	where area_name= (select area_name from Courses where course_id=c_id)
    	and (get_work_hour(eid) is null or get_work_hour(eid)+ (select duration from Courses where c_id=course_id) <=30)
    	),
	t1 as(
		SELECT Instructor_in_area.eid AS eid, Days.specific_day AS session_date, generate_series(S.start_time-1, S.end_time) AS time,generate_series(9,17) AS full_time
    	FROM Days CROSS JOIN Instructor_in_area
   		LEFT JOIN Sessions S
    	ON Instructor_in_area.eid = S.eid AND Days.specific_day = S.session_date
		)
	select employee_id, employee_name, num_hours, days, ARRAY_AGG(hours)
	from(
		select empty.eid employee_id, name employee_name, all_em_work_hour(empty.eid, empty.session_date) num_hours, empty.session_date days, empty.full_time hours 
		FROM t1 empty 
		natural left join (select eid, name from employees) X
		LEFT JOIN t1 occupied
        ON empty.eid = occupied.eid AND empty.session_date = occupied.session_date
        AND empty.full_time = occupied.time
        WHERE occupied.time is NULL AND (empty.full_time<12 OR empty.full_time>=14)
        ORDER BY empty.eid, empty.session_date, empty.full_time
    ) AS t2
    group by employee_id, employee_name, num_hours, days;
	
$$ LANGUAGE sql;

-- 8. find_rooms
CREATE OR REPLACE FUNCTION find_rooms (session_day date,
session_start_hour int, session_duration int)
RETURNS TABLE(rid int) AS $$
    SELECT DISTINCT R.rid AS rid
    FROM Rooms R LEFT JOIN
    (SELECT session_date, start_time, end_time, rid from Sessions
    WHERE Sessions.session_date = session_day) S
    ON R.rid = S.rid
    WHERE S.end_time <= session_start_hour
	   OR S.start_time >= (session_start_hour + session_duration)
	   OR S.session_date IS NULL;
$$ LANGUAGE sql;


-- 9. get_available_rooms
CREATE OR REPLACE FUNCTION get_available_rooms(start_date date, end_date date)
RETURNS TABLE(rid int, seating_capacity int, days date, hours int[ ]) AS $$
    WITH Days AS
    (
      SELECT t.day::date specific_day
      FROM   generate_series(start_date, end_date, '1 day') AS t(day)
     ),
    t1 AS
    (
      SELECT R.rid AS rid, R.seating_capacity AS seating_capacity,
      Days.specific_day AS session_date, generate_series(S.start_time, S.end_time-1) AS time,
      generate_series(9,17) AS full_time
      FROM Rooms R CROSS JOIN Days
      LEFT JOIN
      Sessions S
      ON R.rid = S.rid AND Days.specific_day = S.session_date
    )
    SELECT rid, seating_capacity, days, ARRAY_AGG(hours)
    FROM
    (
        SELECT empty.rid rid, empty.seating_capacity seating_capacity, empty.session_date days, empty.full_time hours
        FROM t1 empty LEFT JOIN t1 occupied
        ON empty.rid = occupied.rid AND empty.session_date = occupied.session_date
        AND empty.full_time = occupied.time
        WHERE occupied.time is NULL AND (empty.full_time<12 OR empty.full_time>=14)
        ORDER BY empty.rid, empty.session_date, empty.full_time ASC
    ) AS t2
    GROUP BY rid, seating_capacity, days;
$$ LANGUAGE sql;

-- 10. add_course_offering
CREATE TYPE session_type AS (
      session_date date,
      start_time integer,
      room_id integer
      );

CREATE OR REPLACE PROCEDURE add_course_offering(
offering_id IN INTEGER, 
course_id1 IN INTEGER, 
fees IN decimal(5,2), 
target_number_registrations IN INTEGER,
launch_date IN date,
registration_deadline IN date, 
eid IN INTEGER,
session_info IN session_type[])
AS $$


DECLARE
instructor_id integer;
session_date date;
start_time integer;
end_time integer := start_time + (select duration from courses where courses.course_id = course_id1);
room_id integer;
seating_capacity integer := 0;
add_capacity integer;
s session_type;
start_date date := '2040-01-01';
end_date date := '2000-01-01';
index_no integer;


BEGIN 
        foreach s in array session_info loop
            add_capacity := (select rooms.seating_capacity from rooms where rooms.rid = s.room_id);
            seating_capacity := seating_capacity + add_capacity;
        end loop;

        IF seating_capacity < target_number_registrations THEN
            RAISE NOTICE 'Seating capacity is less than the target number of registration. Fail to add a new offering.';
            RETURN;
        END IF;

        foreach s in array session_info loop
           session_date := s.session_date;
           start_time := s.start_time;

           IF (SELECT COUNT(*) FROM find_instructors(course_id1,session_date,start_time)) = 0 THEN
               RAISE NOTICE 'Cannot find available instructors. Fail to add a new offering.';
               RETURN;
           END IF;

           IF session_date < start_date THEN
               start_date := session_date;
           END IF;
           
           IF session_date > end_date THEN
               end_date := session_date;
           END IF;
        end loop;

        INSERT INTO offerings(offering_id,launch_date,course_id,fees,start_date,end_date,registration_deadline,seating_capacity,target_number_registrations,eid)
                values(offering_id,launch_date,course_id1,fees,start_date,end_date,registration_deadline,seating_capacity,target_number_registrations,eid);

        foreach s in array session_info loop
           session_date := s.session_date;
           start_time := s.start_time;
           room_id := s.room_id;
           instructor_id := (select employee_id
                        from find_instructors(course_id1,session_date,start_time)
                        limit 1);
           index_no := (select array_position(session_info, s));
           perform add_session(offering_id,index_no,session_date,start_time,instructor_id,room_id);
         end loop;
END;
$$ LANGUAGE plpgsql;

-- 11. add_course_package
create or replace procedure add_course_package 
	(package_name text, num_of_free_sessions integer, start_date date, end_date date, price decimal(5, 2))
as $$
begin
insert into Course_packages (name, sale_start_date, sale_end_date, num_free_registration, price)
	values (package_name, start_date, end_date, num_of_free_sessions, price);
end;
$$ language plpgsql;

-- 12. get_available_course_packages
create or replace function get_available_course_packages()
returns table (id int, name text, num_free_registration int, sale_end_date date, price decimal(5, 2)) as $$
	select C.package_id, C.name, C.num_free_registration, C.sale_end_date, C.price
	from Course_packages C
	where sale_end_date >= (select current_date);
$$ language sql;

-- 13. buy_course_package
create or replace procedure buy_course_package 
	(cid integer, pid integer)
as $$
declare 
	buy_date date;
	card text;
	num_free_registration int;
begin
	buy_date := (select current_date);
	card := (select card_number from Owns where cust_id = cid order by from_date desc limit 1);
	num_free_registration := (select CP.num_free_registration from Course_packages CP where CP.package_id = pid);
	insert into Buys (buy_date, package_id, card_number, cust_id, num_remaining_redemptions) 
		values (buy_date, pid, card, cid, num_free_registration);
end;
$$ language plpgsql;

-- 14. get_my_course_package
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

-- 15. get_available_course_offerings
CREATE OR REPLACE FUNCTION get_remaining_seats_offering() RETURNS TABLE(offering_id integer, vacancy numeric) AS $$

   with number_of_redeems as(
   SELECT offering_id, count(*) as n
   FROM redeems
   GROUP BY offering_id
   ),
   
   number_of_registers as(
   SELECT offering_id, count(*) as n
   FROM registers
   GROUP BY offering_id
   ),

   total_number as (
   SELECT offering_id , sum(n) as taken_seats
   FROM ( select * from number_of_redeems UNION ALL select * from number_of_registers) as combined
   GROUP BY offering_id)

   SELECT offerings.offering_id, (seating_capacity - coalesce(taken_seats, 0)) as remaining_seats
   FROM offerings LEFT JOIN total_number on offerings.offering_id = total_number.offering_id
   order by offerings.offering_id;
   
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION get_available_course_offerings() RETURNS 
TABLE(course_title TEXT, 
   course_area TEXT,
   start_date DATE,
   end_date DATE,
   registration_deadline DATE,
   fees decimal(5,2),
   remaining_seats numeric
) AS $$

BEGIN 
   RETURN QUERY
   with available_offeringid as (
   select offering_id from get_remaining_seats_offering()
   where vacancy > 0
   ),
   available_pairs as (
   select * from get_remaining_seats_offering()
   ),
   temp as(
   select title as course_title, 
   area_name as course_area,
   offerings.start_date,
   offerings.end_date,
   offerings.registration_deadline,
   offerings.fees,
   offerings.offering_id
   from courses RIGHT JOIN offerings ON (courses.course_id = offerings.course_id)
   )
   
   SELECT temp.course_title, 
   temp.course_area,
   temp.start_date,
   temp.end_date,
   temp.registration_deadline,
   temp.fees,
   available_pairs.vacancy as remaining_seats 
   FROM temp LEFT JOIN available_pairs on temp.offering_id = available_pairs.offering_id
   WHERE available_pairs.vacancy > 0 and 
         temp.registration_deadline > current_date
   ORDER BY registration_deadline asc, course_title asc
   ;

END;
$$ LANGUAGE plpgsql;

-- 16. get_available_course_sessions
CREATE OR REPLACE FUNCTION get_available_course_sessions(offering_identifier int)
RETURNS TABLE(session_date date, session_start_hour int, instructor_name TEXT, remaining_seat bigint) AS $$
    SELECT  S.session_date, S.start_time, E.name, R3.seating_capacity-COUNT(R.cust_id)-COUNT(R2.cust_id) AS remaining_seat
    FROM Offerings O JOIN Sessions S ON O.offering_id = S.offering_id AND O.offering_id=offering_identifier
    JOIN Employees E ON S.eid = E.eid
    LEFT JOIN Registers R ON S.offering_id = R.offering_id AND S.sid =R.sid
    LEFT JOIN Redeems R2 ON S.offering_id = R2.offering_id AND S.sid =R2.sid
    LEFT JOIN Rooms R3 ON S.rid = R3.rid
    GROUP BY (S.offering_id, S.sid, S.session_date, S.start_time, E.name, R3.seating_capacity)
    ORDER BY S.session_date, S.start_time ASC;
$$ LANGUAGE sql;

-- 17. register_session
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
				(select card_number from Owns where cust_id = cid order by from_date desc limit 1),
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

-- 18. get_my_registrations
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

-- 19. update_course_session
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

-- 20. cancel_registration
CREATE OR REPLACE PROCEDURE cancel_registration(cus_id integer, o_id integer) AS $$
DECLARE refund_fee decimal(5,2);
	session_id integer;
	p_id integer;
BEGIN 
	IF (cus_id,o_id) in (select cust_id, offering_id from Registers)
	THEN 
		session_id:= (select sid from Registers where cust_id=cus_id and offering_id=o_id);
	ELSE 
		session_id:= (select sid from Redeems where cust_id=cus_id and offering_id=o_id);
	END IF;
	IF current_date+7> (select session_date from Sessions where offering_id=o_id and sid=session_id)
	THEN RAISE NOTICE 'Session starts within 7 days. Refund is not applicable.';
		RETURN;
	ELSEIF (cus_id,o_id) in (select cust_id, offering_id from Registers)
	THEN 
		refund_fee:=0.9*(select fees from Offerings where offering_id=o_id);
		INSERT INTO Cancels values(current_date, refund_fee, 0, cus_id, o_id, session_id);
		DELETE FROM Registers where cust_id=cus_id and offering_id=o_id;
	ELSE
		p_id:=(select package_id from Redeems where cust_id=cus_id and offering_id=o_id);
		INSERT INTO Cancels values(current_date, 0, 1, cus_id, o_id, session_id);
		UPDATE Buys SET num_remaining_redemptions=num_remaining_redemptions+1 where cust_id=cus_id and package_id=p_id;
		DELETE FROM Redeems where cust_id=cus_id and offering_id=o_id;
	END IF;
END;
$$ LANGUAGE plpgsql;

-- 21. update_instructor
CREATE OR REPLACE PROCEDURE update_instructor(o_id integer, s_id integer, employee_id integer) AS $$
BEGIN
	UPDATE Sessions set eid=employee_id
	where offering_id=o_id
	and sid=s_id;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION update_session_eid() RETURNS TRIGGER AS $$
DECLARE
	c_id integer;
	s_date date;
	s_time integer;
BEGIN
	c_id:=(select course_id from Offerings where offering_id=NEW.offering_id);
	s_date:=(select session_date from Sessions where offering_id=NEW.offering_id
		and sid=NEW.sid);
	s_time:=(select start_time from Sessions where offering_id=NEW.offering_id
		and sid=NEW.sid);
	IF current_date>=(select session_date from Sessions 
		where offering_id=NEW.offering_id
		and sid=NEW.sid)
	THEN RAISE NOTICE 'The session has already started. Update rejected.';
		RETURN NULL;
	ELSEIF NEW.eid not in (select employee_id from find_instructors(c_id,s_date,s_time))
	THEN RAISE NOTICE 'Update request invalid.';
		RETURN NULL;
	ELSE
		RETURN NEW;
	END IF;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER update_instructor_trigger
BEFORE UPDATE OF eid ON Sessions
FOR EACH ROW EXECUTE FUNCTION update_session_eid(); 

-- 22. update_room
CREATE OR REPLACE FUNCTION update_room(offering_identifier int, session_number int, new_rid int)
RETURNS void AS $$
DECLARE
     s_date DATE;
     s_start_hour INTEGER;
     duration INTEGER;
     no_of_registration INTEGER;
     new_room_capacity INTEGER;
BEGIN
     s_date := (SELECT session_date FROM Sessions WHERE Offering_id = offering_identifier AND sid = session_number);
     s_start_hour := (SELECT start_time FROM Sessions WHERE Offering_id = offering_identifier AND sid = session_number);
     duration := (SELECT DISTINCT C.duration FROM Courses C
                         JOIN Offerings O on C.course_id = O.course_id
                         JOIN Sessions S on S.Offering_id = O.Offering_id
                         WHERE S.Offering_id = offering_identifier AND S.sid = session_number);

     no_of_registration := (SELECT COUNT(R.cust_id) + COUNT(R2.cust_id)
     FROM Sessions S
     LEFT JOIN Registers R ON S.offering_id = R.offering_id AND S.sid =R.sid
     LEFT JOIN Redeems R2 ON S.offering_id = R2.offering_id AND S.sid =R2.sid
     WHERE S.offering_id = offering_identifier AND S.sid = session_number
     GROUP BY S.offering_id, S.sid) ;

     new_room_capacity := (SELECT DISTINCT seating_capacity FROM Rooms WHERE rid=new_rid);

     IF (s_date<CURRENT_DATE) THEN
     RAISE NOTICE 'Session already conducted';
     ELSIF (new_room_capacity < no_of_registration) THEN
     RAISE NOTICE 'Room too small for number of registration';
     ELSIF (new_rid NOT IN (select * from find_rooms (s_date,   s_start_hour, duration))) THEN
     RAISE NOTICE 'Already in the room or room not available';
     ELSE
     UPDATE Sessions
     SET rid = new_rid
     WHERE offering_id = offering_identifier AND sid = session_number;
     END IF;

END;
$$ LANGUAGE plpgsql;

-- 23. remove_session
CREATE OR REPLACE FUNCTION remove_session(offering_identifier int, session_number int)
RETURNS void AS $$
DECLARE
     s_date DATE;
BEGIN
     s_date := (SELECT session_date FROM Sessions WHERE Offering_id = offering_identifier AND sid = session_number);
     IF (s_date<CURRENT_DATE) THEN
     RAISE NOTICE 'Session already conducted';
     ELSIF((SELECT COUNT(offering_id) FROM Sessions WHERE Offering_id = offering_identifier)=1) THEN
     RAISE NOTICE 'Only one session left for the offering, cannot delete';
     ELSIF(1<=(SELECT COUNT(R.cust_id) + COUNT(R2.cust_id)
     FROM Sessions S
     LEFT JOIN Registers R ON S.offering_id = R.offering_id AND S.sid =R.sid
     LEFT JOIN Redeems R2 ON S.offering_id = R2.offering_id AND S.sid =R2.sid
     WHERE S.offering_id = offering_identifier AND S.sid = session_number
     GROUP BY S.offering_id, S.sid))  THEN
     RAISE NOTICE 'There are already customers registering for the session';
     ELSE
     DELETE FROM Sessions
     WHERE Offering_id = offering_identifier AND sid = session_number;
     END IF;
END;
$$ LANGUAGE plpgsql;

-- 24. add_session
CREATE OR REPLACE FUNCTION add_session(offering_identifier int, session_number int, new_day date, start_hour int, new_eid int, new_rid int)
RETURNS void AS $$
DECLARE
     duration_time INTEGER;
     c_id INTEGER;
     ddl DATE;
BEGIN
     c_id := (SELECT course_id FROM Offerings WHERE Offering_id = offering_identifier);
     duration_time := (SELECT duration FROM Courses WHERE course_id = c_id);
     ddl := (SELECT registration_deadline FROM Offerings WHERE Offering_id = offering_identifier);

     IF (CURRENT_DATE >= ddl) THEN
     RAISE NOTICE 'Offering register deadline has passed.';
     ELSIF (new_eid NOT IN (SELECT employee_id FROM find_instructors(c_id, new_day, start_hour) I)) THEN
     RAISE NOTICE 'Instructor not eligible or available.';
     ELSIF (ddl > new_day::date - 10*interval '1' day) THEN
     RAISE NOTICE 'Date early than/too close to register deadline';
     ELSIF (new_rid NOT IN  (select * from find_rooms (new_day, start_hour, duration_time))) THEN
     RAISE NOTICE 'Room not available';
     ELSIF (start_hour+duration_time > 12 OR start_hour+duration_time>18) THEN
     RAISE NOTICE 'Session not able to conduct at this time';
     ELSE
     INSERT INTO Sessions
     VALUES (offering_identifier, session_number, new_day, start_hour, start_hour+duration_time, new_rid, new_eid);

     END IF;
END;
$$ LANGUAGE plpgsql;

-- 25. pay_salary
CREATE OR REPLACE FUNCTION pay_salary() 
RETURNS TABLE (em_id integer, em_name text, status text, n_work_days integer, n_work_hours numeric, em_hourly_rate decimal(5,2), em_monthly_salary decimal(5,2), salary_amount decimal(5,2)) AS $$
DECLARE 
	curs CURSOR FOR (select eid from Employees);
	r RECORD;
	amt decimal(5,2);
	wh numeric;
	wd integer;
	h_rate decimal(5,2);
	m_salary decimal(5,2);
BEGIN
	OPEN curs;
	LOOP
		FETCH curs INTO r;
		EXIT WHEN NOT FOUND;
		wh:=get_work_hour(r.eid);
		wd:=get_work_day(r.eid);
		IF wh is not null
		THEN 
			h_rate:=(select hourly_rate from Part_time_emp where eid=r.eid);
			amt:= h_rate * wh;
		ELSE 
			m_salary=(select monthly_salary from Full_time_emp where eid=r.eid);
			amt:= m_salary * wd / (select extract(days FROM date_trunc('month', now()) + interval '1 month - 1 day'));
		END IF;
		INSERT into Pay_slips values(r.eid, current_date, coalesce(amt,0), wh, wd) ON CONFLICT (eid,payment_date) DO NOTHING;
	END LOOP;
	RETURN QUERY
	select eid, name, case 
		when hourly_rate is null then 'Full_time'
		else 'Part_time' end as status, num_work_days, num_work_hours, hourly_rate, monthly_salary, coalesce(amount,0)
	from Pay_slips
	natural left join (select eid, name from Employees) as X
	natural left join Full_time_emp
	natural left join Part_time_emp
	where (select extract(month from payment_date))=(select extract(month from current_date));
END;
$$ LANGUAGE plpgsql;

-- 26. promote_courses
CREATE OR REPLACE FUNCTION get_number_of_registration() RETURNS TABLE(offering_id integer, number_of_registration
 numeric) AS $$

   with number_of_redeems as(
   SELECT offering_id, count(*) as n
   FROM redeems
   GROUP BY offering_id
   ),
   
   number_of_registers as(
   SELECT offering_id, count(*) as n
   FROM registers
   GROUP BY offering_id
   ),

   total_number as (
   SELECT offering_id , sum(n) as number_of_registration
   FROM ( select * from number_of_redeems UNION ALL select * from number_of_registers) as combined
   GROUP BY offering_id)

   SELECT * from total_number order by offering_id;

$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION promote_courses(
customer_id OUT INTEGER, customer_name OUT TEXT, course_area OUT TEXT, course_id OUT INTEGER, course_name OUT TEXT, launch_date OUT DATE, registration_deadline out DATE, fees out DECIMAL(5,2)) RETURNS SETOF RECORD AS $$
BEGIN
    RETURN QUERY

    with inactive_customers as (
    select cust_id from customers where cust_id not in (
        select cust_id from registers where registers.registration_date > CURRENT_DATE - INTERVAL '6 months'
        union
        select cust_id from redeems where redeems.redemption_date > CURRENT_DATE - INTERVAL '6 months'
        )
    ),

    t1 as (
    select distinct cust_id,area_name,registration_date as thedate
    from registers, courses, offerings
    where registers.offering_id = offerings.offering_id and
          offerings.course_id = courses.course_id 
    union
    
    select distinct cust_id,area_name,redemption_date as thedate
    from redeems, courses, offerings
    where redeems.offering_id = offerings.offering_id and
          offerings.course_id = courses.course_id 
    ),
    
    interested_area as (
        select distinct cust_id, area_name
        from (
        select A.* from 
        (select t1.*,
          rank() OVER(PARTITION BY cust_id ORDER BY thedate DESC)
          FROM t1) A
        WHERE rank <=3
        ) B

        union 

        select distinct C.cust_id, S.area_name
        from customers C, courses S
        where C.cust_id not in 
           (select cust_id from t1)
        
        )

    select I.cust_id as customer_id, B.name as customer_name, A.area_name as course_area, C.course_id, C.title as course_title, 
    O.launch_date, O.registration_deadline, O.fees
    from interested_area A, inactive_customers I, courses C, offerings O, customers B, select * from get_remaining_seats_offering() as R
    where A.cust_id = I.cust_id and
    I.cust_id = B.cust_id and 
    A.area_name = C.area_name and
    C.course_id = O.course_id and 
    O.registration_deadline > current_date and
    (R.offering_id = O.offering_id and R.vacancy > 0)

    ORDER BY customer_id asc, O.registration_deadline asc;
     
END;
$$ LANGUAGE plpgsql;

-- 27. top_packages
create or replace function top_packages_sales
	(N int)
returns table (package_id int, count int) as $$
begin
	return query select * 
	from (
		select B.package_id, count(*)::int as count
		from Buys B
		where (select extract (year from (select sale_start_date from Course_packages CP where CP.package_id = B.package_id))) = (select extract (year from current_date))
		group by B.package_id
		order by count desc
	) as T
	where T.count >= coalesce((
		select R.count 
		from (
			select B.package_id, count(*)::int as count
			from Buys B
			where (select extract (year from (select sale_start_date from Course_packages CP where CP.package_id = B.package_id))) = (select extract (year from current_date))
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

-- 28. popular_courses
CREATE OR REPLACE FUNCTION popular_courses(OUT course_id integer, out course_name text, out course_area text, out number_of_offerings bigint, out registration_for_latest_offering
 numeric) 
RETURNS SETOF RECORD AS $$
BEGIN 

   RETURN QUERY
   with t1 as (
   select *
   from get_number_of_registration() as A join offerings B on A.offering_id = B.offering_id
   ),

   t2 as (select offerings.course_id,count(*) as n
   FROM Offerings
   WHERE date_part('year', start_date) = date_part('year', CURRENT_DATE)   
   GROUP BY offerings.course_id
   HAVING count(*) > 1
   ),

   popular_courses as (
   SELECT * from t2 where t2.course_id not in 

   (SELECT a.course_id
   from t1 A, t1 B
   WHERE A.course_id = B.course_id and 
   A.start_date > B.start_date and
   A.number_of_registration < B.number_of_registration
   )
   ),

   max_registration as (
   select t1.course_id, max(number_of_registration) as registration_for_latest_offering
   from t1
   group by t1.course_id
   )

   select p.course_id, c.title as course_name,c.area_name as course_area, p.n as number_of_offerings,m.registration_for_latest_offering
   from popular_courses p, courses c, max_registration m
   where p.course_id = c.course_id and 
   c.course_id = m.course_id
   order by p.course_id asc;

END;
$$ LANGUAGE plpgsql;

-- 29. view_summary_report
CREATE OR REPLACE FUNCTION view_summary_report(IN N integer,OUT year double precision, out month double precision,out total_package_sold numeric,out total_registration_fee numeric, out total_salary_paid numeric, out total_refunded_registration_fee numeric, out total_redemption bigint) RETURNS SETOF RECORD AS $$
DECLARE
last_date date := date_trunc('month', current_date) + interval '1 month'- INTERVAL '1 DAY';
first_date date := last_Date + INTERVAL '1 DAY'- N * INTERVAL '1 months';

BEGIN
   return query
   with package as (
   select date_part('year', buy_date) as year, date_part('month', buy_date) as month, A.price as package_price
   from (buys join course_packages on buys.package_id = course_packages.package_id) as A
   WHERE buy_date between first_date and last_date
   ),
   package_sum as (
   select A.year,A.month,sum(package_price) as total_package_sold
   from package A
   group by A.year,A.month
   ),
   card as (
   select date_part('year', registration_date) as year, date_part('month', registration_date) as month, fees as offering_price
   from (registers R join offerings O on R.offering_id = O.offering_id) as A
   WHERE registration_date between first_date and last_date
   ),
   card_sum as (
   select A.year,A.month,sum(offering_price) as total_registration_fee
   from card A
   group by A.year,A.month
   ),
   salary as (
   select date_part('year', A.payment_date) as year, date_part('month', A.payment_date) as month, A.amount as salary_amount
   from pay_slips A
   WHERE A.payment_date between first_date and last_date
   ),
   salary_sum as (
   select A.year,A.month, sum(salary_amount) as total_salary_paid
   from salary A
   group by A.year,A.month
   ),
   cancellation as (
   select date_part('year', A.cancellation_date) as year, date_part('month', A.cancellation_date) as month, A.refund_amount
   from cancels A
   WHERE A.cancellation_date between first_date and last_date
   ),
   cancellation_sum as (
   select A.year,A.month,sum(refund_amount) as total_refunded_registration_fee
   from cancellation A
   group by A.year,A.month
   ),
   redemption as (
   select date_part('year', A.redemption_date) as year, date_part('month', A.redemption_date) as month
    from redeems A
   where A.redemption_date between first_date and last_date
   ),
   redemption_sum as (
   select A.year,A.month,count(*) as total_redemption
   from redemption A
   group by A.year,A.month
   )
   
   select A.year,A.month,A.total_package_sold, B.total_registration_fee, C.total_salary_paid,D.total_refunded_registration_fee
          ,E.total_redemption
   from package_sum A full outer join card_sum B on (A.year = B.year and A.month = B.month)
        full join salary_sum C on COALESCE(A.year,B.year) = C.year and COALESCE(A.month,B.month) = C.month 
        full join cancellation_sum D on COALESCE(A.year,B.year) = D.year and COALESCE(A.month,B.month) = D.month 
        full join redemption_sum E on COALESCE(A.year,B.year) = E.year and COALESCE(A.month,B.month) = E.month;
 
END;
$$ LANGUAGE plpgsql;

-- 30. view_manager_report
CREATE OR REPLACE FUNCTION view_manager_report()
RETURNS table(manager_name text, num_of_area_managed int, num_of_offerings_end_this_year int, net_registration_fees_this_year int,
top_offering_course text[]) AS $$

BEGIN
    drop table if exists RegisterFees, RedeemsFees, Countings, TopOfferings;
    CREATE TEMP TABLE RegisterFees (
       offering_id int,
       fees int
    );

    INSERT INTO RegisterFees (offering_id, fees)
        select R1.offering_id, O.fees
        from Registers R1 join Offerings O on R1.offering_id = O.offering_id;

    CREATE TEMP TABLE RedeemsFees (
       offering_id int,
       fees int
    );

    INSERT INTO RedeemsFees(offering_id, fees)
        select R2.offering_id, floor(CP.price/CP.num_free_registration)
        from Redeems R2 join Course_packages CP ON R2.package_id = CP.package_id;

    CREATE TEMP TABLE Countings(
       m_name text,
       area_managed int,
       offerings_end_this_year int,
       net_fees_this_year int
    );

    INSERT INTO Countings(m_name, area_managed, offerings_end_this_year, net_fees_this_year)
        select E.name, COUNT(DISTINCT C.area_name), COUNT(O.course_id), coalesce(SUM(RF1.fees),0)+coalesce(SUM(RF2.fees),0)-coalesce(SUM(CN.refund_amount),0)
        from Managers M join Employees E on M.eid = E.eid
        left join Course_areas CA on M.eid = CA.eid
        left join Courses C on CA.area_name = C.area_name
        left join
        (select * from Offerings where date_part('year', end_date) = date_part('year', CURRENT_DATE)) O
        on O.course_id = C.course_id
        left join RegisterFees RF1 on RF1.offering_id = O.offering_id
        left join RedeemsFees RF2 on RF2.offering_id = O.offering_id
        left join Cancels CN on CN.offering_id = O.offering_id
        where E.depart_date IS NULL
        group by E.name;

    CREATE TEMP TABLE TopOfferings(
        m_name text,
        top_of_course text[]
    );

    INSERT INTO TopOfferings(m_name, top_of_course)
        with temp as
        (
            select E.name m_name, O.offering_id offering_id, coalesce(SUM(RF1.fees),0)+coalesce(SUM(RF2.fees),0)-coalesce(SUM(CN.refund_amount),0) net_fees
            from Managers M join Employees E on M.eid = E.eid
            left join Course_areas CA on M.eid = CA.eid
            left join Courses C on CA.area_name = C.area_name
            left join
            (select * from Offerings where date_part('year', end_date) = date_part('year', CURRENT_DATE)) O
            on O.course_id = C.course_id
            left join RegisterFees RF1 on RF1.offering_id = O.offering_id
            left join RedeemsFees RF2 on RF2.offering_id = O.offering_id
            left join Cancels CN on CN.offering_id = O.offering_id
            where E.depart_date IS NULL
            group by E.name, O.offering_id
        )
        select t.m_name, array_agg(DISTINCT C.title)
        from temp t inner join
        (select m_name, offering_id, max(net_fees) maxfees
         from temp
         group by m_name, offering_id) g
        on t.m_name = g.m_name and t.offering_id = g.offering_id and t.net_fees = g.maxfees
        join Offerings O on t.offering_id = O.offering_id
        join Courses C on O.course_id = C.course_id
        group by t.m_name;

    RETURN QUERY
    (
    select C.m_name, area_managed, offerings_end_this_year, net_fees_this_year, top_of_course
    from Countings C
    left join TopOfferings TOs on C.m_name = TOs.m_name
    order by C.m_name asc
    );

END;
$$ LANGUAGE plpgsql;

-- Trigger
CREATE OR REPLACE FUNCTION update_offerings_date() RETURNS TRIGGER
AS $$
BEGIN
     IF (TG_OP = 'INSERT' or TG_OP = 'UPDATE') THEN
         UPDATE Offerings
         SET start_date = (
         SELECT MIN(session_date)
         FROM Sessions
         WHERE offering_id = NEW.offering_id
         GROUP BY offering_id)
         WHERE offering_id = NEW.offering_id;

         UPDATE Offerings
         SET end_date = (
         SELECT MAX(session_date)
         FROM Sessions
         WHERE offering_id = NEW.offering_id
         GROUP BY offering_id)
         WHERE offering_id = NEW.offering_id;
         RETURN NEW;

     ELSIF(TG_OP='DELETE') THEN
         UPDATE Offerings
         SET start_date = (
         SELECT MIN(session_date)
         FROM Sessions
         WHERE offering_id = OLD.offering_id
         GROUP BY offering_id)
         WHERE offering_id = OLD.offering_id;

         UPDATE Offerings
         SET end_date = (
         SELECT MAX(session_date)
         FROM Sessions
         WHERE offering_id = OLD.offering_id
         GROUP BY offering_id)
         WHERE offering_id = OLD.offering_id;
         RETURN OLD;
     END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_offerings_date_trigger
AFTER INSERT OR DELETE OR UPDATE ON Sessions
FOR EACH ROW EXECUTE FUNCTION update_offerings_date();


CREATE OR REPLACE FUNCTION update_offerings_seating_capacity() RETURNS TRIGGER
AS $$
BEGIN
     IF (TG_OP = 'INSERT' or TG_OP = 'UPDATE') THEN
          UPDATE Offerings
          SET seating_capacity = (
          SELECT SUM(R.seating_capacity)
          FROM Sessions S Join Rooms R on S.rid = R.rid
          WHERE S.offering_id = NEW.offering_id
          GROUP BY S.offering_id)
          WHERE offering_id = NEW.offering_id;
          RETURN NEW;
      ELSIF(TG_OP='DELETE') THEN
          UPDATE Offerings
          SET seating_capacity = (
          SELECT SUM(R.seating_capacity)
          FROM Sessions S Join Rooms R on S.rid = R.rid
          WHERE S.offering_id = OLD.offering_id
          GROUP BY S.offering_id)
          WHERE offering_id = OLD.offering_id;
          RETURN OLD;
      END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_offerings_seating_capacity_trigger
AFTER INSERT OR DELETE OR UPDATE ON Sessions
FOR EACH ROW EXECUTE FUNCTION update_offerings_seating_capacity();

CREATE OR REPLACE FUNCTION insert_session_check_eid_func() RETURNS TRIGGER AS $$
BEGIN
   IF NEW.eid in (
       select eid from find_instructors(NEW.session_date, NEW.start_time, NEW.end_time)
       ) THEN
       RETURN NEW;
   ELSE 
       RAISE NOTICE 'Invalid eid input. Eid must belong to an available instructor';
       RETURN NULL;
   END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER insert_session_check_eid_trigger
BEFORE INSERT ON Sessions
FOR EACH ROW EXECUTE FUNCTION insert_session_check_eid_func();

CREATE OR REPLACE FUNCTION insert_session_check_room_func() RETURNS TRIGGER AS $$
BEGIN
   IF NEW.rid in (
       select rid from find_rooms(NEW.session_date, NEW.start_time, NEW.end_time-NEW.start_time)
       ) THEN
       RETURN NEW;
   ELSE 
       RAISE NOTICE 'Input room is not available.';
       RETURN NULL;
   END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER insert_session_check_room_trigger
BEFORE INSERT ON Sessions
FOR EACH ROW EXECUTE FUNCTION insert_session_check_room_func();

CREATE OR REPLACE FUNCTION insert_offering_check_date_func() RETURNS TRIGGER AS $$
BEGIN
    IF NEW.launch_date > NEW.registration_deadline OR 
    NEW.start_date > NEW.end_date OR
    NEW.registration_deadline > NEW.start_date 

    THEN
        RAISE NOTICE 'Invalid order of dates for the offerings.';
        RETURN NULL;

    ELSE 
        RETURN NEW;

    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER insert_offering_check_date_trigger
BEFORE INSERT ON Offerings
FOR EACH ROW EXECUTE FUNCTION insert_offering_check_date_func();

CREATE OR REPLACE FUNCTION insert_offering_check_admin_func() RETURNS TRIGGER AS $$
BEGIN
    IF NEW.eid not in (select eid from administrators) THEN
        RAISE NOTICE 'Invalid eid input. Eid must belong to an administrator';
        RETURN NULL;
    ELSE 
        RETURN NEW;

    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER insert_offering_check_admin_trigger
BEFORE INSERT ON Offerings
FOR EACH ROW EXECUTE FUNCTION insert_offering_check_admin_func();

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
		raise notice 'The registration has ended.';
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
		raise notice 'The customer has already owned an active or partially active package.';
		return null;
	end if;
end;
$$ language plpgsql;

create trigger limit_active_package_per_person_in_course_package
before insert on Buys
for each row execute function limit_active_package_per_person();

CREATE OR REPLACE FUNCTION update_depart_date() RETURNS TRIGGER AS $$
BEGIN
	IF (
		(NEW.depart_date>= coalesce((select max(registration_deadline) from Offerings where eid=NEW.eid), '0001-01-01'::date))
	and (NEW.depart_date>= coalesce((select max(session_date) from Sessions where eid=NEW.eid), '0001-01-01'::date))
	and (NEW.eid not in (select eid from Managers) or NEW.eid not in (select eid from Course_areas))
	)
	THEN 
		
		RETURN NEW;		
	ELSE
		RAISE NOTICE 'Removal rejected.';
		RETURN NULL;
	END IF;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER remove_employee_trigger
BEFORE UPDATE OF depart_date ON Employees
FOR EACH ROW EXECUTE FUNCTION update_depart_date(); 



CREATE OR REPLACE FUNCTION reject_delete_employee() RETURNS TRIGGER AS $$
BEGIN
	RAISE NOTICE 'Removal of employee records not allowed.';
	RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER delete_employee_trigger
BEFORE DELETE ON Employees
FOR EACH ROW EXECUTE FUNCTION reject_delete_employee(); 