# Case Study #6 - Clique Bait 🖱
Reference: [8 Week SQL Challenge - Clique Bait](https://8weeksqlchallenge.com/case-study-6/)
***
## Introduction
Clique Bait is not like your regular online seafood store - the founder and CEO Danny, was also a part of a digital data analytics team and wanted to expand his knowledge into the seafood industry!

In this case study - you are required to support Danny’s vision and analyse his dataset and come up with creative solutions to calculate funnel fallout rates for the Clique Bait online store.
***
## Available Data
For this case study there is a total of 5 datasets which you will need to combine to solve all of the questions.
***
## Case Study Questions
## A. Enterprise Relationship Diagram
Using the following DDL schema details to create an ERD for all the Clique Bait datasets.
[Click here](https://dbdiagram.io/home) to access the DB Diagram tool to create the ERD.

```sql

CREATE TABLE clique_bait.event_identifier (
  "event_type" INTEGER,
  "event_name" VARCHAR(13)
);

CREATE TABLE clique_bait.campaign_identifier (
  "campaign_id" INTEGER,
  "products" VARCHAR(3),
  "campaign_name" VARCHAR(33),
  "start_date" TIMESTAMP,
  "end_date" TIMESTAMP
);

CREATE TABLE clique_bait.page_hierarchy (
  "page_id" INTEGER,
  "page_name" VARCHAR(14),
  "product_category" VARCHAR(9),
  "product_id" INTEGER
);

CREATE TABLE clique_bait.users (
  "user_id" INTEGER,
  "cookie_id" VARCHAR(6),
  "start_date" TIMESTAMP
);

CREATE TABLE clique_bait.events (
  "visit_id" VARCHAR(6),
  "cookie_id" VARCHAR(6),
  "page_id" INTEGER,
  "event_type" INTEGER,
  "sequence_number" INTEGER,
  "event_time" TIMESTAMP
);

```
```dbml

TABLE event_identifier {
  event_type INTEGER
  event_name VARCHAR(33)
}

TABLE campaign_identifier {
  campaign_id INTEGER
  products VARCHAR(3)
  campaign_name VARCHAR(33)
  start_date TIMESTAMP
  end_date TIMESTAMP
}

TABLE page_hierarchy {
  page_id INTEGER
  page_name VARCHAR(14)
  product_category VARCHAR(9)
  product_id INTEGER
  }

TABLE users {
  user_id INTEGER
  cookie_id VARCHAR(6)
  start_date TIMESTAMP
}

TABLE events {
  "visit_id" VARCHAR(6)
  "cookie_id" VARCHAR(6)
  "page_id" INTEGER
  "event_type" INTEGER
  "sequence_number" INTEGER
  "event_time" TIMESTAMP
}



Ref: "users"."cookie_id" < "events"."cookie_id"

Ref:  "event_identifier"."event_type" < "events"."event_type"

Ref: "page_hierarchy"."page_id" < "events"."page_id"

Ref: "events"."event_time" < "campaign_identifier"."start_date"

Ref: "events"."event_time" < "campaign_identifier"."end_date"

```
[CliqueBaitERD](CliqueBaitERD.png)
***
## B. Digital Analysis
Using the available datasets - answer the following questions using a single query for each one:
#### 1. How many users are there?
```sql

SELECT COUNT(DISTINCT user_id) AS users_count
FROM users;

```
[Week-6-A-1](CliqueBaitOutput/Week-6-A-1.png)
***
#### 2. How many cookies does each user have on average?
```sql

WITH cookies AS (
SELECT user_id, 
	COUNT(cookie_id) AS cookies_count
FROM users
GROUP BY user_id
)
SELECT 
	ROUND(AVG(cookies_count)) AS avg_cookie
FROM cookies;

```
[Week-6-A-2](CliqueBaitOutput/Week-6-A-2.png)
***
#### 3. What is the unique number of visits by all users per month?
```sql

WITH visit_month AS (
SELECT *, 
	EXTRACT(MONTH FROM event_time) AS month
FROM events
)
SELECT month, COUNT(DISTINCT visit_id) AS visit_count
FROM visit_month
GROUP BY month;

```
[Week-6-A-3](CliqueBaitOutput/Week-6-A-3.png)
***
#### 4. What is the number of events for each event type?
```sql

SELECT event_type, 
	COUNT(event_type) AS event_count
FROM events
GROUP BY event_type;

```
[Week-6-A-4](CliqueBaitOutput/Week-6-A-4.png)
***
#### 5. What is the percentage of visits which have a purchase event?
```sql

SELECT
	100 * COUNT(DISTINCT visit_id)/(SELECT COUNT(DISTINCT visit_id) FROM events) AS purchase_perc
FROM events
JOIN event_identifier
USING (event_type)
WHERE event_name = 'Purchase';

```
[Week-6-A-5](CliqueBaitOutput/Week-6-A-5.png)
***
#### 6. What is the percentage of visits which view the checkout page but do not have a purchase event?
```sql

WITH view_no_purchase AS (
SELECT visit_id,
	MAX(CASE WHEN event_type = 1 AND page_id = 12 THEN 1 ELSE 0 END) AS checkout,
	MAX(CASE WHEN event_type = 3 THEN 1 ELSE 0 END) AS purchase
FROM events
GROUP BY visit_id
)
SELECT ROUND(100 * (1 - SUM(purchase)::NUMERIC/SUM(checkout)), 2) AS perc_no_purchase
FROM view_no_purchase;

```
[Week-6-A-6](CliqueBaitOutput/Week-6-A-6.png)
***
#### 7. What are the top 3 pages by number of views?
```sql

SELECT page_id, page_name, COUNT(*) AS view_per_page
FROM events
JOIN page_hierarchy
USING (page_id)
WHERE event_type = 1
GROUP BY page_id, page_name
ORDER BY view_per_page DESC
LIMIT 3;

```
[Week-6-A-7](CliqueBaitOutput/Week-6-A-7.png)
***
#### 8. What is the number of views and cart adds for each product category?
```sql

SELECT product_category,
	SUM(CASE WHEN event_name = 'Page View' THEN 1 ELSE 0 END) AS page_view,
	SUM(CASE WHEN event_name = 'Add to Cart' THEN 1 ELSE 0 END) AS add_to_cart
FROM events
JOIN event_identifier
USING (event_type)
JOIN page_hierarchy
USING (page_id)
WHERE product_category IS NOT NULL
GROUP BY product_category
ORDER BY page_view DESC;

```
[Week-6-A-8](CliqueBaitOutput/Week-6-A-8.png)
***
#### 9. What are the top 3 products by purchases?
```sql

WITH combined_tables AS (
SELECT *
FROM events
JOIN event_identifier
USING (event_type)
JOIN page_hierarchy
USING (page_id)
),
purchase_event AS (
SELECT DISTINCT visit_id
FROM combined_tables
WHERE event_name = 'Purchase'
)
SELECT page_name,
	SUM(CASE WHEN pe.visit_id IS NOT NULL THEN 1 ELSE 0 END) AS purchase_count
FROM combined_tables ct
LEFT JOIN purchase_event pe
USING (visit_id)
WHERE product_category IS NOT NULL
GROUP BY page_name
ORDER BY purchase_count DESC
LIMIT 3;

```
[Week-6-A-9](CliqueBaitOutput/Week-6-A-9.png)
***
## C. Product Funnel Analysis
#### 1. Using a single SQL query - create a new output table which has the following details:
- How many times was each product viewed?
- How many times was each product added to cart?
- How many times was each product added to a cart but not purchased (abandoned)?
- How many times was each product purchased?
```sql

DROP VIEW IF EXISTS product_name_info;
CREATE VIEW product_name_info AS
WITH page_cart_event AS (
SELECT *,
	CASE WHEN event_name = 'Page View' THEN 1 ELSE 0 END AS page_view,
	CASE WHEN event_name = 'Add to Cart' THEN 1 ELSE 0 END AS add_to_cart
FROM events
JOIN event_identifier
USING (event_type)
JOIN page_hierarchy
USING (page_id)
),
purchase_event AS (
SELECT DISTINCT visit_id
FROM page_cart_event
WHERE event_name = 'Purchase'
),
combined_events AS (
SELECT pce.visit_id, page_name, product_category, page_view, add_to_cart,
	CASE WHEN pe.visit_id IS NOT NULL THEN 1 ELSE 0 END AS purchase
FROM page_cart_event pce
LEFT JOIN purchase_event pe
USING (visit_id)
ORDER BY purchase ASC
)
SELECT page_name,
	SUM(page_view) AS total_page_view, 
	SUM(add_to_cart) AS total_add_Cart,
	SUM(CASE WHEN add_to_cart = 1 AND purchase = 0 THEN 1 ELSE 0 END) AS total_abandoned,
	SUM(CASE WHEN add_to_cart = 1 AND purchase = 1 THEN 1 ELSE 0 END) AS total_purchase
FROM combined_events
WHERE product_category IS NOT NULL
GROUP BY page_name
ORDER BY total_page_view DESC;

```
[Week-6-B-1-A](CliqueBaitOutput/Week-6-B-1-B.png)
***
#### Additionally, create another table which further aggregates the data for the above points but this time for each product category instead of individual products.
```sql

DROP VIEW IF EXISTS product_category_info;
CREATE VIEW product_category_info AS
WITH page_cart_event AS (
SELECT *,
	CASE WHEN event_name = 'Page View' THEN 1 ELSE 0 END AS page_view,
	CASE WHEN event_name = 'Add to Cart' THEN 1 ELSE 0 END AS add_to_cart
FROM events
JOIN event_identifier
USING (event_type)
JOIN page_hierarchy
USING (page_id)
),
purchase_event AS (
SELECT DISTINCT visit_id
FROM page_cart_event
WHERE event_name = 'Purchase'
),
combined_events AS (
SELECT pce.visit_id, page_name, product_category, page_view, add_to_cart,
	CASE WHEN pe.visit_id IS NOT NULL THEN 1 ELSE 0 END AS purchase
FROM page_cart_event pce
LEFT JOIN purchase_event pe
USING (visit_id)
ORDER BY purchase ASC
)
SELECT product_category,
	SUM(page_view) AS total_page_view, 
	SUM(add_to_cart) AS total_add_Cart,
	SUM(CASE WHEN add_to_cart = 1 AND purchase = 0 THEN 1 ELSE 0 END) AS total_abandoned,
	SUM(CASE WHEN add_to_cart = 1 AND purchase = 1 THEN 1 ELSE 0 END) AS total_purchase
FROM combined_events
WHERE product_category IS NOT NULL
GROUP BY product_category
ORDER BY total_page_view DESC;

```
[Week-6-A-1](CliqueBaitOutput/Week-6-A-1.png)
***
#### Use your 2 new output tables - answer the following questions:
#### 2. Which product had the most views, cart adds and purchases?
```sql

SELECT total_page_view,
	CASE WHEN total_page_view = MAX(total_page_view) OVER() THEN page_name ELSE NULL END AS most_views,
	total_add_cart,
	CASE WHEN total_add_cart = MAX(total_add_cart) OVER() THEN page_name ELSE NULL END AS most_add_carts,
	total_purchase,
	CASE WHEN total_purchase = MAX(total_purchase) OVER() THEN page_name ELSE NULL END AS most_purchase
FROM product_name_info
GROUP BY page_name, total_page_view, total_add_cart, total_purchase;

```
[Week-6-B-2](CliqueBaitOutput/Week-6-B-2.png)
***
#### 3. Which product was most likely to be abandoned?
```sql

SELECT total_abandoned,
	CASE WHEN total_abandoned = MAX(total_abandoned) OVER() THEN page_name ELSE NULL END AS most_abandoned
FROM product_name_info
ORDER BY most_abandoned;

```
[Week-6-B-3](CliqueBaitOutput/Week-6-B-3.png)
***
#### 4. Which product had the highest view to purchase percentage?
```sql

SELECT page_name, 
	ROUND(100.00 * total_purchase / total_page_view, 2) AS view_to_purchase_perc
FROM product_name_info
ORDER BY view_to_purchase_perc DESC;

```
[Week-6-B-4](CliqueBaitOutput/Week-6-B-4.png)
***
#### 5. What is the average conversion rate from view to cart add?
```sql

SELECT 
	ROUND(AVG((100.00 * total_add_cart / total_page_view)), 2) AS avg_conversion_view_to_cart
FROM product_name_info;

```
[Week-6-B-5](CliqueBaitOutput/Week-6-B-5.png)
***
#### 6. What is the average conversion rate from cart add to purchase?
```sql

SELECT 
	ROUND(AVG((100.00 * total_purchase / total_add_cart)), 2) AS avg_conversion_cart_to_purchase
FROM product_name_info;

```
[Week-6-B-6](CliqueBaitOutput/Week-6-B-6.png)
***
## C. Campaigns Analysis
#### Generate a table that has 1 single row for every unique visit_id record and has the following columns:
- user_id
- visit_id
- visit_start_time: the earliest event_time for each visit
- page_views: count of page views for each visit
- cart_adds: count of product cart add events for each visit
- purchase: 1/0 flag if a purchase event exists for each visit
- campaign_name: map the visit to a campaign if the visit_start_time falls between the start_date and end_date
- impression: count of ad impressions for each visit
- click: count of ad clicks for each visit
- (Optional column) cart_products: a comma separated text value with products added to the cart sorted by the order they were added to the cart (hint: use the sequence_number)
```sql

SELECT user_id, 
	   visit_id,
	   MIN(event_time) AS visit_start_time,
	   SUM(CASE WHEN event_name = 'Page View' THEN 1 ELSE 0 END) AS page_views,
	   SUM(CASE WHEN event_name = 'Add to Cart' THEN 1 ELSE 0 END) AS cart_views,
	   SUM(CASE WHEN event_name = 'Purchase' THEN 1 ELSE 0 END) AS purchase,
	   campaign_name,
	   SUM(CASE WHEN event_name = 'Ad Impression' THEN 1 ELSE 0 END) AS impression,
	   SUM(CASE WHEN event_name = 'Ad Click' THEN 1 ELSE 0 END) AS click,
	   STRING_AGG(CASE WHEN product_id IS NOT NULL AND event_name = 'Add to Cart' THEN page_name ELSE NULL END, ', ' ORDER BY sequence_number) AS cart_products
FROM users
JOIN events
USING (cookie_id)
LEFT JOIN campaign_identifier c
ON event_time BETWEEN c.start_date AND c.end_date
LEFT JOIN page_hierarchy
USING (page_id)
JOIN event_identifier
USING (event_type)
GROUP BY user_id, visit_id, campaign_name

```
[Week-6-C](CliqueBaitOutput/Week-6-C.png)
***
