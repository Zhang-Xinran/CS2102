-- insert into Credit_cards
insert into Credit_cards (card_number, CVV, expiry_date) values ('4470361716237', '678', '2022-03-18');
insert into Credit_cards (card_number, CVV, expiry_date) values ('4532601368531', '539', '2022-05-20');
insert into Credit_cards (card_number, CVV, expiry_date) values ('4929695056073', '291', '2022-06-15');
insert into Credit_cards (card_number, CVV, expiry_date) values ('4532141317790', '442', '2022-10-10');
insert into Credit_cards (card_number, CVV, expiry_date) values ('4929521169516262', '919', '2022-10-15');
insert into Credit_cards (card_number, CVV, expiry_date) values ('4539530426470074', '822', '2022-11-01');
insert into Credit_cards (card_number, CVV, expiry_date) values ('4716136511273', '671', '2022-06-18');
insert into Credit_cards (card_number, CVV, expiry_date) values ('4532758798381127', '930', '2022-03-20');
insert into Credit_cards (card_number, CVV, expiry_date) values ('4556076811840','336', '2022-10-29');
insert into Credit_cards (card_number, CVV, expiry_date) values ('4716030910084', '421', '2022-01-09');

-- insert into Customers
insert into Customers (cust_id, address, phone, name, email) values (default, '2307 Tellus. Road', '(494) 745-3105', 'Levi Ball', 'litora.torquent.per@tincidunttempus.org');
insert into Customers (cust_id, address, phone, name, email) values (default, 'P.O. Box 335, 4573 Sem Av.','(593) 253-5993', 'Kadeem Carr', 'penatibus.et@pedemalesuada.org');
insert into Customers (cust_id, address, phone, name, email) values (default, '104-4454 Sit Rd.', '(866) 976-7577', 'Keane Holloway', 'tincidunt@sapien.net');
insert into Customers (cust_id, address, phone, name, email) values (default, '1306 Magna. Ave', '(290) 558-8204', 'Chaim Travis', 'ante.Nunc.mauris@scelerisque.ca');
insert into Customers (cust_id, address, phone, name, email) values (default, 'P.O. Box 697, 9829 Nam St.', '(913) 690-5047', 'Keane Beck', 'dapibus@egetvenenatisa.net');
insert into Customers (cust_id, address, phone, name, email) values (default, '1207 Consectetuer Street', '(809) 688-9388', 'Nolan Bishop', 'dui.Fusce@ligulaconsectetuerrhoncus.ca');
insert into Customers (cust_id, address, phone, name, email) values (default, '104-4309 Eget Ave', '(231) 794-8365', 'Hasad Blake', 'orci.consectetuer@ultricies.co.uk');
insert into Customers (cust_id, address, phone, name, email) values (default, 'Ap #829-717 Lectus Ave', '(919) 404-8257', 'Harding Langley', 'mus.Proin.vel@semegestas.co.uk');
insert into Customers (cust_id, address, phone, name, email) values (default, '1543 Vitae Road', '(888) 839-7843', 'Blake Powell', 'nec@consequat.org');
insert into Customers (cust_id, address, phone, name, email) values (default, '728-3216 Curabitur Rd.', '(458) 843-0891', 'Harrison Hardy', 'pellentesque@Morbinon.com');

-- insert into Owns
insert into Owns (cust_id, card_number, from_date)
values (1, '4470361716237', '2021-01-01');
insert into Owns (cust_id, card_number, from_date)
values (2, '4532601368531', '2021-01-01');
insert into Owns (cust_id, card_number, from_date)
values (3, '4929695056073', '2021-01-01');
insert into Owns (cust_id, card_number, from_date)
values (4, '4532141317790', '2021-01-01');
insert into Owns (cust_id, card_number, from_date)
values (5, '4929521169516262', '2021-01-01');
insert into Owns (cust_id, card_number, from_date)
values (6, '4539530426470074', '2021-01-01');
insert into Owns (cust_id, card_number, from_date)
values (7, '4716136511273', '2021-01-01');
insert into Owns (cust_id, card_number, from_date)
values (8, '4532758798381127', '2021-01-01');
insert into Owns (cust_id, card_number, from_date)
values (9, '4556076811840', '2021-01-01');
insert into Owns (cust_id, card_number, from_date)
values (10, '4716030910084', '2021-01-01');

