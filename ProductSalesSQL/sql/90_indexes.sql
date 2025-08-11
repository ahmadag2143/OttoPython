-- Error handling: Check if tables exist before creating indexes
SELECT
  CASE
    WHEN (SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name='sales') = 0
    THEN 'ERROR: sales table missing - cannot create indexes'
    WHEN (SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name='calendar') = 0
    THEN 'ERROR: calendar table missing - cannot create indexes'
    WHEN (SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name='product') = 0
    THEN 'ERROR: product table missing - cannot create indexes'
    ELSE 'OK: All tables exist for indexing'
  END AS table_check;

CREATE INDEX IF NOT EXISTS idx_sales_date       ON sales (DATE(orderdate_utc));
CREATE INDEX IF NOT EXISTS idx_sales_sku_date   ON sales (sku_id, DATE(orderdate_utc));
CREATE INDEX IF NOT EXISTS idx_calendar_date    ON calendar (date_id);
CREATE INDEX IF NOT EXISTS idx_product_sku      ON product (sku_id);

-- Error handling: Verify indexes were created
SELECT
  COUNT(*) AS index_count,
  GROUP_CONCAT(name, ', ') AS created_indexes
FROM sqlite_master
WHERE type='index'
  AND name IN ('idx_sales_date', 'idx_sales_sku_date', 'idx_calendar_date', 'idx_product_sku');
