drop table if exists Credit_cards, Customers, Course_packages, Buys, Owns, Registers, Redeems, Cancels cascade;
drop table if exists Course_areas, Courses, Rooms, Sessions, Offerings cascade;
drop table if exists Employees, Pay_slips, Part_time_emp, Full_time_emp, Part_time_instructors cascade;
drop table if exists Instructors, Full_time_instructors, Administrators, Managers, Specializes cascade;


create table Rooms(
  rid integer PRIMARY KEY,
  floor integer not null,
  room_number integer not null,
  seating_capacity integer,
  unique (floor, room_number)
);

create table Employees(
  eid serial primary key,
  phone integer unique not null,
  name  text not null,
  address text,
  email text unique not null,
  join_date date not null,
  depart_date date
);

create table Part_time_emp(
  eid integer primary key references Employees
      on delete cascade
      on update cascade,
  hourly_rate decimal(5,2) not null
);


create table Pay_slips(
  eid integer,
  payment_date date,
  amount decimal(5,2) not null
      check (amount>=0),
  num_work_hours numeric
      check (num_work_hours >= 0 or num_work_hours is null),
  num_work_days integer
      check (((num_work_days >= 0) and (num_work_days <= 31)) or num_work_days is null),
  primary key (eid, payment_date),
  foreign key (eid) references Employees
      on delete cascade
      on update cascade
);

create table Full_time_emp(
  eid integer primary key references Employees
      on delete cascade
      on update cascade,
  monthly_salary decimal(5,2) not null
);


create table Administrators(
  eid integer primary key references Full_time_Emp
      on delete cascade
      on update cascade
);

create table Managers(
  eid integer primary key references Full_time_Emp
      on delete cascade
      on update cascade
);

create table Course_areas(
  area_name text primary key,
  eid integer not null,
  foreign key (eid) references Managers(eid)
      on delete cascade
      on update cascade
);

create table Instructors(
  eid integer not null references Employees
      on delete cascade
      on update cascade,
   primary key (eid)
);

create table Specializes(
  eid integer not null references Instructors
  	  on delete cascade
  	  on update cascade,
  area_name text not null references Course_areas,
  primary key (eid, area_name)
);

create table Part_time_instructors(
eid integer primary key references Instructors
    references Part_time_Emp
      on delete cascade
      on update cascade
);

create table Full_time_instructors(
  eid integer primary key references Instructors
      references Full_time_Emp
      on delete cascade
      on update cascade
);

create table Credit_cards(
  card_number text primary key,
  expiry_date date not null,
  CVV int not null
);

create table Customers(
  cust_id serial primary key,
  address text,
  phone text unique not null,
  name text not null,
  email text unique not null
);

create table Course_packages(
  package_id serial primary key,
  name text not null,
  sale_start_date date not null,
  sale_end_date date not null,
  num_free_registration int not null,
  price decimal(5, 2) not null,
  check(sale_end_date >= sale_start_date)
);

create table Owns(
  from_date date not null,
  cust_id serial,
  card_number text unique,
  foreign key (card_number) references Credit_cards on delete cascade on update cascade,
  foreign key (cust_id) references Customers on delete cascade on update cascade,
  primary key (cust_id, card_number)
);

create table Courses(
  course_id serial primary key,
  title text unique not null,
  duration integer
    check (duration >= 0),
  description text,
  area_name text not null,
  foreign key (area_name) references Course_areas(area_name) on delete cascade on update cascade
);

create table Offerings(
  offering_id int primary key,
  launch_date date,
  course_id serial,
  fees decimal(5,2) not null,
  start_date date not null,
  end_date date not null,
  registration_deadline date not null,
  seating_capacity integer not null,
  target_number_registrations integer not null,
  eid integer not null,
  unique(course_id, launch_date),      
  foreign key (course_id) references Courses
    on delete cascade
    on update cascade,
  foreign key (eid) references Administrators(eid)
    on delete cascade
    on update cascade,
  check (registration_deadline <= start_date - 10*interval '1' day)  
);

create table Sessions(
  offering_id integer not null,
  sid integer,
  session_date date not null,
  start_time integer not null
      check(start_time >= 9),
  end_time integer not null
      check(end_time <= 18 and end_time > start_time),
  rid integer not null,
  eid integer,
  primary key (offering_id, sid),
  unique(session_date, start_time, eid),
  unique(offering_id, session_date, start_time),
  unique(rid, session_date, start_time),  
  foreign key (offering_id) references Offerings
  	on delete cascade on update cascade,
  foreign key (rid) references Rooms(rid)
	on delete cascade on update cascade,
  foreign key (eid) references Instructors(eid)
	on delete cascade on update cascade,
  check ((start_time < 12 and end_time <= 12) or start_time >= 14),
  check (extract(dow from session_date) in (1,2,3,4,5)) 
);


create table Buys(
  buy_date date,
  package_id int,
  card_number text,
  cust_id serial,
  num_remaining_redemptions int not null,
  foreign key (cust_id, card_number) references Owns,
  foreign key (package_id) references Course_packages
      on delete cascade 
      on update cascade,
  primary key (buy_date, cust_id, card_number, package_id),
  check (num_remaining_redemptions >=0)
);


create table Registers(
  registration_date date,
  card_number text,
  cust_id serial,
  offering_id integer,
  sid int,
  foreign key (cust_id, card_number) references Owns,
  foreign key (offering_id, sid) references Sessions
      on delete cascade 
      on update cascade,
  primary key (registration_date, cust_id, card_number, offering_id, sid)
);

create table Redeems(
  redemption_date date,
  buy_date date,
  package_id int,
  card_number text,
  cust_id serial,
  offering_id int,
  sid int,
  foreign key (buy_date, cust_id, card_number, package_id) references Buys,
  foreign key (offering_id, sid) references Sessions
      on delete cascade 
      on update cascade,
  primary key (redemption_date, buy_date, cust_id, card_number, package_id, offering_id, sid)
);

create table Cancels(
  cancellation_date date,
  refund_amount decimal(5, 2),
  package_credit int,
  cust_id serial,
  offering_id int,
  sid int,
  foreign key (cust_id) references Customers,
  foreign key (offering_id, sid) references Sessions
       on delete cascade 
      on update cascade,
  primary key (cancellation_date, cust_id, sid)
);