-- insert into Course_packages
insert into Course_packages (name, sale_start_date, sale_end_date, num_free_registration, price)
values ('Package 1', '2021-03-01', '2021-05-30', 10, 100.00);
insert into Course_packages (name, sale_start_date, sale_end_date, num_free_registration, price)
values ('Package 2', '2021-03-01', '2021-08-30', 15, 150.00);
insert into Course_packages (name, sale_start_date, sale_end_date, num_free_registration, price)
values ('Package 3', '2021-03-01', '2021-09-30', 14, 140.00);
insert into Course_packages (name, sale_start_date, sale_end_date, num_free_registration, price)
values ('Package 4', '2021-03-01', '2021-10-31', 5, 50.00);
insert into Course_packages (name, sale_start_date, sale_end_date, num_free_registration, price)
values ('Package 5', '2021-03-01', '2021-10-31', 10, 100.00);
insert into Course_packages (name, sale_start_date, sale_end_date, num_free_registration, price)
values ('Package 6', '2021-03-01', '2021-11-30', 8, 80.00);
insert into Course_packages (name, sale_start_date, sale_end_date, num_free_registration, price)
values ('Package 7', '2021-03-01', '2021-11-30', 10, 100.00);
insert into Course_packages (name, sale_start_date, sale_end_date, num_free_registration, price)
values ('Package 8', '2021-03-01', '2021-12-31', 12, 120.00);
insert into Course_packages (name, sale_start_date, sale_end_date, num_free_registration, price)
values ('Package 9', '2021-03-01', '2021-12-31', 3, 40.00);
insert into Course_packages (name, sale_start_date, sale_end_date, num_free_registration, price)
values ('Package 10', '2021-03-01', '2021-05-30', 5, 50.00);

