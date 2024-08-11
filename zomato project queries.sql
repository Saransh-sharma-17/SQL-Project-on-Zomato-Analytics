CREATE TABLE goldusers_signup
(userid integer,
 gold_signup_date date); 

INSERT INTO goldusers_signup
(userid,gold_signup_date) 
 VALUES 
(1,'09-22-2017'),
(3,'04-21-2017');

CREATE TABLE users
(userid integer,signup_date date); 

INSERT INTO users
 VALUES 
(1,'09-02-2014'),
(2,'01-15-2015'),
(3,'04-11-2014');

CREATE TABLE sales
(userid integer,created_date date,product_id integer); 

INSERT INTO sales(userid,created_date,product_id) 
 VALUES
(1,'04-19-2017',2),
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

CREATE TABLE product
(product_id integer,product_name text,price integer); 

INSERT INTO product(product_id,product_name,price) 
 VALUES
(1,'p1',980),
(2,'p2',870),
(3,'p3',330);

SELECT * FROM goldusers_signup

SELECT * FROM product

SELECT * FROM sales

SELECT * FROM users

---- 1. What is the total amount each customer spent on zomato? 

SELECT s.userid, SUM(p.price) as total_amt_spent
FROM sales as s
JOIN product as p
ON s.product_id = p.product_id 
GROUP BY userid
ORDER BY userid ASC;

--- 2. How many days has each customer visited zomato? 

SELECT userid, COUNT(DISTINCT created_date) as distinct_date
FROM sales
GROUP BY userid;

--- 3. What was the first product purchased by each customer? 

SELECT * FROM 
(SELECT *, RANK() OVER(PARTITION BY userid ORDER BY created_date) as rnk FROM sales)
WHERE rnk = 1;

--- 4. What is the most purchased item on the menu and how many times was it purchased by all customers? 

SELECT userid, COUNT(product_id) as cnt FROM sales
WHERE product_id = 
                  (SELECT product_id FROM sales
                   GROUP BY product_id
                   ORDER BY count(product_id) DESC
                   LIMIT 1)
GROUP BY userid;

--- 5. Which item was the most popular for each customer? 

SELECT * FROM 
(SELECT *, RANK() OVER(PARTITION BY userid ORDER BY product_id) as rnk FROM 
(SELECT userid, product_id, COUNT(product_id) as cnt FROM sales GROUP BY userid, product_id) AS a) as b
WHERE rnk = 1;

--- 6. Which item was purchased first by the customer after they became a member? 

SELECT * FROM sales

SELECT * FROM goldusers_signup

SELECT * FROM 
(SELECT a.*, RANK() OVER(PARTITION BY userid ORDER BY created_date ASC) as rnk FROM 
(SELECT s.userid, s.created_date, s.product_id, gus.gold_signup_date
FROM sales as s
INNER JOIN goldusers_signup as gus
ON s.userid = gus.userid and created_date >= gold_signup_date) AS a)
WHERE rnk = 1;

--- 7. Which item was purchased just before the customer became a member? 

SELECT * FROM 
(SELECT a.*, RANK() OVER(PARTITION BY userid ORDER BY created_date DESC) as rnk FROM 
(SELECT s.userid, s.created_date, s.product_id, gus.gold_signup_date
FROM sales as s
INNER JOIN goldusers_signup as gus
ON s.userid = gus.userid and created_date <= gold_signup_date) as a)
WHERE rnk = 1;

--- 8. What is the total orders and amount spent for each member before they become a member? 

SELECT userid, COUNT(created_date) as order_purchased, SUM(price) as total_smt_spent FROM 
(SELECT a.*, p.price FROM 
(SELECT s.userid, s.created_date, s.product_id, gus.gold_signup_date
FROM sales as s
INNER JOIN goldusers_signup as gus
ON s.userid = gus.userid and created_date <= gold_signup_date) as A
INNER JOIN product as p
ON a.product_id = p.product_id) as B
GROUP BY userid;

--- 9. If buying each product generates points for eg. 5rs = 2 zomoto points and each product has different purchase 
--     points for eg. for p1 5rs = 1 zomato point, for p2 10rs = 5 zomato points and p3 5rs = 1 zomato point.
--     Calculate points collected by each customer and for which product most points have been given till now ? 
       (2rs = 1 zomato points)

SELECT * FROM sales

SELECT d.userid, SUM(total_points) as total_points_earned FROM
(SELECT c.*, amt/points as total_points FROM 
(SELECT B.*, CASE 
WHEN product_id = 1 THEN 5
WHEN product_id = 2 THEN 2
WHEN product_id = 3 THEN 5
ELSE 0 END AS points FROM 
(SELECT a.userid, a.product_id, SUM(price) as amt FROM
(SELECT s.*, p.price 
FROM sales AS s
INNER JOIN product as p
ON s.product_id = p.product_id) AS a
GROUP BY userid, product_id) as b) AS C) AS D
GROUP BY userid
ORDER BY userid ASC;

SELECT * FROM
(SELECT E.*, RANK() OVER(ORDER BY total_points_earned DESC) rnk FROM
(SELECT d.product_id, SUM(total_points) as total_points_earned FROM
(SELECT c.*, amt/points as total_points FROM 
(SELECT B.*, CASE 
WHEN product_id = 1 THEN 5
WHEN product_id = 2 THEN 2
WHEN product_id = 3 THEN 5
ELSE 0 END AS points FROM 
(SELECT a.userid, a.product_id, SUM(price) as amt FROM
(SELECT s.*, p.price 
FROM sales AS s
INNER JOIN product as p
ON s.product_id = p.product_id) AS a
GROUP BY userid, product_id) as b) AS C) AS D
GROUP BY product_id
ORDER BY product_id ASC) AS E)
WHERE rnk = 1;

--- 10. If the first one year after a customer joins the gold program (including their join date) irrespective of what
--      the customer has purchased they earn 5 zomato points for every 10rs spent who earned more 1 or 3 and what 
--      was their points earnings in their first year ? (1 ZOMATO POINTS = 2RS)   (0.5 points = 1rs)

SELECT b.*, b.price*0.5 as total_points_earned FROM 
(SELECT a.*, p.price FROM 
(SELECT s.userid, s.created_date, s.product_id, gus.gold_signup_date
FROM sales as s
INNER JOIN goldusers_signup as gus
ON s.userid = gus.userid and created_date >= gold_signup_date and created_date <= gold_signup_date+365) AS a
INNER JOIN product as p
ON a.product_id = p.product_id ORDER BY userid ASC) AS b;

--- 11. Rank all the transactions of the customers 

SELECT *, RANK() OVER(PARTITION BY userid ORDER BY created_date ASC) AS rank FROM sales;

--- 12. Rank all the transations of each member whenever they are a zomato gold member for every no gold member 
--      transaction mark as na

SELECT b.*,CASE WHEN rnk=0 THEN 'na' ELSE rnk END as rnkk FROM 
(SELECT a.*,CAST((CASE 
WHEN gold_signup_date is null THEN 0 
ELSE RANK() OVER(PARTITION BY userid ORDER BY created_date DESC) END) AS varchar) AS rnk FROM 
(SELECT s.userid, s.created_date, s.product_id, gus.gold_signup_date
FROM sales as s
LEFT JOIN goldusers_signup as gus
ON s.userid = gus.userid and created_date >= gold_signup_date) AS a) AS b

