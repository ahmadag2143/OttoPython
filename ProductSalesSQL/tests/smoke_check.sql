-- Error handling: Check required tables exist
SELECT
  CASE
    WHEN (SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name='product') = 0
    THEN 'ERROR: product table missing'
    WHEN (SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name='sales') = 0
    THEN 'ERROR: sales table missing'
    WHEN (SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name='calendar') = 0
    THEN 'ERROR: calendar table missing'
    WHEN (SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name='revenue') = 0
    THEN 'ERROR: revenue table missing'
    ELSE 'OK: All required tables exist'
  END AS table_check;

-- Error handling: Check for empty tables
SELECT
  CASE
    WHEN (SELECT COUNT(*) FROM product) = 0 THEN 'ERROR: product table is empty'
    WHEN (SELECT COUNT(*) FROM calendar) = 0 THEN 'ERROR: calendar table is empty'
    ELSE 'OK: Core tables have data'
  END AS data_check;

-- Error handling: Check date range validity
SELECT
  CASE
    WHEN :start_date >= :end_date_excl THEN 'ERROR: start_date must be before end_date_excl'
    WHEN (SELECT COUNT(*) FROM calendar WHERE date_id >= :start_date AND date_id < :end_date_excl) = 0
    THEN 'ERROR: No calendar entries for specified date range'
    ELSE 'OK: Date range is valid'
  END AS date_range_check;

-- expected rows = (#products) × (#days)
WITH days AS (
  SELECT COUNT(*) AS d
  FROM calendar
  WHERE date_id >= :start_date AND date_id < :end_date_excl
)
SELECT
  (SELECT COUNT(*) FROM product) * (SELECT d FROM days) AS expected_rows,
  (SELECT COUNT(*) FROM revenue) AS actual_rows,
  CASE
    WHEN (SELECT COUNT(*) FROM revenue) = (SELECT COUNT(*) FROM product) * (SELECT d FROM days)
    THEN 'OK: Row count matches expected'
    ELSE 'ERROR: Row count mismatch - check data pipeline'
  END AS row_count_check;

-- Error handling: Data quality checks
SELECT
  SUM(CASE WHEN sales   < 0 THEN 1 ELSE 0 END) AS neg_sales,
  SUM(CASE WHEN revenue < 0 THEN 1 ELSE 0 END) AS neg_revenue,
  SUM(CASE WHEN sales IS NULL THEN 1 ELSE 0 END) AS null_sales,
  SUM(CASE WHEN revenue IS NULL THEN 1 ELSE 0 END) AS null_revenue,
  SUM(CASE WHEN sku_id IS NULL OR sku_id = '' THEN 1 ELSE 0 END) AS null_empty_sku,
  SUM(CASE WHEN date_id IS NULL THEN 1 ELSE 0 END) AS null_dates,
  CASE
    WHEN SUM(CASE WHEN sales < 0 OR revenue < 0 OR sales IS NULL OR revenue IS NULL
                   OR sku_id IS NULL OR sku_id = '' OR date_id IS NULL THEN 1 ELSE 0 END) = 0
    THEN 'OK: All data quality checks passed'
    ELSE 'ERROR: Data quality issues detected'
  END AS data_quality_check
FROM revenue;

-- Error handling: Business logic validation
SELECT
  COUNT(*) AS total_revenue_rows,
  COUNT(DISTINCT sku_id) AS unique_skus,
  COUNT(DISTINCT date_id) AS unique_dates,
  MIN(date_id) AS min_date,
  MAX(date_id) AS max_date,
  CASE
    WHEN MIN(date_id) < :start_date OR MAX(date_id) >= :end_date_excl
    THEN 'ERROR: Revenue data contains dates outside expected range'
    ELSE 'OK: All dates within expected range'
  END AS date_boundary_check
FROM revenue;

-- spot-check a few dates
SELECT sku_id, date_id, sales, revenue
FROM revenue
ORDER BY date_id, sku_id
LIMIT 10;
