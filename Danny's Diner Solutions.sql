

CREATE DATABASE danny_diner;

CREATE TABLE sales (
  customer_id VARCHAR(1),
  order_date DATE,
  product_id INTEGER
);

INSERT INTO sales
  (customer_id, order_date, product_id)
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  product_id INTEGER,
  product_name VARCHAR(5),
  price INTEGER
);

INSERT INTO menu
  (product_id, product_name, price)
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  customer_id VARCHAR(1),
  join_date DATE
);

INSERT INTO members
  (customer_id, join_date)
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');
  
  
  
  
  /* --------------------
   Case Study Questions
   --------------------*/

-- 1. What is the total amount each customer spent at the restaurant?

SELECT
	customer_id
  , SUM(price) AS 'Total_amount'
FROM sales
JOIN menu
    ON sales.product_id = menu.product_id
GROUP BY customer_id;
    
-- 2. How many days has each customer visited the restaurant?

SELECT 
	customer_id
  , COUNT(DISTINCT order_date) AS 'Total_no_visited'
FROM sales
GROUP BY customer_id;

-- 3. What was the first item from the menu purchased by each customer?

SELECT 
	customer_id
  , order_date
  , GROUP_CONCAT( DISTINCT product_name) AS 'first_orders'
FROM ( SELECT 
		customer_id
	  , order_date
	  , product_name
	  , DENSE_RANK() OVER(PARTITION BY customer_id ORDER BY order_date) AS 'order_rank'
	FROM sales
	JOIN menu
		ON sales.product_id = menu.product_id ) orders
WHERE order_rank = 1
GROUP BY customer_id;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT 
	customer_id
  , product_name
  , COUNT(*) AS 'number_of_orders'
FROM (SELECT
			sales.product_id
		  , menu.product_name
		  , COUNT(sales.product_id) AS 'no_of_orders'
		FROM sales
		JOIN menu
			ON sales.product_id = menu.product_id
		GROUP BY sales.product_id
		ORDER BY no_of_orders DESC
		LIMIT 1 ) items
JOIN sales
    ON items.product_id = sales.product_id
GROUP BY customer_id
	   , sales.product_id;
  
-- 5. Which item was the most popular for each customer?

WITH FavItem AS ( SELECT 
						customer_id
					  , product_name
					  , COUNT(*) AS 'most_order'
					  , DENSE_RANK() OVER(PARTITION BY customer_id ORDER BY COUNT(*) DESC) AS 'order_rank' 
					FROM sales
					JOIN menu
						ON sales.product_id = menu.product_id
					GROUP BY sales.product_id
					       , customer_id
					ORDER BY customer_id
					       , most_order DESC )
SELECT 
	customer_id
  , GROUP_CONCAT(DISTINCT product_name) AS 'FavItem'
  , most_order
FROM FavItem
	WHERE order_rank = 1
	GROUP BY customer_id;
    
-- 6. Which item was purchased first by the customer after they became a member?

SELECT
	DISTINCT sales.customer_id
  , order_date
  , menu.product_name
FROM sales
JOIN menu
	ON sales.product_id = menu.product_id
JOIN members
	ON sales.customer_id = members.customer_id
	WHERE sales.order_date >= members.join_date 
    GROUP BY sales.customer_id
	ORDER BY customer_id;

-- 7. Which item was purchased just before the customer became a member?

WITH previous_order AS ( SELECT 
								sales.customer_id
							  , order_date
							  , product_name
							  , DENSE_RANK() OVER(PARTITION BY customer_id ORDER BY order_date DESC) AS 'last_order'
							FROM sales
							JOIN members
								ON sales.customer_id = members.customer_id
							JOIN menu
								ON sales.product_id = menu.product_id
								WHERE sales.order_date < members.join_date )
SELECT 
	customer_id
  , order_date
  , GROUP_CONCAT(DISTINCT product_name) AS 'last_orders'
FROM previous_order
WHERE last_order = 1
	GROUP BY customer_id ;
        
-- 8. What is the total items and amount spent for each member before they became a member?

SELECT
	sales.customer_id
  , COUNT(DISTINCT product_name) AS 'Total_items'
  , SUM(price) AS 'Total_amount'
FROM sales
JOIN members
    ON sales.customer_id = members.customer_id
JOIN menu
	ON sales.product_id = menu.product_id
	WHERE sales.order_date < members.join_date
    GROUP BY sales.customer_id ;
        
-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

WITH cte_points AS ( SELECT
						customer_id
					  , CASE
							WHEN product_name = 'sushi' THEN price * 20
                            ELSE price * 10
                            END AS 'points'
					FROM sales
                    JOIN menu
						ON sales.product_id = menu.product_id )
SELECT 
	customer_id
  , SUM(points) AS 'points'
FROM cte_points
	GROUP BY customer_id;

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

WITH total_points AS ( SELECT 
						   sales.customer_id
						 , MONTHNAME(order_date) AS 'month'
						 , CASE
							  WHEN sales.product_id = 1 THEN price*20
                              ELSE price*10
                              END AS 'points'
					  FROM sales
                      JOIN members
						ON sales.customer_id = members.customer_id
					  JOIN menu
						ON sales.product_id = menu.product_id
						WHERE
							sales.order_date >= members.join_date
						AND
							MONTH(order_date) = 1)
SELECT 
	customer_id
  , month
  , SUM(points) AS 'points'
FROM total_points
	GROUP BY customer_id
	ORDER BY customer_id;
        
-- Bonus Question : Join all the things

SELECT 
	sales.customer_id
  , order_date
  , product_name
  , price
  , CASE
		WHEN sales.order_date >= members.join_date THEN 'Y'
        ELSE 'N'
        END AS 'Member'
FROM sales
LEFT JOIN members
	ON sales.customer_id = members.customer_id
JOIN menu
	ON sales.product_id = menu.product_id;
    
-- Bonus Question : Rank all the things

WITH ranks AS ( SELECT 
					sales.customer_id
				  , order_date
				  , product_name
				  , price
				  , CASE
						WHEN sales.order_date >= members.join_date THEN 'Y'
						ELSE 'N'
						END AS 'Member'
				FROM sales
				LEFT JOIN members	
					ON sales.customer_id = members.customer_id
				JOIN menu
					ON sales.product_id = menu.product_id )
SELECT 
	*
  , CASE
		WHEN member = 'Y' 
			THEN DENSE_RANK() OVER(PARTITION BY customer_id, Member ORDER BY order_date)
		ELSE 'null'
		END AS 'ranking'
FROM ranks;
