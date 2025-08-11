-- sql/01_create_calendar_from_numbers.sql

-- Error handling: Check if numbers table exists
SELECT
  CASE
    WHEN (SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name='numbers') = 0
    THEN 'ERROR: numbers table missing - run 00_digits_numbers.sql first'
    WHEN (SELECT COUNT(*) FROM numbers) = 0
    THEN 'ERROR: numbers table is empty'
    ELSE 'OK: numbers table exists and has data'
  END AS numbers_check;

-- Error handling: Validate parameters
WITH params AS (
  SELECT DATE(:start_date) AS start_date,
         DATE(:end_date_excl) AS end_date_excl
)
SELECT
  CASE
    WHEN ':start_date' = :start_date OR ':end_date_excl' = :end_date_excl
    THEN 'ERROR: Parameters not set - use .param set commands'
    WHEN start_date IS NULL
    THEN 'ERROR: Invalid start_date format'
    WHEN end_date_excl IS NULL
    THEN 'ERROR: Invalid end_date_excl format'
    WHEN start_date >= end_date_excl
    THEN 'ERROR: start_date must be before end_date_excl'
    ELSE 'OK: Parameters are valid'
  END AS param_check
FROM params;

-- Insert dates into calendar table
DROP TABLE IF EXISTS calendar;
CREATE TABLE calendar (
  date_id DATE PRIMARY KEY
) WITHOUT ROWID;

WITH
params AS (
  SELECT DATE(:start_date) AS start_date,
         DATE(:end_date_excl) AS end_date_excl
),
span AS (
  SELECT CAST(julianday(end_date_excl) - julianday(start_date) AS INTEGER) AS days
  FROM params
)
INSERT INTO calendar(date_id)
SELECT DATE(p.start_date, '+' || n.n || ' day')
FROM params p
JOIN span s
JOIN numbers n ON n.n < s.days
ORDER BY n.n;

-- Error handling: Verify calendar creation
SELECT
  COUNT(*) AS calendar_rows,
  MIN(date_id) AS first_date,
  MAX(date_id) AS last_date,
  CASE
    WHEN COUNT(*) = (SELECT CAST(julianday(:end_date_excl) - julianday(:start_date) AS INTEGER))
    THEN 'OK: Calendar created with expected number of days'
    ELSE 'ERROR: Calendar row count mismatch'
  END AS calendar_check
FROM calendar;