-- insert into Employees
insert into Employees (eid, phone, name, address, email, join_date) values
(1, '70135510', 'Lee', '209-2932 Aliquam Road', 'adipiscing.elit.Etiam@erosNam.edu', '2019-03-20'), 
(2, '29284051', 'Aladdin', '239-4617 A, Ave', 'gravida.molestie.arcu@lectus.org', '2019-03-25'), 
(3, '80099935', 'Walter', 'P.O. Box 256, 3619 Dapibus St.', 'Donec@eulacus.org', '2019-12-29'), 
(4, '44508629', 'Evan', 'Ap #874-2283 Amet Rd.', 'eget@aliquet.org', '2018-06-20'), 
(5, '18228916', 'Wanda', '923-1683 Egestas Ave', 'in@Morbivehicula.edu', '2018-08-05'), 
(6, '87993859', 'Raymond', '4938 Mauris Avenue', 'non.lacinia@tinciduntnuncac.co.uk', '2019-02-24'), 
(7, '99407414', 'Marshall', 'Ap #972-1936 Nam Street', 'Mauris@Etiam.co.uk', '2019-04-02'), 
(8, '12693607', 'Timothy', '2808 Accumsan Rd.', 'rutrum@musProin.net', '2017-06-20'), 
(9, '80786010', 'Oleg', '810-8561 Lorem Rd.', 'In.at.pede@aliquameuaccumsan.net', '2019-06-13'), 
(10, '58592920', 'Deirdre', '3753 Cum Road', 'amet.risus@Maecenasmalesuadafringilla.co.uk', '2019-06-30'), 
(11, '55748972', 'Jarrod', '7717 Ac Rd.', 'Nulla.aliquet@maurisrhoncusid.ca', '2018-02-05'), 
(12, '71417334', 'Micah', '1361 Justo. Ave', 'eu.ultrices@eratnonummyultricies.ca', '2019-11-27'), 
(13, '30235510', 'Camden', 'P.O. Box 423, 5942 Lorem Rd.', 'sed.libero@elementumpurusaccumsan.edu', '2019-02-23'), 
(14, '16852887', 'Lucius', '2933 Ante St.', 'Aliquam.erat@pedeetrisus.co.uk', '2018-03-09'), 
(15, '11861497', 'Leonard', 'P.O. Box 804, 4447 Mauris St.', 'vitae@suscipit.edu', '2017-04-26'), 
(16, '16399407', 'Sylvia', '487-1468 Cras Av.', 'et.magnis@etmagnis.co.uk', '2021-03-08'), 
(17, '76315326', 'Danielle', '639-6521 Mauris Ave', 'montes@duiFuscediam.net', '2019-05-25'), 
(18, '64836653', 'Fletcher', 'P.O. Box 106, 1290 Ornare, Avenue', 'nascetur@atsemmolestie.ca', '2019-03-02'), 
(19, '76601696', 'Keaton', '299-3992 Integer Road', 'Sed@dolor.net', '2018-09-14'), 
(20, '49275345', 'Lavinia', '110-8627 Lorem Street', 'egestas.Fusce.aliquet@lorem.net', '2019-09-26'), 
(21, '57647664', 'Lars', '721-5065 Urna. Avenue', 'penatibus.et.magnis@Praesenteu.com', '2019-07-24'), 
(22, '55962752', 'Evan', '137-9761 Ac Street', 'enim.Etiam.imperdiet@vitae.ca', '2019-02-26'), 
(23, '85237027', 'Carly', 'Ap #609-9120 Mollis Ave', 'non.justo@aliquetmolestie.ca', '2019-01-19'), 
(24, '74666924', 'Brynn', 'Ap #126-7452 Enim Street', 'dis@semperduilectus.ca', '2019-09-06'), 
(25, '27196191', 'Boris', 'Ap #159-8671 Id Ave', 'a@tinciduntnibhPhasellus.org', '2019-11-23'), 
(26, '43503173', 'TaShya', 'P.O. Box 257, 6325 Gravida Ave', 'libero.Proin.sed@Vivamusnisi.edu', '2019-03-01'), 
(27, '12966266', 'Barrett', 'P.O. Box 824, 9825 Proin Road', 'Duis.sit@musAeneaneget.co.uk', '2019-03-11'), 
(28, '35353014', 'Russell', '526-5212 Curabitur Av.', 'Sed.eget.lacus@fames.edu', '2019-08-18'), 
(29, '91779142', 'Leo', 'Ap #912-6984 Metus Avenue', 'nec.malesuada.ut@mauris.org', '2021-02-05'), 
(30, '13891156', 'Jameson', '2864 Ligula Ave', 'erat@et.org', '2019-10-28'), 
(31, '83463147', 'Burton', 'P.O. Box 189, 9305 Vel, St.', 'ligula@interdumenim.org', '2019-12-22'), 
(32, '76449029', 'Cameron', '7714 Est. Av.', 'tincidunt.tempus@veliteu.net', '2019-06-01'), 
(33, '75305315', 'Simone', '2117 Risus, Rd.', 'Aenean@egetlacusMauris.ca', '2019-10-28'), 
(34, '89300583', 'Cathleen', 'Ap #479-9161 Eu, St.', 'Duis.at.lacus@Integerin.com', '2019-12-09'), 
(35, '29378542', 'Phelan', '3185 Et, St.', 'cubilia.Curae.Donec@adipiscingenimmi.co.uk', '2019-04-20'), 
(36, '73119070', 'Gretchen', '9460 Sed St.', 'ultrices.posuere.cubilia@etmagnisdis.net', '2019-09-02'), 
(37, '19195384', 'Tyrone', 'P.O. Box 435, 3603 Fusce Street', 'mauris.elit.dictum@euduiCum.co.uk', '2021-01-11'), 
(38, '82102510', 'Cailin', '976-9065 Phasellus Rd.', 'Suspendisse.ac@massarutrummagna.com', '2019-05-08'), 
(39, '93471849', 'Geoffrey', '9956 Eget, Road', 'Nulla.tincidunt@purus.net', '2019-08-29'), 
(40, '12898045', 'Odette', 'Ap #891-6197 Lacus. Avenue', 'Vivamus.molestie.dapibus@sodalesatvelit.co.uk', '2021-03-03'), 
(41, '46828965', 'Bryar', '623-586 Nec Av.', 'accumsan.interdum.libero@lobortismaurisSuspendisse.net', '2019-07-16'), 
(42, '60538182', 'Berk', '910-5660 Morbi Road', 'dis@felispurus.ca', '2019-08-29'), 
(43, '32292936', 'Kennedy', '714-664 Ligula. Street', 'vitae@Nam.net', '2019-08-19'), 
(44, '88363649', 'Britanni', 'P.O. Box 517, 9536 Egestas Av.', 'et@Mauris.edu', '2019-04-01'), 
(45, '57602392', 'Graiden', '930-3412 Curae; Avenue', 'nunc.sed.libero@ligulaAenean.ca', '2021-03-08'), 
(46, '15741108', 'Vance', 'P.O. Box 526, 811 Nec, Ave', 'vitae@orciUt.edu', '2019-03-18'), 
(47, '37785477', 'Idona', 'Ap #623-6544 Erat Avenue', 'nisi@sollicitudinorci.co.uk', '2019-04-20'), 
(48, '13079815', 'Jennifer', 'Ap #232-5457 Mollis St.', 'amet.massa.Quisque@mattisornarelectus.co.uk', '2018-05-20'), 
(49, '54081231', 'Wing', 'Ap #753-2391 Montes, Rd.', 'diam@nisi.co.uk', '2019-08-29'), 
(50, '80644709', 'Guy', 'Ap #397-6021 Rutrum, Rd.', 'aliquet@tempordiam.co.uk', '2010-02-27'), 
(51, '18330530', 'Kelly', 'Ap #792-9575 Proin Rd.', 'elementum@Nullamnisl.co.uk', '2019-06-29'), 
(52, '69878236', 'Bell', '644-7093 A Street', 'Aliquam.ultrices@Fuscemollis.ca', '2019-09-06'), 
(53, '74579441', 'Michael', '5003 Rutrum Av.', 'faucibus.orci@anteipsumprimis.edu', '2019-10-27'), 
(54, '38384509', 'Hasad', 'P.O. Box 877, 2308 Sit Rd.', 'Vivamus.sit@Suspendissenon.ca', '2019-05-24'), 
(55, '23464556', 'Emi', '446-9128 Id, Ave', 'morbi@velitin.org', '2019-04-18'), 
(56, '60249359', 'Leroy', 'Ap #349-8979 Egestas Street', 'sagittis.augue.eu@nectempus.net', '2019-01-25'), 
(57, '65299859', 'Ahmed', '934-1173 Placerat St.', 'lorem.Donec.elementum@varius.edu', '2019-07-26'), 
(58, '96931976', 'Owen', 'Ap #574-2224 Morbi St.', 'nec@eratsemper.net', '2019-07-04'), 
(59, '23713213', 'Jermaine', '8816 Pulvinar Rd.', 'mattis.semper@imperdietdictummagna.net', '2019-10-20'), 
(60, '72222592', 'Knox', '7780 Sem Rd.', 'mollis@montesnasceturridiculus.ca', '2019-10-17');


