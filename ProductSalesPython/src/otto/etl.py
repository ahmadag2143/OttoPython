
import pandas as pd
from otto.models import RevenueRow
from otto.schemas import revenue_schema
from otto.logging_config import logger
from otto.config import config


def run_etl(products_df: pd.DataFrame, sales_df: pd.DataFrame, calendar_df: pd.DataFrame) -> pd.DataFrame:
    """
    Run the ETL transformation pipeline for product sales data.

    Args:
        products_df (pd.DataFrame): DataFrame containing product information.
        sales_df (pd.DataFrame): DataFrame containing sales records.
        calendar_df (pd.DataFrame): DataFrame containing calendar dates.

    Returns:
        pd.DataFrame: DataFrame with aggregated revenue per product per date.
    """
    logger.info("Starting ETL transformation")
    try:
        # Preprocess sales: add date_id, aggregate by sku_id and date
        logger.info("Preprocessing sales data: adding date_id and aggregating sales")
        sales_df['date_id'] = pd.to_datetime(sales_df['orderdate_utc']).dt.date
        sales_agg = sales_df.groupby(['sku_id', 'date_id'], as_index=False)['sales'].sum()

        # Use calendar_df for all dates in the desired range
        logger.info("Normalizing calendar date_id column")
        calendar_df['date_id'] = pd.to_datetime(calendar_df['date_id']).dt.date

        # Cartesian product: all products x all dates from calendar
        logger.info("Creating full product-date grid")
        full_grid = (products_df.assign(key=1)
                     .merge(calendar_df.assign(key=1), on='key')
                     .drop('key', axis=1))

        # Merge with aggregated sales
        logger.info("Merging product-date grid with aggregated sales")
        merged = pd.merge(full_grid, sales_agg, on=['sku_id', 'date_id'], how='left')
        merged['sales'] = merged['sales'].fillna(0).astype(int)

        # Compute revenue
        logger.info("Computing revenue column")
        merged['revenue'] = merged['price'] * merged['sales']

        # Pandera validation (DataFrame-level)
        if config.enable_pandera_validation:
            logger.info("Validating revenue DataFrame with Pandera schema")
            revenue_schema.validate(
                merged[['sku_id', 'date_id', 'price', 'sales', 'revenue']],
                lazy=True
            )

        # Optional: Validate rows using Pydantic
        if config.enable_pydantic_validation:
            logger.info("Validating each revenue row with Pydantic model")
            for row in merged[['sku_id', 'date_id', 'price', 'sales', 'revenue']].to_dict(orient='records'):
                RevenueRow(**row)

        logger.info(f"ETL transformation complete. Output rows: {len(merged)}")
        return merged[['sku_id', 'date_id', 'price', 'sales', 'revenue']]
    except Exception as e:
        logger.error(f"ETL transformation failed: {e}", exc_info=True)
        raise
