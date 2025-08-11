
import pandera.pandas as pa
from otto.logging_config import logger


def validate_with_schema(df, schema, schema_name):
    logger.info(f"Validating DataFrame with {schema_name} schema, rows: {len(df)}")
    try:
        validated = schema.validate(df)
        logger.info(f"Validation with {schema_name} successful")
        return validated
    except Exception as e:
        logger.error(f"Validation with {schema_name} failed: {e}", exc_info=True)
        raise


product_schema = pa.DataFrameSchema({
    "sku_id": pa.Column(pa.Int, nullable=False),
    "sku_description": pa.Column(pa.String, nullable=True),
    "price": pa.Column(pa.Float, checks=pa.Check.gt(0), nullable=False),
})


sales_schema = pa.DataFrameSchema({
    "sku_id": pa.Column(pa.Int, nullable=False),
    "order_id": pa.Column(pa.String, nullable=False),
    "sales": pa.Column(pa.Int, checks=pa.Check.ge(0), nullable=False),
    "orderdate_utc": pa.Column(pa.String, nullable=False),
})


revenue_schema = pa.DataFrameSchema({
    "sku_id": pa.Column(pa.Int, nullable=False),
    "date_id": pa.Column(pa.Date, nullable=False),
    "price": pa.Column(pa.Float, checks=pa.Check.ge(0), nullable=False),
    "sales": pa.Column(pa.Int, checks=pa.Check.ge(0), nullable=False),
    "revenue": pa.Column(pa.Float, checks=pa.Check.ge(0), nullable=False),
})
