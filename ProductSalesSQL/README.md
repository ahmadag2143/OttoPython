## Revenue Pipeline (SQL / SQLite)

### Prerequisites

- SQLite 3.x
- A database `db/product_sales.db`
- Source tables: `product` and `sales`

### Production Pipeline Workflow

### Step 1: Create numbers table (one-time setup)

```bash
sqlite3 db/product_sales.db < sql/00_digits_numbers.sql
```

### Step 2: Generate calendar table

```bash
sqlite3  db/product_sales.db \
-cmd ".parameter set :start_date DATE('2025-01-01')" \
-cmd ".parameter set :end_date_excl DATE('2025-02-01')" \
< sql/01_create_calendar_from_numbers.sql
```

### Step 3: Create indexes (recommended)

```bash
sqlite3 db/product_sales.db < sql/90_indexes.sql
```

### Step 4: Build revenue pipeline

```bash

sqlite3  db/product_sales.db \
-cmd ".parameter set :start_date DATE('2025-01-01')" \
-cmd ".parameter set :end_date_excl DATE('2025-02-01')" \
< sql/10_pipeline.sql
```

### Step 6: Smoke checks

```bash
sqlite3  db/product_sales.db \
-cmd ".parameter set :start_date DATE('2025-01-01')" \
-cmd ".parameter set :end_date_excl DATE('2025-02-01')" \
< tests/smoke_check.sql
```

### Step 7: Data Quality Checks

```bash
sqlite3  db/product_sales.db \
-cmd ".parameter set :start_date DATE('2025-01-01')" \
-cmd ".parameter set :end_date_excl DATE('2025-02-01')" \
< sql/99_data_quality_checks.sql
```
