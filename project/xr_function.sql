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


-- 5. add_course
CREATE OR REPLACE FUNCTION add_course(title text,  duration int, description text, area_name text)
RETURNS void AS $$
BEGIN
    INSERT INTO Courses(course_id, title, duration, description, area_name)
    VALUES (default, title,  duration, description, area_name);
END;
$$ LANGUAGE plpgsql;


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