-- insert into Full_time_emp
insert into Full_time_emp (eid, monthly_salary) values 
(1, 623.28),
(2, 515.23),
(3, 760.22),
(4, 848.27),
(5, 968.05),
(6, 972.02),
(7, 397.97),
(8, 937.78),
(9, 326.44),
(10, 802.28),
(11, 822.07),
(12, 323.38),
(13, 361.02),
(14, 517.58),
(15, 482.46),
(16, 329.40),
(17, 769.85),
(18, 718.58),
(19, 531.50),
(20, 317.73),
(21, 902.49),
(22, 709.77),
(23, 363.94),
(24, 371.30),
(25, 894.21),
(26, 406.15),
(27, 560.67),
(28, 781.54),
(29, 540.93),
(30, 567.96),
(31, 669.11),
(32, 356.64),
(33, 586.73),
(34, 516.60),
(35, 728.84),
(36, 760.60),
(37, 948.67),
(38, 337.30),
(39, 629.21),
(40, 990.40);

-- insert into Part_time_emp
insert into Part_time_emp (eid, hourly_rate) values
(41, 3.09),
(42, 7.46),
(43, 4.33),
(44, 8.34),
(45, 3.97),
(46, 6.80),
(47, 3.01),
(48, 8.43),
(49, 6.85),
(50, 4.19),
(51, 4.58),
(52, 6.65),
(53, 5.91),
(54, 7.91),
(55, 9.51),
(56, 8.04),
(57, 5.65),
(58, 5.55),
(59, 5.64),
(60, 8.15);

-- insert into Adminstrators
insert into Administrators (eid) values (11), (12), (13), (14), (15), (16), (17), (18), (19), (20);

