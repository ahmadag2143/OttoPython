-- Error handling: Check if all required tables exist
SELECT
  CASE
    WHEN (SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name='product') = 0
    THEN 'CRITICAL: product table missing'
    WHEN (SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name='sales') = 0
    THEN 'CRITICAL: sales table missing'
    WHEN (SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name='calendar') = 0
    THEN 'CRITICAL: calendar table missing'
    WHEN (SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name='revenue') = 0
    THEN 'CRITICAL: revenue table missing'
    ELSE 'OK: All required tables exist'
  END AS table_existence_check;

-- 1. PRODUCT TABLE VALIDATION
SELECT '=== PRODUCT TABLE VALIDATION ===' AS section;

-- Check for missing/invalid SKUs in product table
SELECT
  SUM(CASE WHEN sku_id IS NULL OR sku_id = '' THEN 1 ELSE 0 END) AS missing_sku_count,
  CASE
    WHEN SUM(CASE WHEN sku_id IS NULL OR sku_id = '' THEN 1 ELSE 0 END) = 0
    THEN 'OK: No missing SKUs'
    ELSE 'ERROR: Missing SKUs found in product table'
  END AS sku_validation
FROM product;

-- Check for invalid prices in product table
SELECT
  SUM(CASE WHEN price IS NULL OR price < 0 THEN 1 ELSE 0 END) AS invalid_price_count,
  MIN(price) AS min_price,
  MAX(price) AS max_price,
  CASE
    WHEN SUM(CASE WHEN price IS NULL OR price < 0 THEN 1 ELSE 0 END) = 0
    THEN 'OK: All prices are valid'
    ELSE 'ERROR: Invalid prices found in product table'
  END AS price_validation
FROM product;

-- Check for duplicate SKUs in product table
SELECT
  COUNT(*) AS duplicate_sku_count,
  CASE
    WHEN COUNT(*) = 0 THEN 'OK: No duplicate SKUs'
    ELSE 'ERROR: Duplicate SKUs found in product table'
  END AS duplicate_sku_check
FROM (
  SELECT sku_id, COUNT(*) as cnt
  FROM product
  GROUP BY sku_id
  HAVING COUNT(*) > 1
);

-- 2. SALES TABLE VALIDATION
SELECT '=== SALES TABLE VALIDATION ===' AS section;

-- Check for missing/invalid data in sales table
SELECT
  SUM(CASE WHEN sku_id IS NULL OR sku_id = '' THEN 1 ELSE 0 END) AS missing_sku,
  SUM(CASE WHEN orderdate_utc IS NULL THEN 1 ELSE 0 END) AS missing_date,
  SUM(CASE WHEN sales IS NULL OR sales < 0 THEN 1 ELSE 0 END) AS invalid_sales,
  CASE
    WHEN SUM(CASE WHEN sku_id IS NULL OR sku_id = '' OR orderdate_utc IS NULL OR sales IS NULL OR sales < 0 THEN 1 ELSE 0 END) = 0
    THEN 'OK: All sales data is valid'
    ELSE 'ERROR: Invalid data found in sales table'
  END AS sales_data_validation
FROM sales;

-- Check for future dates in sales
SELECT
  COUNT(*) AS future_date_count,
  CASE
    WHEN COUNT(*) = 0 THEN 'OK: No future dates'
    ELSE 'WARNING: Future dates found in sales table'
  END AS future_date_check
FROM sales
WHERE DATE(orderdate_utc) > DATE('now');

-- Check for orphaned SKUs (sales SKUs not in product table)
SELECT
  COUNT(*) AS orphaned_sku_count,
  CASE
    WHEN COUNT(*) = 0 THEN 'OK: All sales SKUs exist in product table'
    ELSE 'ERROR: Sales contain SKUs not in product table'
  END AS orphaned_sku_check
FROM sales s
LEFT JOIN product p ON s.sku_id = p.sku_id
WHERE p.sku_id IS NULL;

