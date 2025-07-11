SET search_path = pizza_runner;

--customer_orders, pizza_names, pizza_recipes, pizza_toppings, runner_orders, runners


-- A. Pizza Metrics
-- 1. How many pizzas were ordered?

SELECT COUNT(*) AS pizzas_ordered
FROM customer_orders;

-- 2. How many unique customer orders were made?

SELECT COUNT(DISTINCT customer_id) AS unique_orders
FROM customer_orders;

-- 3. How many successful orders were delivered by each runner?

SELECT runner_id, COUNT(*) AS successful_orders
FROM runner_orders
WHERE cancellation ISNULL
GROUP BY runner_id
ORDER BY runner_id;

-- 4. How many of each type of pizza was delivered?

SELECT pizza_id, COUNT(*) AS pizza_type_count
FROM customer_orders
JOIN runner_orders
USING (order_id)
WHERE cancellation ISNULL
GROUP BY pizza_id
ORDER BY pizza_id;

-- 5. How many Vegetarian and Meatlovers were ordered by each customer?

SELECT customer_id, pizza_name, COUNT(pizza_name)
FROM customer_orders
JOIN runner_orders
USING (order_id)
JOIN pizza_names
USING (pizza_id)
GROUP BY customer_id, pizza_name
ORDER BY customer_id;

-- 6. What was the maximum number of pizzas delivered in a single order?

SELECT order_id, COUNT(pickup_time) AS pizza_orders
FROM runner_orders
JOIN customer_orders
USING (order_id)
WHERE pickup_time IS NOT NULL
GROUP BY pickup_time, order_id
ORDER BY pizza_orders DESC
LIMIT 1;

-- 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?

SELECT customer_id, COUNT(change) AS pizza_change
FROM (SELECT *,
CASE 
	WHEN exclusions IS NOT NULL OR extras IS NOT NULL THEN 'change'
	ELSE 'no change'
END AS change
FROM customer_orders)
WHERE change = 'change'
GROUP BY customer_id;

-- 8. How many pizzas were delivered that had both exclusions and extras?

SELECT SUM(pizza_change) AS pizza_both
FROM (SELECT customer_id, COUNT(change) AS pizza_change
FROM (SELECT *,
CASE 
	WHEN exclusions IS NOT NULL AND extras IS NOT NULL THEN 'both'
	ELSE 'no change'
END AS change
FROM customer_orders)
WHERE change = 'both'
GROUP BY customer_id);

-- 9. What was the total volume of pizzas ordered for each hour of the day?

SELECT COUNT(order_id) AS count_pizza, hour_of_day
FROM (SELECT order_id, EXTRACT(HOUR FROM order_time::TIMESTAMP) AS hour_of_day
FROM runner_orders
JOIN customer_orders
USING (order_id))
GROUP BY hour_of_day
ORDER BY hour_of_day ASC;

-- 10. What was the volume of orders for each day of the week?

SELECT day_name, day_of_week, COUNT(order_id) AS count_pizza
FROM (SELECT order_id, EXTRACT(DOW FROM order_time::TIMESTAMP) day_of_week, TO_CHAR(order_time::TIMESTAMP, 'FMDay') AS day_name
FROM runner_orders
JOIN customer_orders
USING (order_id))
GROUP BY day_of_week, day_name
ORDER BY day_of_week ASC;

-- B. Runner and Customer Experience
-- 1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)

SELECT week_number, COUNT(week_number) AS count_runners_signed
FROM (SELECT
       FLOOR((EXTRACT(DOY FROM registration_date) - 1) / 7) + 1 AS week_number
FROM runners)
GROUP BY week_number
ORDER BY week_number;

-- 2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?

SELECT runner_id, 
	ROUND(AVG(EXTRACT(EPOCH FROM (pickup_time::TIMESTAMP - order_time))/60),2) AS minute_to_hq
FROM customer_orders
LEFT JOIN runner_orders
USING (order_id)
WHERE pickup_time IS NOT NULL
GROUP BY runner_id
ORDER BY runner_id;

-- 3. Is there any relationship between the number of pizzas and how long the order takes to prepare?

WITH pizza_prep AS (
SELECT order_time, pickup_time, COUNT(order_id) AS count_pizza, ROUND(AVG(EXTRACT(EPOCH FROM (pickup_time::TIMESTAMP - order_time))/60),2) AS prep_time
FROM (SELECT DISTINCT *
FROM runner_orders
JOIN customer_orders
USING (order_id)
WHERE pickup_time IS NOT NULL)
GROUP BY order_time, pickup_time)

