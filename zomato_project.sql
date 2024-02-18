
drop table if exists goldusers_signup;
CREATE TABLE goldusers_signup(userid integer,gold_signup_date date); 

INSERT INTO goldusers_signup(userid,gold_signup_date) 
 VALUES (1,'09-22-2017'),
(3,'04-21-2017');

drop table if exists users;
CREATE TABLE users(userid integer,signup_date date); 

INSERT INTO users(userid,signup_date) 
 VALUES (1,'09-02-2014'),
(2,'01-15-2015'),
(3,'04-11-2014');

drop table if exists sales;
CREATE TABLE sales(userid integer,created_date date,product_id integer); 

INSERT INTO sales(userid,created_date,product_id) 
 VALUES (1,'04-19-2017',2),
(3,'12-18-2019',1),
(2,'07-20-2020',3),
(1,'10-23-2019',2),
(1,'03-19-2018',3),
(3,'12-20-2016',2),
(1,'11-09-2016',1),
(1,'05-20-2016',3),
(2,'09-24-2017',1),
(1,'03-11-2017',2),
(1,'03-11-2016',1),
(3,'11-10-2016',1),
(3,'12-07-2017',2),
(3,'12-15-2016',2),
(2,'11-08-2017',2),
(2,'09-10-2018',3);


drop table if exists product;
CREATE TABLE product(product_id integer,product_name text,price integer); 

INSERT INTO product(product_id,product_name,price) 
 VALUES
(1,'p1',980),
(2,'p2',870),
(3,'p3',330);


select * from sales;
select * from product;
select * from goldusers_signup;
select * from users;

--1)total amount spent by each customer?

select a.userid, sum(b.price) as spent from sales a join product b on a.product_id = b.product_id 
group by a.userid


--2)how many unique days each customer visited zomato?

select userid, count(distinct created_date) as days  from sales group by userid order by userid


--3) first product purchased by each customer

select a.userid, a.created_date, b.product_name from sales a join product b on a.product_id= b.product_id 
order by userid, created_date

select b.userid, b.product_id, p.product_name from
(select userid, product_id from 
(select *, rank() over(partition by userid order by created_date) as rnk from sales) a where rnk =1)b join product p on b.product_id = p.product_id

--4) most purchased item on menu and the number of times purchased  by all customers?

select userid, count(product_id) as cnt from sales where product_id =
(select top 1 product_id from sales a group by product_id order by count(product_id)  desc) group by userid


--5) Most popular item for each customer

select * from(
select *, rank() over(partition by userid order by cnt desc) as rnk from
(select userid, product_id, count(product_id)as cnt from sales group by userid, product_id) a)b where rnk =1


--6) First purchased item after becoming member(gold)

  select * from
  (select *, rank() over(partition by userid order by created_date) as rnk from
  (select a.userid,a.created_date, a.product_id, b.gold_signup_date from sales a inner join goldusers_signup b on a.userid= b.userid  
  where gold_signup_date<=created_date) c)d where rnk =1


  
--7) First purchased item just before a becoming member(gold)

select * from
(select *, rank() over(partition by userid order by created_date desc) as rnk from
(select a.userid,a.created_date, a.product_id, b.gold_signup_date from sales a inner join goldusers_signup b on a.userid= b.userid  
  where gold_signup_date>created_date) c)d where rnk =1


--8) Wht is the total orders and amount spent for each member before they become a member?

select userid, sum(price) as amount_spent,count(created_date) as total_orders from
(select c.*, d.price from 
(select a.userid,a.created_date, a.product_id, b.gold_signup_date from sales a inner join goldusers_signup b on a.userid= b.userid  
  where gold_signup_date>created_date)c inner join product d on c.product_id = d.product_id) e group by userid



 --9) If buying each product generates points, 2 points for 5 rupees and each produuct has different points, for each point for p1 its 5rupes, for p2 its 2rs and 
        --for p3 its 5rs 
     --so, for points to money after converting them all to points  2 points for 5 rupees and each produuct (1 points for 2.5 rupees and each produuct at last )

select userid, sum(Total_points) as points_earned, sum(Total_points)*2.5 as cashback_earned from
(select e.*, total/points as Total_points from
(select d.*, case when product_id = 1 then 5 when product_id  = 2 then 2  when product_id = 3 then 5 else 0 end as points from
(select c.userid, c.product_id, sum(price) as total from
(select a.*, b.price,b.product_name from sales a join product b on a.product_id = b.product_id) c
group by userid,product_id)d) e)f group by userid

--10) Total amount spent by users for 1 year after gold membership and zomato points for a year after membershp are 5points for 10 rupees

select e.userid, sum(e.price)as total_spent,sum(e.price)*0.5 as total_points from
(select c.*, d.price from
(select a.userid, a.created_date,a.product_id, b.gold_signup_date from sales a join goldusers_signup b  on a.userid = b.userid
where a.created_date >= b.gold_signup_date and a.created_date <=dateadd(year,1,b.gold_signup_date))c join product d on c.product_id= d.product_id)e
group by userid


--11) rank all the transaction of customers

 select *, rank() over(partition by userid order by created_date) as rnk from sales

 --12)rank all transactions for each customer after becoming a goldmember for non gold mem transaction mark as NA

select d.*, case when rnk = 0 then 'NA' else rnk end as rnkk from
(select c.*, cast((case when gold_signup_date is NULL then 0 else rank()over(partition by userid order by created_date desc) end) as varchar) as rnk from
(select a.userid,a.created_date,a.product_id, b.gold_signup_date from sales a left join goldusers_signup b on a.userid = b.userid
and gold_signup_date<=a.created_date) c)d;
 
