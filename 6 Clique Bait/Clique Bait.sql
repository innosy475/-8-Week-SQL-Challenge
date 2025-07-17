SET search_path = clique_bait;

--users, events, page_hierarchy, campaign_identifier, event_identitfier

-- A. Digital Analysis
-- Using the available datasets - answer the following questions using a single query for each one:
-- 1. How many users are there?

SELECT COUNT(DISTINCT user_id) AS users_count
FROM users;

-- 2. How many cookies does each user have on average?

WITH cookies AS (
SELECT user_id, 
	COUNT(cookie_id) AS cookies_count
FROM users
GROUP BY user_id
)
SELECT 
	ROUND(AVG(cookies_count)) AS avg_cookie
FROM cookies;

-- 3. What is the unique number of visits by all users per month?

WITH visit_month AS (
SELECT *, 
	EXTRACT(MONTH FROM event_time) AS month
FROM events
)
SELECT month, COUNT(DISTINCT visit_id) AS visit_count
FROM visit_month
GROUP BY month;

-- 4. What is the number of events for each event type?

SELECT event_type, 
	COUNT(event_type) AS event_count
FROM events
GROUP BY event_type;

-- 5. What is the percentage of visits which have a purchase event?

SELECT
	100 * COUNT(DISTINCT visit_id)/(SELECT COUNT(DISTINCT visit_id) FROM events) AS purchase_perc
FROM events
JOIN event_identifier
USING (event_type)
WHERE event_name = 'Purchase';

-- 6. What is the percentage of visits which view the checkout page but do not have a purchase event?

WITH view_no_purchase AS (
SELECT visit_id,
	MAX(CASE WHEN event_type = 1 AND page_id = 12 THEN 1 ELSE 0 END) AS checkout,
	MAX(CASE WHEN event_type = 3 THEN 1 ELSE 0 END) AS purchase
FROM events
GROUP BY visit_id
)
SELECT ROUND(100 * (1 - SUM(purchase)::NUMERIC/SUM(checkout)), 2) AS perc_no_purchase
FROM view_no_purchase;

-- 7. What are the top 3 pages by number of views?

SELECT page_id, page_name, COUNT(*) AS view_per_page
FROM events
JOIN page_hierarchy
USING (page_id)
WHERE event_type = 1
GROUP BY page_id, page_name
ORDER BY view_per_page DESC
LIMIT 3;

-- 8. What is the number of views and cart adds for each product category?

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


-- 9. What are the top 3 products by purchases?

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

-- B. Product Funnel Analysis
-- 1. Using a single SQL query - create a new output table which has the following details:
-- How many times was each product viewed?
-- How many times was each product added to cart?
-- How many times was each product added to a cart but not purchased (abandoned)?
-- How many times was each product purchased?

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

-- Additionally, create another table which further aggregates the data for the above points but this time for each product category instead of individual products.

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

-- Use your 2 new output tables - answer the following questions:

-- 2. Which product had the most views, cart adds and purchases?

SELECT total_page_view,
	CASE WHEN total_page_view = MAX(total_page_view) OVER() THEN page_name ELSE NULL END AS most_views,
	total_add_cart,
	CASE WHEN total_add_cart = MAX(total_add_cart) OVER() THEN page_name ELSE NULL END AS most_add_carts,
	total_purchase,
	CASE WHEN total_purchase = MAX(total_purchase) OVER() THEN page_name ELSE NULL END AS most_purchase
FROM product_name_info
GROUP BY page_name, total_page_view, total_add_cart, total_purchase;

-- 3. Which product was most likely to be abandoned?

SELECT total_abandoned,
	CASE WHEN total_abandoned = MAX(total_abandoned) OVER() THEN page_name ELSE NULL END AS most_abandoned
FROM product_name_info
ORDER BY most_abandoned;

-- 4. Which product had the highest view to purchase percentage?

SELECT page_name, 
	ROUND(100.00 * total_purchase / total_page_view, 2) AS view_to_purchase_perc
FROM product_name_info
ORDER BY view_to_purchase_perc DESC; 

-- 5. What is the average conversion rate from view to cart add?

SELECT 
	ROUND(AVG((100.00 * total_add_cart / total_page_view)), 2) AS avg_conversion_view_to_cart
FROM product_name_info;

-- 6. What is the average conversion rate from cart add to purchase?

SELECT 
	ROUND(AVG((100.00 * total_purchase / total_add_cart)), 2) AS avg_conversion_cart_to_purchase
FROM product_name_info;

-- C. Generate a table that has 1 single row for every unique visit_id record and has the following columns:

-- user_id
-- visit_id
-- visit_start_time: the earliest event_time for each visit
-- page_views: count of page views for each visit
-- cart_adds: count of product cart add events for each visit
-- purchase: 1/0 flag if a purchase event exists for each visit
-- campaign_name: map the visit to a campaign if the visit_start_time falls between the start_date and end_date
-- impression: count of ad impressions for each visit
-- click: count of ad clicks for each visit
-- (Optional column) cart_products: a comma separated text value with products added to the cart sorted by the order they were added to the cart (hint: use the sequence_number)

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
