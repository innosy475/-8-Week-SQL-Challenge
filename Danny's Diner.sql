SET search_path = dannys_diner;

SELECT *
FROM menu;

-- sales, menu, members

-- 1. What is the total amount each customer spent at the restaurant?

SELECT s.customer_id, SUM(m.price) AS total_spent
FROM menu m
JOIN sales s
USING (product_id)
GROUP BY s.customer_id
ORDER BY SUM(m.price) DESC;

-- 2. How many days has each customer visited the restaurant?

SELECT customer_id, COUNT(DISTINCT order_date) AS num_days_visited
FROM sales
GROUP BY customer_id;

-- 3. What was the first item from the menu purchased by each customer?

SELECT DISTINCT sales.customer_id, product_name, order_date
FROM sales
JOIN menu
USING (product_id)
JOIN (SELECT customer_id, MIN(order_date) AS first_date
	  FROM sales
	  GROUP BY customer_id) AS fd
ON sales.customer_id = fd.customer_id
AND sales.order_date = fd.first_date
ORDER BY customer_id;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT product_name, COUNT(product_name) AS most_sold_product
FROM menu
JOIN sales
USING (product_id)
GROUP BY product_name
LIMIT 1;

-- 5. Which item was the most popular for each customer?

SELECT customer_id, product_name, sold_count, product_rank
FROM (SELECT customer_id, product_name, COUNT(product_name) AS sold_count,
	RANK() OVER (PARTITION BY customer_id 
	ORDER BY COUNT(*) DESC) AS product_rank
	FROM menu
	JOIN sales
	USING (product_id)
	GROUP BY customer_id, product_name
	ORDER BY customer_id, sold_count DESC
)
WHERE product_rank = 1;

-- 6. Which item was purchased first by the customer after they became a member?
SELECT customer_id, product_name
FROM (SELECT customer_id, product_name, join_date, order_date, 
		RANK() OVER(PARTITION BY customer_id 
					ORDER BY order_date - join_date
					) AS first_purchase
FROM members
JOIN sales
USING (customer_id)
JOIN menu
USING (product_id)
WHERE join_date < order_date)
WHERE first_purchase = 1;

-- 7. Which item was purchased just before the customer became a member?
SELECT customer_id, product_name, order_date, join_date
FROM (SELECT customer_id, product_name, order_date, join_date, 
		RANK() OVER(PARTITION BY customer_id 
					ORDER BY order_date - join_date
					) AS purchased_before
FROM members
JOIN sales
USING (customer_id)
JOIN menu
USING (product_id)
WHERE order_date < join_date
ORDER BY customer_id, order_date)
WHERE purchased_before = 1;
-- 8. What is the total items and amount spent for each member before they became a member?

SELECT customer_id, SUM(order_count), CONCAT('$ ', SUM(amount_spent)) AS total_amount_spentt
FROM (SELECT sales.customer_id, product_name, COUNT(product_name) AS order_count, price * COUNT(product_name) AS amount_spent
		FROM members
		JOIN sales
		USING (customer_id)
		JOIN menu
		USING (product_id)
		WHERE order_date < join_date
		GROUP BY sales.customer_id, product_name, price
		ORDER BY customer_id)
GROUP BY customer_id;

-- 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

SELECT customer_id, SUM(points)
FROM (SELECT product_name, customer_id,
CASE 
	WHEN product_name = 'sushi' THEN 2 * price * 10
	ELSE price * 10
END AS points
FROM menu
JOIN sales
USING (product_id))
GROUP BY customer_id
ORDER BY customer_id;

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

SELECT customer_id, SUM(points)
FROM (SELECT customer_id, count_days, product_name,
CASE
	WHEN count_days BETWEEN 0 AND 8 THEN 2 * price * 10
	WHEN product_name = 'sushi' AND count_days < 0 AND count_days > 8 THEN 2 * price * 10
	ELSE 10 * price
END AS points
FROM (SELECT customer_id, product_name, price, join_date, order_date, order_date - join_date AS count_days
FROM members
JOIN sales
USING (customer_id)
JOIN menu
USING (product_id)
WHERE order_date < '2021-02-01'))
GROUP BY customer_id;

-- Join All The Things
-- The following questions are related creating basic data tables that Danny and his team can use to quickly derive insights without needing to join the underlying tables using SQL.

SELECT sales.customer_id,	order_date,	product_name,	price,
CASE
	WHEN order_date < join_date THEN 'N'
	WHEN order_date >= join_date THEN 'Y'
	ELSE 'N'
END AS member
FROM sales
LEFT JOIN members
USING (customer_id)
JOIN menu
USING (product_id);

-- Rank All The Things
-- Danny also requires further information about the ranking of customer products, but he purposely does not need the ranking for non-member purchases so he expects null ranking values for the records when customers are not yet part of the loyalty program.

SELECT customer_id, order_date, member,
CASE
	WHEN member = 'N' THEN NULL
	WHEN member = 'Y' THEN RANK() OVER(PARTITION BY customer_id, member ORDER BY order_date ASC)
END as ranking
FROM (SELECT sales.customer_id,	order_date,	product_name,	price,
CASE
	WHEN order_date < join_date THEN 'N'
	WHEN order_date >= join_date THEN 'Y'
	ELSE 'N'
END AS member
FROM sales
LEFT JOIN members
USING (customer_id)
JOIN menu
USING (product_id));