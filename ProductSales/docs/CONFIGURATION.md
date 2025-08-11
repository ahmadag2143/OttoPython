# Configuration Management

The Otto ETL pipeline supports environment-based configuration through environment variables. This allows you to customize behavior for different deployment environments (development, staging, production) without changing code.

## Configuration Options

### Database Configuration

- `DATABASE_URL`: Path or connection string to the database
  - Default: `product_sales.db` (relative to project root)
  - Example: `DATABASE_URL=/path/to/database.db`

### Date Range Configuration

- `START_DATE`: Start date for calendar data (YYYY-MM-DD format)
  - Default: `2025-01-01`
- `END_DATE`: End date for calendar data (YYYY-MM-DD format)
  - Default: `2025-01-31`

### Logging Configuration

- `LOG_LEVEL`: Logging level (DEBUG, INFO, WARNING, ERROR, CRITICAL)
  - Default: `INFO`
- `LOG_FORMAT`: Log message format string
  - Default: `%(asctime)s %(levelname)s %(name)s %(message)s`

### ETL Configuration

- `BATCH_SIZE`: Number of records to process in batches
  - Default: `10000`
- `ENABLE_PYDANTIC_VALIDATION`: Enable row-level validation with Pydantic (true/false)
  - Default: `true`
- `ENABLE_PANDERA_VALIDATION`: Enable DataFrame-level validation with Pandera (true/false)
  - Default: `true`

### Performance Configuration

- `MAX_RETRIES`: Maximum number of retry attempts for failed operations
  - Default: `3`
- `RETRY_DELAY`: Delay between retry attempts in seconds
  - Default: `1.0`

### Environment Configuration

- `ENVIRONMENT`: Deployment environment (development, staging, production)
  - Default: `development`
- `DEBUG`: Enable debug mode (true/false)
  - Default: `false`

## Usage

### Method 1: Environment Variables

Set environment variables directly:

```bash
export LOG_LEVEL=DEBUG
export DATABASE_URL=/path/to/prod.db
python main.py
```

### Method 2: .env File

Create a `.env` file in the project root:

```bash
# Edit .env with your values
python main.py
```

### Method 3: Docker Environment

In docker-compose.yml or Dockerfile:

```yaml
environment:
  - LOG_LEVEL=INFO
  - DATABASE_URL=postgresql://user:pass@db:5432/otto
  - ENVIRONMENT=production
```

## Environment Examples

### Development

```bash
ENVIRONMENT=development
LOG_LEVEL=DEBUG
DEBUG=true
ENABLE_PYDANTIC_VALIDATION=true
ENABLE_PANDERA_VALIDATION=true
```

### Production

```bash
ENVIRONMENT=production
LOG_LEVEL=WARNING
DEBUG=false
DATABASE_URL=postgresql://user:password@host:port/database
MAX_RETRIES=5
RETRY_DELAY=2.0
```

### Testing

```bash
ENVIRONMENT=testing
LOG_LEVEL=ERROR
DATABASE_URL=:memory:
ENABLE_PYDANTIC_VALIDATION=false
ENABLE_PANDERA_VALIDATION=false
```

## Configuration Validation

The configuration is automatically validated on startup. Invalid configurations will raise clear error messages:

- Date formats must be YYYY-MM-DD
- BATCH_SIZE must be positive
- MAX_RETRIES must be non-negative
- RETRY_DELAY must be non-negative

## Security Notes

- Never commit `.env` files with sensitive data
- Use secure connection strings in production
- Consider using secret management systems for production credentials
