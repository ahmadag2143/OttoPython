# Otto ETL Pipeline

A production-ready ETL (Extract, Transform, Load) pipeline for processing product sales data and generating revenue analytics for business intelligence reporting.

## 🎯 Overview

The Otto ETL Pipeline transforms raw product and sales data into a comprehensive revenue dataset suitable for PowerBI reports and business analytics. It processes daily sales data across all products, filling gaps for products with no sales to provide complete business visibility.

## 🏗️ Architecture

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   Product   │    │    Sales    │    │  Calendar   │
│   Database  │    │  Database   │    │ (Generated) │
└──────┬──────┘    └──────┬──────┘    └──────┬──────┘
       │                  │                  │
       └──────────────────┼──────────────────┘
                          │
                    ┌─────▼─────┐
                    │    ETL    │
                    │ Transform │
                    └─────┬─────┘
                          │
                    ┌─────▼─────┐
                    │  Revenue  │
                    │   Table   │
                    └───────────┘
```

### Key Components

- **Data Extraction**: Reads from product, sales, and calendar tables
- **Data Validation**: Dual-layer validation with Pandera (schema) and Pydantic (business rules)
- **Data Transformation**: Creates complete product-date grid with revenue calculations
- **Configuration Management**: Environment-based configuration for multi-stage deployments
- **Centralized Logging**: Comprehensive observability throughout the pipeline

## 📊 Data Model

### Input Tables

- **product**: Product catalog with SKU, description, and pricing
- **sales**: Transaction records with order details and quantities
- **calendar**: Date dimension (auto-generated if empty)

### Output Table

```sql
CREATE TABLE revenue (
    sku_id INTEGER,     -- Product identifier
    date_id DATE,       -- Transaction date
    price REAL,         -- Product price
    sales INTEGER,      -- Quantity sold (0 if no sales)
    revenue REAL        -- Calculated revenue (price × sales)
);
```

## 🚀 Quick Start

### Prerequisites

- Python 3.9+
- SQLite database with product and sales tables

### Installation

1. **Clone and setup**:

```bash
git clone <repository-url>
cd otto
```

2. **Install dependencies**:

```bash
pip install -e .
```

```bash

```

4. **Run the pipeline**:

```bash
python main.py
```

## ⚙️ Configuration

The pipeline uses environment-based configuration for flexible deployment across different environments.

### Environment Variables

| Variable                       | Default              | Description                                 |
| ------------------------------ | -------------------- | ------------------------------------------- |
| `DATABASE_URL`               | `product_sales.db` | Database connection string                  |
| `START_DATE`                 | `2025-01-01`       | Start date for data processing              |
| `END_DATE`                   | `2025-01-31`       | End date for data processing                |
| `LOG_LEVEL`                  | `INFO`             | Logging level (DEBUG, INFO, WARNING, ERROR) |
| `BATCH_SIZE`                 | `10000`            | Processing batch size                       |
| `ENABLE_PYDANTIC_VALIDATION` | `true`             | Enable row-level validation                 |
| `ENABLE_PANDERA_VALIDATION`  | `true`             | Enable schema validation                    |
| `ENVIRONMENT`                | `development`      | Deployment environment                      |

### Configuration Examples

**Development**:

```bash
ENVIRONMENT=development
LOG_LEVEL=DEBUG
DEBUG=true
```

**Production**:

```bash
ENVIRONMENT=production
LOG_LEVEL=WARNING
DATABASE_URL=postgresql://user:pass@host:port/db
MAX_RETRIES=5
```

## 🧪 Testing

### Run All Tests

```bash
pytest tests/ -v
```

### Run Specific Test Categories

```bash
# Test data models
pytest tests/test_models.py -v

# Test ETL logic
pytest tests/test_etl.py -v

# Test configuration
pytest tests/test_config.py -v
```

### Test Coverage

```bash
pytest --cov=otto tests/
```

## 📁 Project Structure

```
otto/
├── src/otto/                   # Main package
│   ├── __init__.py
│   ├── config.py               # Configuration management
│   ├── db_utils.py             # Database utilities
│   ├── etl.py                  # ETL transformation logic
│   ├── logging_config.py       # Centralized logging
│   ├── main.py                 # Application entry point
│   ├── models.py               # Pydantic data models
│   ├── schemas.py              # Pandera validation schemas
│   └── utils.py                # Utility functions
├── tests/                      # Test suite
│   ├── test_config.py
│   ├── test_etl.py
│   ├── test_models.py
│   ├── test_schemas.py
│   └── test_utils.py
├── docs/                       # Documentation
│   └── CONFIGURATION.md
├── .env                        # Environment configuration
├── .gitignore                  # Git ignore rules
├── .flake8                     # Code style configuration
├── main.py                     # CLI entry point
├── pyproject.toml              # Project configuration
├── requirements.txt            # Dependencies
└── README.md                   # This file
```

## 🔍 Data Quality & Validation

The pipeline implements multiple validation layers:

### Schema Validation (Pandera)

- **DataFrame-level validation**: Ensures data types and constraints
- **Column validation**: Checks for required fields and data integrity
- **Business rule validation**: Enforces domain-specific constraints

### Business Rule Validation (Pydantic)

- **Row-level validation**: Validates individual records
- **Type safety**: Ensures data type consistency
- **Custom validators**: Business logic validation

### Example Validations

```python
# Price must be positive
price: float = Field(..., gt=0)

# SKU ID must be positive integer
sku_id: int = Field(..., gt=0)

# Sales quantity cannot be negative
sales: int = Field(..., ge=0)
```

### Code Style

- **PEP 8 compliance** with 150-character line limit
- **Type hints** throughout codebase
- **Comprehensive docstrings** for all functions
- **Import organization** following isort standards

### Adding New Features

1. Create feature branch
2. Add comprehensive tests
3. Update documentation
4. Ensure all quality checks pass
5. Submit pull request

- **Automated testing** on multiple Python versions
- **Code quality checks** with flake8 and pytest
- **Security scanning** with safety and bandit
- **Automated deployment** to staging and production

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes with tests
4. Ensure all tests pass (`pytest tests/ -v`)
5. Commit your changes (`git commit -m 'Add amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

### Contribution Guidelines

- **Test coverage**: Maintain >90% test coverage
- **Documentation**: Update documentation for new features
- **Code style**: Follow existing code style and conventions
- **Type hints**: Add type hints for all new functions

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

### Common Issues

**Import Errors**:

```bash
# Reinstall in development mode
pip install -e .
```

**Database Connection Issues**:

```bash
# Check database path in configuration
python -c "from otto.config import config; print(config.database_url)"
```

**Test Failures**:

```bash
# Run with verbose output
pytest tests/ -v -s
```
