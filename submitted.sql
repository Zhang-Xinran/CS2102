DROP VIEW IF EXISTS zzanswer CASCADE;
DROP VIEW IF EXISTS v1, v2, v3, v4, v5, v6, v7, v8, v9, v10 CASCADE;

create or replace view v1 (pizza) AS
select pizza
from Sells S, Restaurants R, Customers C
where S.rname = R.rname and R.area = C.area and C.cname = 'Bob'
;

create or replace view v2 (cname) AS
select cname
from Customers C
where (
select count(*) 
from Likes L 
where L.cname = C.cname
) >= 2
;

create or replace view v3 (rname1, rname2) AS
select R1.rname, R2.rname
from Restaurants R1, Restaurants R2
where R1.rname <> R2.rname 
and (
select count(*)
from Sells S1, Sells S2
where S1.pizza = S2.pizza and S1.rname = R1.rname and S2.rname = R2.rname and S1.price <= S2.price
) = 0
and (
select count(*)
from Sells S3, Sells S4
where S3.pizza = S4.pizza and S3.rname = R1.rname and S4.rname = R2.rname
) > 0
;

create or replace view v4 (rname) AS
select rname
from Restaurants R
where R.area = 'Central'
or (
select count(*)
from Sells S
where S.rname = R.rname
) >= 10
or ((
select count(*)
from Sells S
where S.rname = R.rname and S.price > 20
) = 0 and (
select count(*)
from Sells S
where S.rname = R.rname
) > 0)
;


create or replace view v5 (rname) AS
select rname
from Restaurants R
where (
select avg(price)
from (
select price
from Sells S
where S.rname = R.rname
order by price asc
limit 2
) as Price
) <= 20 
and (
select count(*)
from Sells S
where S.rname = R.rname
) >= 2
;

create or replace view v6 (rname, pizza1, pizza2, pizza3, totalcost) AS
select S1.rname, S1.pizza, S2.pizza, S3.pizza, S1.price + S2.price + S3.price
from Sells S1, Sells S2, Sells S3
where (S1.rname = S2.rname and S2.rname = S3.rname)
and (S1.pizza <> S2.pizza and S2.pizza <> S3.pizza and S1.pizza <> S3.pizza)
and (S1.price + S2.price + S3.price <= 80)
and ((
select count(*) from Likes L where L.pizza = S1.pizza and (L.cname = 'Moe' or L.cname = 'Larry' or L.cname = 'Curly')) >= 1
)
and ((
select count(*) from Likes L where L.pizza = S2.pizza and (L.cname = 'Moe' or L.cname = 'Larry' or L.cname = 'Curly')) >= 1
)
and ((
select count(*) from Likes L where L.pizza = S3.pizza and (L.cname = 'Moe' or L.cname = 'Larry' or L.cname = 'Curly')) >= 1
)
and ((select count(*) 
from Likes L 
where L.cname = 'Moe' 
and (L.pizza = S1.pizza or L.pizza = S2.pizza or L.pizza = S3.pizza)) >= 2
)
and ((select count(*) 
from Likes L 
where L.cname = 'Larry' 
and (L.pizza = S1.pizza or L.pizza = S2.pizza or L.pizza = S3.pizza)) >= 2
)
and ((select count(*) 
from Likes L 
where L.cname = 'Curly' 
and (L.pizza = S1.pizza or L.pizza = S2.pizza or L.pizza = S3.pizza)) >= 2
)
and (
S1.pizza < S2.pizza and S2.pizza < S3.pizza
)
;

create or replace view v7 (rname) AS
select rname
from Restaurants R
where (
(
(
select count(*) from Sells where Sells.rname = R.rname
) >= all (
select count(*) from Sells group by rname
)
) or (
(
select max(price) - min(price) from (select price from Sells where Sells.rname = R.rname) as Price
) > all (
select max(price) - min(price) from (select rname, price from Sells where Sells.rname <> R.rname) as Price group by rname
)
)
) and ( 
(
(
select count(*) from Sells where Sells.rname = R.rname
) > all (
select count(*) from Sells where Sells.rname <> R.rname group by rname
) 
) or (
(
select max(price) - min(price) from (select price from Sells where Sells.rname = R.rname) as Price
) >= all (
select max(price) - min(price) from (select rname, price from Sells) as Price group by rname
)
)
) 
;

create or replace view v8 (area, numCust, numRest, maxPrice) AS
select A.area, COALESCE(C.numCust, 0), COALESCE(R.numRest, 0), COALESCE(P.maxPrice, 0)
from (select distinct area from Customers) as A
left join (select area, count(cname) as numCust from Customers group by area) as C
on A.area = C.area
left join (select area, count(rname) as numRest from Restaurants group by area) as R
on A.area = R.area
left join (select area, max(price) as maxPrice from (select area, pizza, price from Restaurants Re, Sells S where Re.rname = S.rname) as X group by area) as P
on A.area = P.area
;


create or replace view v9 (cname) AS
select A.cname
from ( 
select Z.cname, min(Z.numPizza) as minPizza 
from (
select X.cname, X.pizza, COALESCE(Y.numRes, 0) as numPizza
from (
select Customers.cname, pizza, area 
from Likes inner join Customers on Likes.cname = Customers.cname
) as X
left join
(
select pizza, area, count(*) as numRes 
from Sells inner join Restaurants on Sells.rname = Restaurants.rname
group by pizza, area
) as Y
on X.pizza = Y.pizza and X.area = Y.area

)as Z

group by Z.cname
) as A
where A.minPizza >= 2
;

create or replace view v10 (pizza) AS
select Z.pizza 
from (
select pizza, count(*) as numPopular
from (
select pizza, area
from (
select pizza, area, count(*) as numPizza
from Sells inner join Restaurants on Sells.rname = Restaurants.rname
group by pizza, area
) as X

where numPizza = (
select max(numPizza)
from (
select pizza, area, count(*) as numPizza
from Sells inner join Restaurants on Sells.rname = Restaurants.rname
group by pizza, area
) as A
where X.area = A.area
)
) as Y
group by pizza
) as Z
where numPopular = (
select max(numPopular) 
from (
select pizza, count(*) as numPopular
from (
select pizza, area
from (
select pizza, area, count(*) as numPizza
from Sells inner join Restaurants on Sells.rname = Restaurants.rname
group by pizza, area
) as Z1
where numPizza = (
select max(numPizza)
from (
select pizza, area, count(*) as numPizza
from Sells inner join Restaurants on Sells.rname = Restaurants.rname
group by pizza, area
) as A
where Z1.area = A.area
)

) as X1
group by pizza
) as Y1)
;
