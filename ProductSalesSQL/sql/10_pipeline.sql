-- Error handling: Check prerequisites
SELECT
  CASE
    WHEN (SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name='product') = 0
    THEN 'ERROR: product table missing'
    WHEN (SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name='sales') = 0
    THEN 'ERROR: sales table missing'
    WHEN (SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name='calendar') = 0
    THEN 'ERROR: calendar table missing'
    WHEN (SELECT COUNT(*) FROM product) = 0
    THEN 'ERROR: product table is empty'
    WHEN (SELECT COUNT(*) FROM calendar) = 0
    THEN 'ERROR: calendar table is empty'
    ELSE 'OK: Prerequisites met'
  END AS prereq_check;

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
    WHEN (SELECT COUNT(*) FROM calendar WHERE date_id >= start_date AND date_id < end_date_excl) = 0
    THEN 'ERROR: No calendar entries for specified date range'
    ELSE 'OK: Parameters are valid'
  END AS param_check
FROM params;

BEGIN;

-- 0) Target table scaffold (new table; we’ll swap at the end)
DROP TABLE IF EXISTS revenue_new;
CREATE TABLE revenue_new (
  sku_id   TEXT NOT NULL,
  date_id  DATE NOT NULL,
  price    REAL NOT NULL,
  sales    INTEGER NOT NULL DEFAULT 0,
  revenue  REAL NOT NULL DEFAULT 0,
  PRIMARY KEY (sku_id, date_id)
) WITHOUT ROWID;

WITH
vars AS (
  SELECT DATE(:start_date) AS start_date,
         DATE(:end_date_excl) AS end_date_excl
),
cal AS (
  SELECT c.date_id
  FROM calendar c
  CROSS JOIN vars v
  WHERE c.date_id >= v.start_date
    AND c.date_id <  v.end_date_excl
),
sales_agg AS (
  SELECT
    s.sku_id,
    DATE(s.orderdate_utc) AS date_id,
    SUM(s.sales) AS sales
  FROM sales s
  CROSS JOIN vars v
  WHERE DATE(s.orderdate_utc) >= v.start_date
    AND DATE(s.orderdate_utc) <  v.end_date_excl
  GROUP BY s.sku_id, DATE(s.orderdate_utc)
),
product_dates AS (
  SELECT
    p.sku_id,
    p.price,
    c.date_id
  FROM product p
  CROSS JOIN cal c
)
INSERT INTO revenue_new (sku_id, date_id, price, sales, revenue)
SELECT
  pd.sku_id,
  pd.date_id,
  pd.price,
  COALESCE(sa.sales, 0) AS sales,
  pd.price * COALESCE(sa.sales, 0) AS revenue
FROM product_dates pd
LEFT JOIN sales_agg sa
  ON sa.sku_id = pd.sku_id
 AND sa.date_id = pd.date_id;

-- 1) Swap in atomically
DROP TABLE IF EXISTS revenue;
ALTER TABLE revenue_new RENAME TO revenue;

-- Error handling: Verify pipeline completion
SELECT
  COUNT(*) AS total_rows,
  COUNT(DISTINCT sku_id) AS unique_skus,
  COUNT(DISTINCT date_id) AS unique_dates,
  MIN(date_id) AS first_date,
  MAX(date_id) AS last_date,
  SUM(CASE WHEN sales < 0 THEN 1 ELSE 0 END) AS negative_sales,
  SUM(CASE WHEN revenue < 0 THEN 1 ELSE 0 END) AS negative_revenue,
  CASE
    WHEN COUNT(*) = (SELECT COUNT(*) FROM product) *
                    (SELECT COUNT(*) FROM calendar WHERE date_id >= :start_date AND date_id < :end_date_excl)
    THEN 'OK: Pipeline completed successfully'
    ELSE 'ERROR: Unexpected row count in revenue table'
  END AS pipeline_check
FROM revenue;

COMMIT;
