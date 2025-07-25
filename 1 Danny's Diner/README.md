# Case Study #1 - Danny's Diner 🍽
Reference: [8 Week SQL Challenge - Danny's Diner](https://8weeksqlchallenge.com/case-study-1/)
***
## Introduction
Danny seriously loves Japanese food so in the beginning of 2021, he decides to embark upon a risky venture and opens up a cute little restaurant that sells his 3 favourite foods: sushi, curry and ramen.

Danny’s Diner is in need of your assistance to help the restaurant stay afloat - the restaurant has captured some very basic data from their few months of operation but have no idea how to use their data to help them run the business.
***
## Problem Statement
Danny wants to use the data to answer a few simple questions about his customers, especially about their visiting patterns, how much money they’ve spent and also which menu items are their favourite. Having this deeper connection with his customers will help him deliver a better and more personalised experience for his loyal customers.

He plans on using these insights to help him decide whether he should expand the existing customer loyalty program - additionally he needs help to generate some basic datasets so his team can easily inspect the data without needing to use SQL.

Danny has provided you with a sample of his overall customer data due to privacy issues - but he hopes that these examples are enough for you to write fully functioning SQL queries to help him answer his questions!

Danny has shared with you 3 key datasets for this case study:

- sales
- menu
- members

You can inspect the entity relationship diagram and example data below.

### Entity Relationship Diagram
![Danny Diner ERD](Danny_Diner_ERD.png)
***

## Case Study Questions
#### 1. What is the total amount each customer spent at the restaurant?
```sql

SELECT s.customer_id, SUM(m.price) AS total_spent
FROM menu m
JOIN sales s
USING (product_id)
GROUP BY s.customer_id
ORDER BY SUM(m.price) DESC;

```
![Week-1-A-1](Danny's%20Diner%20Output/Week-1-A-1.png)
***
#### 2. How many days has each customer visited the restaurant?
```sql

SELECT customer_id, COUNT(DISTINCT order_date) AS num_days_visited
FROM sales
GROUP BY customer_id;

```
![Week-1-A-2](Danny's%20Diner%20Output/Week-1-A-2.png)
***
#### 3. What was the first item from the menu purchased by each customer?
```sql

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

```
![Week-1-A-3](Danny's%20Diner%20Output/Week-1-A-3.png)
***
#### 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
```sql

SELECT product_name, COUNT(product_name) AS most_sold_product
FROM menu
JOIN sales
USING (product_id)
GROUP BY product_name
LIMIT 1;

```
![Week-1-A-4](Danny's%20Diner%20Output/Week-1-A-4.png)
***
#### 5. Which item was the most popular for each customer?
```sql

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

```
![Week-1-A-5](Danny's%20Diner%20Output/Week-1-A-5.png)
***
#### 6. Which item was purchased first by the customer after they became a member?
```sql

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

```
![Week-1-A-6](Danny's%20Diner%20Output/Week-1-A-6.png)
***
#### 7. Which item was purchased just before the customer became a member?
```sql

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

```
![Week-1-A-7](Danny's%20Diner%20Output/Week-1-A-7.png)
***
#### 8. What is the total items and amount spent for each member before they became a member?
```sql

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

```
![Week-1-A-8](Danny's%20Diner%20Output/Week-1-A-8.png)
***
#### 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
```sql

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

```
![Week-1-A-9](Danny's%20Diner%20Output/Week-1-A-9.png)
***
#### 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
```sql

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

```
![Week-1-A-10](Danny's%20Diner%20Output/Week-1-A-10.png)
***
## Bonus Questions
### Join All The Things
#### The following questions are related creating basic data tables that Danny and his team can use to quickly derive insights without needing to join the underlying tables using SQL.
#### Recreate the following table output using the available data:

<div class="responsive-table">

  <table>
    <thead>
      <tr>
        <th>customer_id</th>
        <th>order_date</th>
        <th>product_name</th>
        <th>price</th>
        <th>member</th>
      </tr>
    </thead>
    <tbody>
      <tr>
        <td>A</td>
        <td>2021-01-01</td>
        <td>curry</td>
        <td>15</td>
        <td>N</td>
      </tr>
      <tr>
        <td>A</td>
        <td>2021-01-01</td>
        <td>sushi</td>
        <td>10</td>
        <td>N</td>
      </tr>
      <tr>
        <td>A</td>
        <td>2021-01-07</td>
        <td>curry</td>
        <td>15</td>
        <td>Y</td>
      </tr>
      <tr>
        <td>A</td>
        <td>2021-01-10</td>
        <td>ramen</td>
        <td>12</td>
        <td>Y</td>
      </tr>
      <tr>
        <td>A</td>
        <td>2021-01-11</td>
        <td>ramen</td>
        <td>12</td>
        <td>Y</td>
      </tr>
      <tr>
        <td>A</td>
        <td>2021-01-11</td>
        <td>ramen</td>
        <td>12</td>
        <td>Y</td>
      </tr>
      <tr>
        <td>B</td>
        <td>2021-01-01</td>
        <td>curry</td>
        <td>15</td>
        <td>N</td>
      </tr>
      <tr>
        <td>B</td>
        <td>2021-01-02</td>
        <td>curry</td>
        <td>15</td>
        <td>N</td>
      </tr>
      <tr>
        <td>B</td>
        <td>2021-01-04</td>
        <td>sushi</td>
        <td>10</td>
        <td>N</td>
      </tr>
      <tr>
        <td>B</td>
        <td>2021-01-11</td>
        <td>sushi</td>
        <td>10</td>
        <td>Y</td>
      </tr>
      <tr>
        <td>B</td>
        <td>2021-01-16</td>
        <td>ramen</td>
        <td>12</td>
        <td>Y</td>
      </tr>
      <tr>
        <td>B</td>
        <td>2021-02-01</td>
        <td>ramen</td>
        <td>12</td>
        <td>Y</td>
      </tr>
      <tr>
        <td>C</td>
        <td>2021-01-01</td>
        <td>ramen</td>
        <td>12</td>
        <td>N</td>
      </tr>
      <tr>
        <td>C</td>
        <td>2021-01-01</td>
        <td>ramen</td>
        <td>12</td>
        <td>N</td>
      </tr>
      <tr>
        <td>C</td>
        <td>2021-01-07</td>
        <td>ramen</td>
        <td>12</td>
        <td>N</td>
      </tr>
    </tbody>
  </table>

</div>

```sql

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
    
```
![Week-1-Join](Danny's%20Diner%20Output/Week-1-Join.png)
***
### Rank All The Things
#### Danny also requires further information about the ranking of customer products, but he purposely does not need the ranking for non-member purchases so he expects null ranking values for the records when customers are not yet part of the loyalty program.

<div class="responsive-table">

  <table>
    <thead>
      <tr>
        <th>customer_id</th>
        <th>order_date</th>
        <th>product_name</th>
        <th>price</th>
        <th>member</th>
        <th>ranking</th>
      </tr>
    </thead>
    <tbody>
      <tr>
        <td>A</td>
        <td>2021-01-01</td>
        <td>curry</td>
        <td>15</td>
        <td>N</td>
        <td>null</td>
      </tr>
      <tr>
        <td>A</td>
        <td>2021-01-01</td>
        <td>sushi</td>
        <td>10</td>
        <td>N</td>
        <td>null</td>
      </tr>
      <tr>
        <td>A</td>
        <td>2021-01-07</td>
        <td>curry</td>
        <td>15</td>
        <td>Y</td>
        <td>1</td>
      </tr>
      <tr>
        <td>A</td>
        <td>2021-01-10</td>
        <td>ramen</td>
        <td>12</td>
        <td>Y</td>
        <td>2</td>
      </tr>
      <tr>
        <td>A</td>
        <td>2021-01-11</td>
        <td>ramen</td>
        <td>12</td>
        <td>Y</td>
        <td>3</td>
      </tr>
      <tr>
        <td>A</td>
        <td>2021-01-11</td>
        <td>ramen</td>
        <td>12</td>
        <td>Y</td>
        <td>3</td>
      </tr>
      <tr>
        <td>B</td>
        <td>2021-01-01</td>
        <td>curry</td>
        <td>15</td>
        <td>N</td>
        <td>null</td>
      </tr>
      <tr>
        <td>B</td>
        <td>2021-01-02</td>
        <td>curry</td>
        <td>15</td>
        <td>N</td>
        <td>null</td>
      </tr>
      <tr>
        <td>B</td>
        <td>2021-01-04</td>
        <td>sushi</td>
        <td>10</td>
        <td>N</td>
        <td>null</td>
      </tr>
      <tr>
        <td>B</td>
        <td>2021-01-11</td>
        <td>sushi</td>
        <td>10</td>
        <td>Y</td>
        <td>1</td>
      </tr>
      <tr>
        <td>B</td>
        <td>2021-01-16</td>
        <td>ramen</td>
        <td>12</td>
        <td>Y</td>
        <td>2</td>
      </tr>
      <tr>
        <td>B</td>
        <td>2021-02-01</td>
        <td>ramen</td>
        <td>12</td>
        <td>Y</td>
        <td>3</td>
      </tr>
      <tr>
        <td>C</td>
        <td>2021-01-01</td>
        <td>ramen</td>
        <td>12</td>
        <td>N</td>
        <td>null</td>
      </tr>
      <tr>
        <td>C</td>
        <td>2021-01-01</td>
        <td>ramen</td>
        <td>12</td>
        <td>N</td>
        <td>null</td>
      </tr>
      <tr>
        <td>C</td>
        <td>2021-01-07</td>
        <td>ramen</td>
        <td>12</td>
        <td>N</td>
        <td>null</td>
      </tr>
    </tbody>
  </table>

</div>

```sql

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
USING (product_id))

```
![Week-1-Rank](Danny's%20Diner%20Output/Week-1-Rank.png)
