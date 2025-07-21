-- Changing month_year to DATE type
ALTER TABLE interest_metrics
ALTER COLUMN month_year TYPE DATE
USING TO_DATE(month_year, 'MM-YY');