-- insert into Managers
insert into Managers (eid) values (21), (22), (23), (24), (25), (26), (27), (28), (29), (30);

-- insert into Instructors
insert into Instructors (eid) values 
(1), (2), (3), (4), (5), (6), (7), (8), (9), (10), (41), (42), (43), (44), (45), (46), (47), (48), (49), (50);

-- insert into Full_time_instructors
insert into Full_time_instructors (eid) values
(1), (2), (3), (4), (5), (6), (7), (8), (9), (10);

-- insert into Part_time_instructors
insert into Part_time_instructors (eid) values 
(41), (42), (43), (44), (45), (46), (47), (48), (49), (50);

-- insert into Course_areas
insert into Course_areas (area_name, eid) values ('Database Systems', 26);
insert into Course_areas (area_name, eid) values ('Networking', 24);
insert into Course_areas (area_name, eid) values ('Programming Methodology', 30);
insert into Course_areas (area_name, eid) values ('Data Structures and Algorithms', 23);
insert into Course_areas (area_name, eid) values ('Software Engineering', 26);
insert into Course_areas (area_name, eid) values ('Machine Learning', 21);
insert into Course_areas (area_name, eid) values ('Parallel Programming', 28);
insert into Course_areas (area_name, eid) values ('Computer Security', 27);
insert into Course_areas (area_name, eid) values ('Operating Systems', 22);
insert into Course_areas (area_name, eid) values ('Media Computing', 22);


-- insert into Specializes
insert into Specializes (eid, area_name) values (10, 'Computer Security');  
insert into Specializes (eid, area_name) values (3, 'Computer Security');  
insert into Specializes (eid, area_name) values (48, 'Software Engineering');  
insert into Specializes (eid, area_name) values (4, 'Software Engineering');  
insert into Specializes (eid, area_name) values (10, 'Database Systems');  
insert into Specializes (eid, area_name) values (2, 'Database Systems');
insert into Specializes (eid, area_name) values (8, 'Computer Security');  
insert into Specializes (eid, area_name) values (43, 'Computer Security');
insert into Specializes (eid, area_name) values (6, 'Software Engineering');
insert into Specializes (eid, area_name) values (8, 'Software Engineering');  
insert into Specializes (eid, area_name) values (46, 'Software Engineering');  
insert into Specializes (eid, area_name) values (41, 'Data Structures and Algorithms');  
insert into Specializes (eid, area_name) values (4, 'Data Structures and Algorithms'); 
insert into Specializes (eid, area_name) values (1, 'Operating Systems'); 
insert into Specializes (eid, area_name) values (6, 'Operating Systems');
insert into Specializes (eid, area_name) values (45, 'Machine Learning');  
insert into Specializes (eid, area_name) values (5, 'Machine Learning');
insert into Specializes (eid, area_name) values (49, 'Parallel Programming');   
insert into Specializes (eid, area_name) values (9, 'Parallel Programming');


-- insert into Rooms
insert into Rooms (rid, floor, room_number, seating_capacity) values (1, 1, 1, 29);
insert into Rooms (rid, floor, room_number, seating_capacity) values (2, 1, 2, 24);
insert into Rooms (rid, floor, room_number, seating_capacity) values (3, 1, 3, 75);
insert into Rooms (rid, floor, room_number, seating_capacity) values (4, 1, 4, 27);
insert into Rooms (rid, floor, room_number, seating_capacity) values (5, 1, 5, 73);
insert into Rooms (rid, floor, room_number, seating_capacity) values (6, 2, 1, 60);
insert into Rooms (rid, floor, room_number, seating_capacity) values (7, 2, 2, 41);
insert into Rooms (rid, floor, room_number, seating_capacity) values (8, 2, 3, 47);
insert into Rooms (rid, floor, room_number, seating_capacity) values (9, 2, 4, 68);
insert into Rooms (rid, floor, room_number, seating_capacity) values (10, 2, 5, 45);

