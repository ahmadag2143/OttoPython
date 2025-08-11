-- sql/00_digits_numbers.sql
DROP TABLE IF EXISTS digits;
CREATE TABLE digits (d INTEGER PRIMARY KEY) WITHOUT ROWID;
INSERT INTO digits(d) VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9);

-- Error handling: Verify digits table was created correctly
SELECT
  CASE
    WHEN COUNT(*) = 10 THEN 'OK: digits table created with 10 rows'
    ELSE 'ERROR: digits table should have 10 rows, has ' || COUNT(*)
  END AS digits_check
FROM digits;

-- Insert numbers 0-99999 using cross join
DROP TABLE IF EXISTS numbers;
CREATE TABLE numbers (n INTEGER PRIMARY KEY) WITHOUT ROWID;

INSERT INTO numbers(n)
SELECT  a.d
     + 10*b.d
     + 100*c.d
     + 1000*d.d
     + 10000*e.d
FROM digits a
CROSS JOIN digits b
CROSS JOIN digits c
CROSS JOIN digits d
CROSS JOIN digits e
ORDER BY 1;

-- Error handling: Verify numbers table was created correctly
SELECT
  CASE
    WHEN COUNT(*) = 100000 THEN 'OK: numbers table created with 100,000 rows'
    ELSE 'ERROR: numbers table should have 100,000 rows, has ' || COUNT(*)
  END AS numbers_check,
  MIN(n) AS min_number,
  MAX(n) AS max_number
FROM numbers;
