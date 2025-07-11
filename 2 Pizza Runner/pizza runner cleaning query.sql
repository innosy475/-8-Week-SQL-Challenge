
-- Cleaning runner_orders table

UPDATE runner_orders
SET 
	pickup_time = CASE WHEN pickup_time = 'null' THEN NULL ELSE pickup_time END,
	distance = CASE WHEN distance = 'null' THEN NULL ELSE distance END,
	duration = CASE WHEN duration = 'null' THEN NULL ELSE duration END,
	cancellation = CASE WHEN cancellation = 'null' OR cancellation = '' THEN NULL ELSE cancellation END;

UPDATE runner_orders
SET 
	distance = TRIM('km' FROM distance),
	duration = TRIM('minutes' FROM duration);

ALTER TABLE runner_orders
ALTER COLUMN distance TYPE FLOAT
USING distance::FLOAT;

ALTER TABLE runner_orders
ALTER COLUMN duration TYPE INTEGER
USING duration::INTEGER;

ALTER TABLE runner_orders
ALTER COLUMN distance TYPE NUMERIC;

-- Cleaning customer_orders table

UPDATE customer_orders
SET
	exclusions = CASE WHEN exclusions = '' OR exclusions = 'null' THEN NULL ELSE exclusions END,
	extras = CASE WHEN extras = '' OR extras = 'null' THEN NULL ELSE extras END;

-- Cleaning pizza_toppings and pizza_recipes tables

DROP VIEW IF EXISTS veggie_pizza_toppings;
CREATE VIEW veggie_pizza_toppings AS
SELECT 1 AS v_pizza_id, TRIM(UNNEST(STRING_TO_ARRAY(toppings, ',')))::INTEGER AS veggie_toppings
FROM pizza_recipes
WHERE pizza_id = 1;

DROP VIEW IF EXISTS meat_pizza_toppings;
CREATE VIEW meat_pizza_toppings AS
SELECT 2 AS m_pizza_id, TRIM(UNNEST(STRING_TO_ARRAY(toppings, ',')))::INTEGER AS meat_toppings
FROM pizza_recipes
WHERE pizza_id = 2;

DROP VIEW IF EXISTS pizza_topping_names;
CREATE VIEW pizza_topping_names AS
SELECT v_pizza_id
FROM veggie_pizza_toppings
INNER JOIN pizza_toppings
ON v_pizza_id = topping_id
INNER JOIN meat_pizza_toppings
ON m_pizza_id = topping_id

-- customer_cte
DROP VIEW IF EXISTS customer_cte;
CREATE VIEW customer_cte AS
SELECT DISTINCT *
FROM runner_orders
INNER JOIN customer_orders
USING (order_id)
WHERE pickup_time IS NOT NULL;

--customer_cte_null
DROP VIEW IF EXISTS customer_cte_null;
CREATE VIEW customer_cte_null AS
SELECT DISTINCT *
FROM runner_orders
INNER JOIN customer_orders
USING (order_id);

-- pizza_topping_names
DROP VIEW IF EXISTS pizza_topping_names;
CREATE VIEW pizza_topping_names AS
SELECT *
FROM pizza_toppings
FULL JOIN veggie_pizza_toppings
ON veggie_toppings = topping_id
FULL JOIN meat_pizza_toppings
ON meat_toppings = topping_id;


--veggie pizza order count
DROP VIEW IF EXISTS veggie_order_count;
CREATE VIEW veggie_order_count AS
SELECT topping_id, pizza_id, topping_name, COUNT(*) AS veggie_count
FROM pizza_topping_names
JOIN customer_cte
ON pizza_id = v_pizza_id
WHERE v_pizza_id IS NOT NULL
GROUP BY topping_name, pizza_id, topping_id;
--meat pizza order count
DROP VIEW IF EXISTS meat_order_count;
CREATE VIEW meat_order_count AS
SELECT topping_id, pizza_id, topping_name, COUNT(*) AS meat_count
FROM pizza_topping_names
JOIN customer_cte
ON pizza_id = m_pizza_id
WHERE m_pizza_id IS NOT NULL
GROUP BY topping_name, pizza_id, topping_id;
--extra toppings count
DROP VIEW IF EXISTS extra_toppings_count;
CREATE VIEW extra_toppings_count AS
WITH count_extra AS (SELECT TRIM(UNNEST(STRING_TO_ARRAY(extras, ',')))::INTEGER AS extra_toppings
FROM customer_orders
WHERE extras IS NOT NULL)

SELECT topping_id, topping_name, COUNT(extra_toppings) AS extra_topping_count
FROM count_extra
JOIN pizza_topping_names
ON extra_toppings = topping_id
GROUP BY topping_name, topping_id
ORDER BY extra_topping_count DESC;
--exclusions count
DROP VIEW IF EXISTS exclusion_toppings_count;
CREATE VIEW exclusion_toppings_count AS
WITH count_exclusion AS (SELECT TRIM(UNNEST(STRING_TO_ARRAY(exclusions, ',')))::INTEGER AS excluded_toppings
FROM customer_orders
WHERE exclusions IS NOT NULL)

SELECT topping_id, topping_name, COUNT(excluded_toppings) AS excluded_topping_count
FROM count_exclusion
JOIN pizza_topping_names
ON excluded_toppings = topping_id
GROUP BY topping_name, topping_id
ORDER BY excluded_topping_count DESC;

