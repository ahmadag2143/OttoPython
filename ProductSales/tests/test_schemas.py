import pandas as pd
import pytest
from otto.schemas import product_schema, sales_schema, revenue_schema


def test_product_schema_accepts_good():
    df = pd.DataFrame({'sku_id': [1], 'sku_description': ['desc'], 'price': [1.0]})
    product_schema.validate(df)


def test_product_schema_rejects_bad_price():
    df = pd.DataFrame({'sku_id': [1], 'sku_description': ['desc'], 'price': [-1.0]})
    with pytest.raises(Exception):
        product_schema.validate(df)


def test_sales_schema_rejects_missing_sales():
    df = pd.DataFrame({'sku_id': [1], 'order_id': ['O1'], 'sales': [None], 'orderdate_utc': ['2025-01-01']})
    with pytest.raises(Exception):
        sales_schema.validate(df)


def test_revenue_schema_accepts_good():
    df = pd.DataFrame({
        "sku_id": [1],
        "date_id": [pd.to_datetime("2025-01-01").date()],
        "price": [1.0],
        "sales": [2],
        "revenue": [2.0]
    })
    revenue_schema.validate(df)


def test_revenue_schema_rejects_negative_sales():
    df = pd.DataFrame({
        "sku_id": [1],
        "date_id": [pd.to_datetime("2025-01-01").date()],
        "price": [1.0],
        "sales": [-1],
        "revenue": [-1.0]
    })
    with pytest.raises(Exception):
        revenue_schema.validate(df)