-- 3. CALENDAR TABLE VALIDATION
SELECT '=== CALENDAR TABLE VALIDATION ===' AS section;

-- Check for gaps in calendar
WITH date_gaps AS (
  SELECT
    date_id,
    LAG(date_id) OVER (ORDER BY date_id) AS prev_date,
    julianday(date_id) - julianday(LAG(date_id) OVER (ORDER BY date_id)) AS gap_days
  FROM calendar
)
SELECT
  COUNT(*) AS gap_count,
  CASE
    WHEN COUNT(*) = 0 THEN 'OK: No gaps in calendar'
    ELSE 'WARNING: Gaps found in calendar dates'
  END AS calendar_gap_check
FROM date_gaps
WHERE gap_days > 1;

-- Check for duplicate dates in calendar
SELECT
  COUNT(*) AS duplicate_date_count,
  CASE
    WHEN COUNT(*) = 0 THEN 'OK: No duplicate dates in calendar'
    ELSE 'ERROR: Duplicate dates found in calendar'
  END AS calendar_duplicate_check
FROM (
  SELECT date_id, COUNT(*) as cnt
  FROM calendar
  GROUP BY date_id
  HAVING COUNT(*) > 1
);

-- 4. REVENUE TABLE VALIDATION (if exists)
SELECT '=== REVENUE TABLE VALIDATION ===' AS section;

-- Check revenue calculation accuracy
SELECT
  COUNT(*) AS calculation_error_count,
  CASE
    WHEN COUNT(*) = 0 THEN 'OK: All revenue calculations are accurate'
    ELSE 'ERROR: Revenue calculation errors detected'
  END AS revenue_calculation_check
FROM revenue
WHERE ABS(revenue - (price * sales)) > 0.01;

-- Check for impossible sales volumes (adjust threshold as needed)
SELECT
  COUNT(*) AS high_volume_count,
  MAX(sales) AS max_sales_volume,
  CASE
    WHEN COUNT(*) = 0 THEN 'OK: No unusually high sales volumes'
    ELSE 'WARNING: Unusually high sales volumes detected (>10000)'
  END AS sales_volume_check
FROM revenue
WHERE sales > 10000;

-- 5. DATA COMPLETENESS CHECKS
SELECT '=== DATA COMPLETENESS VALIDATION ===' AS section;

-- Expected vs actual row counts in revenue
WITH params AS (
  SELECT DATE(:start_date) AS start_date,
         DATE(:end_date_excl) AS end_date_excl
),
expected AS (
  SELECT
    (SELECT COUNT(*) FROM product) *
    (SELECT COUNT(*) FROM calendar c, params p WHERE c.date_id >= p.start_date AND c.date_id < p.end_date_excl)
    AS expected_rows
)
SELECT
  expected_rows,
  (SELECT COUNT(*) FROM revenue) AS actual_rows,
  CASE
    WHEN expected_rows = (SELECT COUNT(*) FROM revenue)
    THEN 'OK: Revenue table has expected row count'
    ELSE 'ERROR: Revenue table row count mismatch'
  END AS completeness_check
FROM expected;

-- 6. CROSS-REFERENCE VALIDATION
SELECT '=== CROSS-REFERENCE VALIDATION ===' AS section;

-- Ensure all revenue SKUs exist in product table
SELECT
  COUNT(*) AS invalid_revenue_sku_count,
  CASE
    WHEN COUNT(*) = 0 THEN 'OK: All revenue SKUs exist in product table'
    ELSE 'ERROR: Revenue contains SKUs not in product table'
  END AS revenue_sku_validation
FROM revenue r
LEFT JOIN product p ON r.sku_id = p.sku_id
WHERE p.sku_id IS NULL;

-- Ensure all revenue dates exist in calendar
SELECT
  COUNT(*) AS invalid_revenue_date_count,
  CASE
    WHEN COUNT(*) = 0 THEN 'OK: All revenue dates exist in calendar'
    ELSE 'ERROR: Revenue contains dates not in calendar'
  END AS revenue_date_validation
