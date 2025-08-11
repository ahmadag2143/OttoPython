from otto.config import config
from otto.db_utils import get_connection, read_table, write_table, read_calendar
from otto.etl import run_etl
from otto.utils import clean_df, validate_df_with_model
from otto.schemas import product_schema, sales_schema
from otto.models import Product, SalesRecord
from otto.logging_config import logger


def main():
    # Validate configuration
    config.validate()
    logger.info(f"Starting ETL pipeline with config: {config}")

    try:
        with get_connection(config.database_url) as conn:
            products_df = read_table(conn, "product", columns=['sku_id', 'sku_description', 'price'])
            sales_df = read_table(conn, "sales", columns=['sku_id', 'order_id', 'sales', 'orderdate_utc'])
            calendar_df = read_calendar(conn, config.start_date, config.end_date)

            # Generate calendar if table is empty
            if len(calendar_df) == 0:
                logger.warning("Calendar table is empty, generating date range dynamically")
                import pandas as pd
                date_range = pd.date_range(start=config.start_date, end=config.end_date, freq='D')
                calendar_df = pd.DataFrame({'date_id': date_range.date})
                logger.info(f"Generated {len(calendar_df)} calendar dates")

            logger.info("Cleaning product and sales data")
            products_df = clean_df(products_df)
            sales_df = clean_df(sales_df)

            if config.enable_pandera_validation:
                logger.info("Validating product and sales schemas with Pandera")
                product_schema.validate(products_df, lazy=True)
                sales_schema.validate(sales_df, lazy=True)

            if config.enable_pydantic_validation:
                logger.info("Validating product and sales rows with Pydantic")
                validate_df_with_model(products_df, Product)
                validate_df_with_model(sales_df, SalesRecord)

            logger.info("Running ETL transformation")
            result_df = run_etl(products_df, sales_df, calendar_df)
            write_table(conn, result_df, "revenue")
            logger.info("Pipeline completed. Output written to 'revenue' table.", extra={"rows": len(result_df)})
    except Exception as e:
        logger.error(f"ETL pipeline failed: {e}", exc_info=True)
        if config.is_production():
            # In production, exit with error code
            exit(1)
        else:
            # In development, re-raise for debugging
            raise


if __name__ == "__main__":
    main()
