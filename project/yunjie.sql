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