-- insert into Courses
insert into Courses (course_id, title, duration, description, area_name) values (default, 'Basic Data Structure', 2, 'a course', 'Data Structures and Algorithms');
insert into Courses (course_id, title, duration, description, area_name) values (default, 'Basic Media Computing', 3, 'a course', 'Media Computing');
insert into Courses (course_id, title, duration, description, area_name) values (default, 'Software Engineering I', 1, 'a course', 'Software Engineering');
insert into Courses (course_id, title, duration, description, area_name) values (default, 'Advanced SQL', 1, 'a course', 'Database Systems');
insert into Courses (course_id, title, duration, description, area_name) values (default, 'Networking I', 2, 'a course', 'Networking');
insert into Courses (course_id, title, duration, description, area_name) values (default, 'Algorithms I', 1, 'a course', 'Data Structures and Algorithms');
insert into Courses (course_id, title, duration, description, area_name) values (default, 'Basic SQL', 2, 'a course', 'Database Systems');
insert into Courses (course_id, title, duration, description, area_name) values (default, 'Python Programming', 3, 'a course', 'Programming Methodology');
insert into Courses (course_id, title, duration, description, area_name) values (default, 'Computer Security I', 3, 'a course', 'Computer Security');
insert into Courses (course_id, title, duration, description, area_name) values (default, 'Parallel Programming I', 3, 'a course', 'Parallel Programming');
insert into Courses (course_id, title, duration, description, area_name) values (default, 'Algorithms II', 1, 'a course', 'Data Structures and Algorithms');
insert into Courses (course_id, title, duration, description, area_name) values (default, 'Software Engineering II', 2, 'a course', 'Software Engineering');
insert into Courses (course_id, title, duration, description, area_name) values (default, 'Software Engineering III', 1, 'a course', 'Software Engineering');
insert into Courses (course_id, title, duration, description, area_name) values (default, 'Computer Security II', 3, 'a course', 'Computer Security');
insert into Courses (course_id, title, duration, description, area_name) values (default, 'Intermediate SQL', 3, 'a course', 'Database Systems');
insert into Courses (course_id, title, duration, description, area_name) values (default, 'Machine Learning I', 3, 'a course', 'Machine Learning');
insert into Courses (course_id, title, duration, description, area_name) values (default, 'Java Programming', 1, 'a course', 'Programming Methodology');
insert into Courses (course_id, title, duration, description, area_name) values (default, 'Machine Learning II', 3, 'a course', 'Machine Learning');
insert into Courses (course_id, title, duration, description, area_name) values (default, 'Advanced Software Engineering', 1, 'a course', 'Software Engineering');
insert into Courses (course_id, title, duration, description, area_name) values (default, 'Basic Operating Systems', 2, 'a course', 'Operating Systems');





-- insert into Offerings
insert into Offerings (offering_id, launch_date, course_id, fees, start_date, end_date, registration_deadline, seating_capacity, target_number_registrations, eid) values (1, '2020-01-22', 14, 489.34, '2020-03-13', '2020-08-07', '2020-02-23', 51, 50, 19);
insert into Offerings (offering_id, launch_date, course_id, fees, start_date, end_date, registration_deadline, seating_capacity, target_number_registrations, eid) values (2, '2020-02-02', 12, 373.73, '2020-05-19', '2020-11-10', '2020-04-18', 53, 52, 14);
insert into Offerings (offering_id, launch_date, course_id, fees, start_date, end_date, registration_deadline, seating_capacity, target_number_registrations, eid) values (3, '2020-01-28', 7, 421.75, '2020-11-19', '2020-12-30', '2020-04-01', 99, 98, 16);
insert into Offerings (offering_id, launch_date, course_id, fees, start_date, end_date, registration_deadline, seating_capacity, target_number_registrations, eid) values (4, '2020-02-17', 14, 348.19, '2020-06-03', '2020-08-03', '2020-04-23', 74, 70, 18);
insert into Offerings (offering_id, launch_date, course_id, fees, start_date, end_date, registration_deadline, seating_capacity, target_number_registrations, eid) values (5, '2020-02-12', 12, 240.31, '2020-05-21', '2020-06-29', '2020-03-25', 116, 100, 20);
insert into Offerings (offering_id, launch_date, course_id, fees, start_date, end_date, registration_deadline, seating_capacity, target_number_registrations, eid) values (6, '2020-01-07', 13, 383.29, '2020-10-09', '2020-12-31', '2020-02-27', 122, 111, 18);
insert into Offerings (offering_id, launch_date, course_id, fees, start_date, end_date, registration_deadline, seating_capacity, target_number_registrations, eid) values (7, '2020-02-17', 1, 442.84, '2020-04-29', '2020-10-22', '2020-03-30', 92, 91, 20);
insert into Offerings (offering_id, launch_date, course_id, fees, start_date, end_date, registration_deadline, seating_capacity, target_number_registrations, eid) values (8, '2020-02-20', 20, 349.04, '2020-09-23', '2020-12-14', '2020-07-27', 87, 85, 13);
insert into Offerings (offering_id, launch_date, course_id, fees, start_date, end_date, registration_deadline, seating_capacity, target_number_registrations, eid) values (9, '2021-01-16', 16, 485.04, '2021-08-13', '2021-10-12', '2021-04-26', 143, 140, 20);
insert into Offerings (offering_id, launch_date, course_id, fees, start_date, end_date, registration_deadline, seating_capacity, target_number_registrations, eid) values (10, '2021-02-16', 10, 341.78, '2021-06-02', '2021-12-20', '2021-04-30', 56, 55, 20);



