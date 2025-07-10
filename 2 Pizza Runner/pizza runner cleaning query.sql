
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

-- Cleaning customer_orders table

UPDATE customer_orders
SET
	exclusions = CASE WHEN exclusions = '' OR exclusions = 'null' THEN NULL ELSE exclusions END,
	extras = CASE WHEN extras = '' OR extras = 'null' THEN NULL ELSE extras END;