FROM revenue r
LEFT JOIN calendar c ON r.date_id = c.date_id
WHERE c.date_id IS NULL;

-- 7. DATA FRESHNESS CHECKS
SELECT '=== DATA FRESHNESS VALIDATION ===' AS section;

-- Check data recency
SELECT
  MAX(DATE(orderdate_utc)) AS latest_sales_date,
  DATE('now') AS current_date,
  CAST(julianday('now') - julianday(MAX(DATE(orderdate_utc))) AS INTEGER) AS days_old,
  CASE
    WHEN julianday('now') - julianday(MAX(DATE(orderdate_utc))) <= 7
    THEN 'OK: Sales data is recent (within 7 days)'
    WHEN julianday('now') - julianday(MAX(DATE(orderdate_utc))) <= 30
    THEN 'WARNING: Sales data is somewhat old (within 30 days)'
    ELSE 'WARNING: Sales data is stale (older than 30 days)'
  END AS data_freshness_check
FROM sales;

-- 8. PERFORMANCE & VOLUME MONITORING
SELECT '=== PERFORMANCE & VOLUME MONITORING ===' AS section;

-- Table size monitoring
SELECT
  'product' AS table_name,
  COUNT(*) AS row_count,
  CASE
    WHEN COUNT(*) = 0 THEN 'ERROR: Empty table'
    WHEN COUNT(*) < 10 THEN 'WARNING: Very small dataset'
    ELSE 'OK: Adequate data volume'
  END AS volume_check
FROM product
UNION ALL
SELECT
  'sales' AS table_name,
  COUNT(*) AS row_count,
  CASE
    WHEN COUNT(*) = 0 THEN 'ERROR: Empty table'
    WHEN COUNT(*) < 100 THEN 'WARNING: Very small dataset'
    ELSE 'OK: Adequate data volume'
  END AS volume_check
FROM sales
UNION ALL
SELECT
  'calendar' AS table_name,
  COUNT(*) AS row_count,
  CASE
    WHEN COUNT(*) = 0 THEN 'ERROR: Empty table'
    WHEN COUNT(*) < 30 THEN 'WARNING: Very small dataset'
    ELSE 'OK: Adequate data volume'
  END AS volume_check
FROM calendar
UNION ALL
SELECT
  'revenue' AS table_name,
  COUNT(*) AS row_count,
  CASE
    WHEN COUNT(*) = 0 THEN 'ERROR: Empty table'
    ELSE 'OK: Revenue table populated'
  END AS volume_check
FROM revenue;

-- 9. BUSINESS LOGIC VALIDATION
SELECT '=== BUSINESS LOGIC VALIDATION ===' AS section;

-- Revenue trend analysis (detect anomalies)
WITH daily_revenue AS (
  SELECT date_id, SUM(revenue) AS total_revenue
  FROM revenue
  GROUP BY date_id
),
revenue_stats AS (
  SELECT
    AVG(total_revenue) AS avg_revenue,
    AVG(total_revenue) * 3 AS high_threshold,
    AVG(total_revenue) * 0.1 AS low_threshold
  FROM daily_revenue
)
SELECT
  COUNT(*) AS anomaly_count,
  CASE
    WHEN COUNT(*) = 0 THEN 'OK: No revenue anomalies detected'
    ELSE 'WARNING: Revenue anomalies detected (extremely high/low days)'
  END AS revenue_anomaly_check
FROM daily_revenue d, revenue_stats s
WHERE d.total_revenue > s.high_threshold
   OR d.total_revenue < s.low_threshold;

-- 10. FINAL SUMMARY
SELECT '=== DATA QUALITY SUMMARY ===' AS section;

SELECT
  'Data Quality Check Complete' AS status,
  DATETIME('now') AS check_timestamp,
  'Review all ERROR and WARNING messages above' AS next_action;
