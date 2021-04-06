create or replace procedure add_course_package 
	(package_name text, num_of_free_sessions integer, start_date date, end_date date, price decimal(5, 2))

call add_course_package('Package 11', 5, '2021-03-10','2021-05-30', 100.36);
call add_course_package('Package 12', 10, '2021-02-14', '2021-05-30', 120.39);

create or replace function get_available_course_packages()

select * from get_available_course_packages();

create or replace procedure buy_course_package 
	(cid integer, pid integer)

call buy_course_package(1, 1);
call buy_course_package(2, 1);
call buy_course_package(3, 2);
call buy_course_package(4, 3);

create or replace function get_my_course_package 
	(in cid int, out res json)

select get_my_course_package(1);
select get_my_course_package(2);
select get_my_course_package(3);
select get_my_course_package(4);

create or replace procedure register_session
	(cid int, coid int, sid int, paymentMethod int)

call register_session(1, 9, 1, 1);
call register_session(1, 9, 1, 2);

call register_session(1, 10, 1, 1);
call register_session(1, 10, 2, 1);
call register_session(1, 10, 2, 2);

call register_session(2, 10, 1, 2);
call register_session(3, 10, 1, 2);


select get_my_course_package(1);
select get_my_course_package(2);
select get_my_course_package(3);

create or replace function get_my_registrations
	(in cid int)

select * from get_my_registrations(1);
select * from get_my_registrations(2);
select * from get_my_registrations(3);

create or replace procedure update_course_session
	(cid int, coid int, new_sid int)

call update_course_session(1, 9, 2);

call update_course_session(1, 10, 2);
call update_course_session(2, 10, 1);

create or replace function top_packages
	(N int)

select * from top_packages(1);
select * from top_packages(2);
select * from top_packages(3);
select * from top_packages(4);
