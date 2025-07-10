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
-- 2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
-- 3. Is there any relationship between the number of pizzas and how long the order takes to prepare?
-- 4. What was the average distance travelled for each customer?
-- 5. What was the difference between the longest and shortest delivery times for all orders?
-- 6. What was the average speed for each runner for each delivery and do you notice any trend for these values?
-- 7. What is the successful delivery percentage for each runner?

-- C. Ingredient Optimisation
-- 1. What are the standard ingredients for each pizza?
-- 2. What was the most commonly added extra?
-- 3. What was the most common exclusion?
-- 4. Generate an order item for each record in the customers_orders table in the format of one of the following:
--		Meat Lovers
--		Meat Lovers - Exclude Beef
--		Meat Lovers - Extra Bacon
--		Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers
--		Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
--		For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"
-- 5. What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?


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

