SET search_path = data_bank;

--regions, customer_nodes, customer_transactions

-- A. Customer Nodes Exploration
-- 1. How many unique nodes are there on the Data Bank system?

SELECT COUNT(DISTINCT node_id) AS unique_nodes
FROM customer_nodes;

-- 2. What is the number of nodes per region?
DROP VIEW IF EXISTS customer_regions;
CREATE VIEW customer_regions AS
SELECT *
FROM customer_nodes
JOIN regions
USING (region_id);

SELECT region_name, 
	COUNT(node_id) AS node_count
FROM customer_regions
GROUP BY region_name;

-- 3. How many customers are allocated to each region?

SELECT region_name, 
	COUNT(DISTINCT customer_id)
FROM customer_regions
GROUP BY region_name;

-- 4. How many days on average are customers reallocated to a different node?

WITH node_days AS (
SELECT customer_id, 
	start_date,
	LEAD(start_date) OVER(PARTITION BY customer_id ORDER BY node_id) AS next_date,
	node_id, 
	LEAD(node_id) OVER(PARTITION BY customer_id ORDER BY node_id) AS next_node
FROM customer_regions
ORDER BY customer_id, node_id, start_date, next_date
),
reallocate_days AS (
SELECT *, 
	ABS(next_date - start_date) AS days_to_reallocate
FROM node_days
WHERE next_node = node_id + 1
)
SELECT ROUND(AVG(days_to_reallocate), 2) AS avg_days
FROM reallocate_days;

-- 5. What is the median, 80th and 95th percentile for this same reallocation days metric for each region?

WITH node_days AS (
SELECT customer_id, 
	start_date,
	LEAD(start_date) OVER(PARTITION BY customer_id ORDER BY node_id) AS next_date,
	node_id, 
	LEAD(node_id) OVER(PARTITION BY customer_id ORDER BY node_id) AS next_node
FROM customer_regions
ORDER BY customer_id, node_id, start_date, next_date
),
reallocate_days AS (
SELECT *, 
	ABS(next_date - start_date) AS days_to_reallocate
FROM node_days
WHERE next_node = node_id + 1
)
SELECT
	percentile_cont(0.5) WITHIN GROUP (ORDER BY days_to_reallocate) AS median,
	percentile_cont(0.8) WITHIN GROUP (ORDER BY days_to_reallocate) AS "80th_percentile",
	percentile_cont(0.95) WITHIN GROUP (ORDER BY days_to_reallocate) AS "95th_percentile"
FROM reallocate_days;

-- B. Customer Transactions
-- 1. What is the unique count and total amount for each transaction type?

SELECT txn_type::TEXT, 
	COUNT(customer_id) AS txn_count, 
	SUM(txn_amount) AS total_txn
FROM customer_transactions
GROUP BY txn_type;

-- 2. What is the average total historical deposit counts and amounts for all customers?

WITH deposit_txn AS (
SELECT
	COUNT(customer_id) AS txn_count,
	AVG(txn_amount) AS avg_deposit
FROM customer_transactions
WHERE txn_type = 'deposit'
GROUP BY customer_id
)
SELECT
	ROUND(AVG(txn_count), 2) AS avg_deposit_count,
	ROUND(AVG(avg_deposit), 2) AS avg_deposit
FROM deposit_txn;

-- 3. For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?

WITH monthly_txn AS (
SELECT customer_id, 
	EXTRACT(MONTH FROM txn_date) AS txn_month,
	SUM(CASE WHEN txn_type = 'deposit' THEN 0 ELSE 1 END) AS count_deposit,
	SUM(CASE WHEN txn_type = 'purhcase' THEN 0 ELSE 1 END) AS count_purchase,
	SUM(CASE WHEN txn_type = 'withdrawal' THEN 1 ELSE 0 END) AS count_withdraw
FROM customer_transactions
GROUP BY customer_id, EXTRACT(MONTH FROM txn_date)
)
SELECT txn_month, 
	COUNT(DISTINCT customer_id) AS count_customer
FROM monthly_txn
WHERE count_deposit > 1
	AND (count_purchase >= 1 OR count_withdraw >= 1)
GROUP BY txn_month
ORDER BY txn_month;

