import pytest
from otto.models import Product, SalesRecord, RevenueRow
from datetime import date


def test_product_negative_price():
    with pytest.raises(ValueError):
        Product(sku_id="A", sku_description="desc", price=-1.0)


def test_product_empty_sku_id():
    with pytest.raises(ValueError):
        Product(sku_id="   ", sku_description="desc", price=10.0)


def test_sales_record_empty_order_id():
    with pytest.raises(ValueError):
        SalesRecord(sku_id="A", order_id="   ", sales=2, orderdate_utc="2025-01-01")


def test_sales_record_sales_negative():
    with pytest.raises(ValueError):
        SalesRecord(sku_id="A", order_id="O1", sales=-3, orderdate_utc="2025-01-01")


def test_revenue_row_negative_revenue():
    with pytest.raises(ValueError):
        RevenueRow(sku_id=1, date_id=date(2025,1,1), price=10.0, sales=2, revenue=-1.0)


def test_revenue_row_good():
    RevenueRow(sku_id=1, date_id=date(2025,1,1), price=10.0, sales=2, revenue=20.0)
