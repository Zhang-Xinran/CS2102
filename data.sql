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
insert into Customers (cust_id, address, phone, name, email) values (1, '2307 Tellus. Road', '(494) 745-3105', 'Levi Ball', 'litora.torquent.per@tincidunttempus.org');
insert into Customers (cust_id, address, phone, name, email) values (2, 'P.O. Box 335, 4573 Sem Av.','(593) 253-5993', 'Kadeem Carr', 'penatibus.et@pedemalesuada.org');
insert into Customers (cust_id, address, phone, name, email) values (3, '104-4454 Sit Rd.', '(866) 976-7577', 'Keane Holloway', 'tincidunt@sapien.net');
insert into Customers (cust_id, address, phone, name, email) values (4, '1306 Magna. Ave', '(290) 558-8204', 'Chaim Travis', 'ante.Nunc.mauris@scelerisque.ca');
insert into Customers (cust_id, address, phone, name, email) values (5, 'P.O. Box 697, 9829 Nam St.', '(913) 690-5047', 'Keane Beck', 'dapibus@egetvenenatisa.net');
insert into Customers (cust_id, address, phone, name, email) values (6, '1207 Consectetuer Street', '(809) 688-9388', 'Nolan Bishop', 'dui.Fusce@ligulaconsectetuerrhoncus.ca');
insert into Customers (cust_id, address, phone, name, email) values (7, '104-4309 Eget Ave', '(231) 794-8365', 'Hasad Blake', 'orci.consectetuer@ultricies.co.uk');
insert into Customers (cust_id, address, phone, name, email) values (8, 'Ap #829-717 Lectus Ave', '(919) 404-8257', 'Harding Langley', 'mus.Proin.vel@semegestas.co.uk');
insert into Customers (cust_id, address, phone, name, email) values (9, '1543 Vitae Road', '(888) 839-7843', 'Blake Powell', 'nec@consequat.org');
insert into Customers (cust_id, address, phone, name, email) values (10, '728-3216 Curabitur Rd.', '(458) 843-0891', 'Harrison Hardy', 'pellentesque@Morbinon.com');

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
insert into Course_packages (package_id, name, sale_start_date, sale_end_date, num_free_registration, price)
values (1, 'Package 1', '2021-03-01', '2021-05-30', 10, 100.00);
insert into Course_packages (package_id, name, sale_start_date, sale_end_date, num_free_registration, price)
values (2, 'Package 2', '2021-03-01', '2021-08-30', 15, 150.00);
insert into Course_packages (package_id, name, sale_start_date, sale_end_date, num_free_registration, price)
values (3, 'Package 3', '2021-03-01', '2021-09-30', 14, 140.00);
insert into Course_packages (package_id, name, sale_start_date, sale_end_date, num_free_registration, price)
values (4, 'Package 4', '2021-03-01', '2021-10-31', 5, 50.00);
insert into Course_packages (package_id, name, sale_start_date, sale_end_date, num_free_registration, price)
values (5, 'Package 5', '2021-03-01', '2021-10-31', 10, 100.00);
insert into Course_packages (package_id, name, sale_start_date, sale_end_date, num_free_registration, price)
values (6, 'Package 6', '2021-03-01', '2021-11-30', 8, 80.00);
insert into Course_packages (package_id, name, sale_start_date, sale_end_date, num_free_registration, price)
values (7, 'Package 7', '2021-03-01', '2021-11-30', 10, 100.00);
insert into Course_packages (package_id, name, sale_start_date, sale_end_date, num_free_registration, price)
values (8, 'Package 8', '2021-03-01', '2021-12-31', 12, 120.00);
insert into Course_packages (package_id, name, sale_start_date, sale_end_date, num_free_registration, price)
values (9, 'Package 9', '2021-03-01', '2021-12-31', 3, 40.00);
insert into Course_packages (package_id, name, sale_start_date, sale_end_date, num_free_registration, price)
values (10, 'Package 10', '2021-03-01', '2021-05-30', 5, 50.00);

-- insert into 