-- insert into Sessions
insert into Sessions (sid, session_date, start_time, end_time, rid, eid, offering_id) values (1, '2020-03-13', 14, 17, 2, 10, 1);   
insert into Sessions (sid, session_date, start_time, end_time, rid, eid, offering_id) values (2, '2020-08-07', 9, 12,  4, 3, 1);  
insert into Sessions (sid, session_date, start_time, end_time, rid, eid, offering_id) values (1, '2020-05-19', 9, 11,  1, 48, 2); 
insert into Sessions (sid, session_date, start_time, end_time, rid, eid, offering_id) values (2, '2020-11-10', 9, 12,  2, 4, 2);  
insert into Sessions (sid, session_date, start_time, end_time, rid, eid, offering_id) values (1, '2020-11-19', 15, 17, 3, 10, 3); 
insert into Sessions (sid, session_date, start_time, end_time, rid, eid, offering_id) values (2, '2020-12-30', 14, 16, 2, 2, 3);  
insert into Sessions (sid, session_date, start_time, end_time, rid, eid, offering_id) values (1, '2020-06-03', 14, 17, 4, 8, 4); 
insert into Sessions (sid, session_date, start_time, end_time, rid, eid, offering_id) values (2, '2020-08-03', 15, 18, 8, 43, 4); 
insert into Sessions (sid, session_date, start_time, end_time, rid, eid, offering_id) values (1, '2020-05-21', 14, 16,  3, 4, 5);  
insert into Sessions (sid, session_date, start_time, end_time, rid, eid, offering_id) values (2, '2020-06-29', 15, 17, 7, 6, 5); 
insert into Sessions (sid, session_date, start_time, end_time, rid, eid, offering_id) values (1, '2020-10-09', 15, 16, 8, 8, 6); 
insert into Sessions (sid, session_date, start_time, end_time, rid, eid, offering_id) values (2, '2020-12-31', 15, 16, 3, 46, 6);  
insert into Sessions (sid, session_date, start_time, end_time, rid, eid, offering_id) values (1, '2020-04-29', 9, 11, 10, 41, 7); 
insert into Sessions (sid, session_date, start_time, end_time, rid, eid, offering_id) values (2, '2020-10-22', 16, 18, 8, 4, 7); 
insert into Sessions (sid, session_date, start_time, end_time, rid, eid, offering_id) values (1, '2020-09-23', 15, 17, 6, 1, 8);  
insert into Sessions (sid, session_date, start_time, end_time, rid, eid, offering_id) values (2, '2020-12-14', 10, 12, 4, 6, 8); 
insert into Sessions (sid, session_date, start_time, end_time, rid, eid, offering_id) values (1, '2021-08-13', 14, 17,  3, 45, 9);  
insert into Sessions (sid, session_date, start_time, end_time, rid, eid, offering_id) values (2, '2021-10-12', 9, 12, 9, 5, 9);  
insert into Sessions (sid, session_date, start_time, end_time, rid, eid, offering_id) values (1, '2021-06-02', 14, 16,  1, 49, 10);  
insert into Sessions (sid, session_date, start_time, end_time, rid, eid, offering_id) values (2, '2021-12-20', 9, 12,  4, 9, 10); 




