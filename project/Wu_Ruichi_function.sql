--1 add_employee
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





------------------------------------------------------------------------
--2 remove_employee
CREATE OR REPLACE PROCEDURE remove_employee(employee_id integer,d_date date) AS $$
BEGIN
	UPDATE employees set depart_date=d_date where eid=employee_id;
END;
$$ LANGUAGE plpgsql;


--directly update employee's depart_date
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



------------------------------------------------------------------------
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





------------------------------------------------------------------------
--6 find_instructors
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

--test case
select find_instructors(14,'2020-03-13',9);


------------------------------------------------------------------------
--7 get_available_instructors
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

-- test case
select get_available_instructors(14,'2020-03-12','2020-03-14');



------------------------------------------------------------------------
--20 cancel_registration
--course offering id
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


--!!!!!!!!!!!!!!!!!! delete from register/redeem


------------------------------------------------------------------------
--21 update_instructor
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



------------------------------------------------------------------------
--25 pay_salary
-- the routine inserts the new salary payment records
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