SELECT count_pizza, ROUND(AVG(prep_time), 2) AS avg_pre
FROM pizza_prep
GROUP BY count_pizza
ORDER BY count_pizza;

-- 4. What was the average distance travelled for each customer?

SELECT customer_id, CONCAT(ROUND(AVG(distance), 2), ' km') AS avg_distance
FROM customer_cte
GROUP BY customer_id
ORDER BY customer_id;

-- 5. What was the difference between the longest and shortest delivery times for all orders?

SELECT MAX(duration) - MIN(duration) AS delivery_time_diff
FROM runner_orders;

-- 6. What was the average speed for each runner for each delivery and do you notice any trend for these values?
--km/min(60min/hr)

SELECT runner_id, customer_id, CONCAT(ROUND(AVG(distance/duration) * 60, 2),' km/hr') AS avg_speed
FROM customer_cte
GROUP BY runner_id, customer_id
ORDER BY runner_id;

-- 7. What is the successful delivery percentage for each runner?

SELECT runner_id,
CONCAT(100*(COUNT(runner_id) - SUM(CASE
	WHEN duration IS NULL THEN 1
	ELSE 0
END))/COUNT(runner_id), '%') AS success_percentage
FROM customer_cte_null
GROUP BY runner_id
ORDER BY runner_id;

-- C. Ingredient Optimisation
-- 1. What are the standard ingredients for each pizza?

SELECT topping_name,
CASE
	WHEN veggie_toppings = meat_toppings THEN 'yes'
	ELSE 'no'
END AS standard_ingredient
FROM pizza_topping_names
WHERE veggie_toppings = meat_toppings;

-- 2. What was the most commonly added extra?

WITH count_extra AS (SELECT TRIM(UNNEST(STRING_TO_ARRAY(extras, ',')))::INTEGER AS extra_toppings
FROM customer_orders
WHERE extras IS NOT NULL)

SELECT topping_name, COUNT(extra_toppings) AS extra_topping_count
FROM count_extra
JOIN pizza_topping_names
ON extra_toppings = topping_id
GROUP BY topping_name
ORDER BY extra_topping_count DESC
LIMIT 1;

-- 3. What was the most common exclusion?

WITH count_exclusion AS (SELECT TRIM(UNNEST(STRING_TO_ARRAY(exclusions, ',')))::INTEGER AS excluded_toppings
FROM customer_orders
WHERE exclusions IS NOT NULL)

SELECT topping_name, COUNT(excluded_toppings) AS excluded_topping_count
FROM count_exclusion
JOIN pizza_topping_names
ON excluded_toppings = topping_id
GROUP BY topping_name
ORDER BY excluded_topping_count DESC
LIMIT 1;

-- 4. Generate an order item for each record in the customers_orders table in the format of one of the following:
--		Meat Lovers
--		Meat Lovers - Exclude Beef
--		Meat Lovers - Extra Bacon
--		Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers
--		Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
--		For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"
-- 5. What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?
-- veggie_order_count, meat_order_count, extra_toppings_count, exclusion_toppings_count


SELECT ptn.topping_id, 
	   ptn.topping_name, 
	   COALESCE(veggie_count, 0) AS veggie_count,
	   COALESCE(meat_count, 0) AS meat_count,
	   COALESCE(extra_topping_count, 0) AS extra_topping_count,
	   COALESCE(excluded_topping_count, 0) AS excluded_topping_count,
	   COALESCE(veggie_count, 0) + COALESCE(meat_count, 0) + COALESCE(extra_topping_count, 0) - COALESCE(excluded_topping_count, 0) AS total_ingredients_used
FROM pizza_topping_names ptn
FULL JOIN veggie_order_count
USING (topping_id)
FULL JOIN meat_order_count
USING (topping_id)
FULL JOIN extra_toppings_count
USING (topping_id)
FULL JOIN exclusion_toppings_count
USING (topping_id)
ORDER BY total_ingredients_used DESC;


-- D. Pricing and Ratings
-- 1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?
-- 2. What if there was an additional $1 charge for any pizza extras?
--		Add cheese is $1 extra
-- 3. The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, how would you design an additional table for this new dataset - generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.
-- 4. Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?
--		customer_id
--		order_id
--		runner_id
--		rating
--		order_time
--		pickup_time
--		Time between order and pickup
--		Delivery duration
--		Average speed
--		Total number of pizzas
-- 5. If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled - how much money does Pizza Runner have left over after these deliveries?

