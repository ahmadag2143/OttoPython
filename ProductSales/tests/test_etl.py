import pandas as pd
from otto.etl import run_etl


def test_etl_basic_integration():
    products_df = pd.DataFrame({
        'sku_id': [1, 2],
        'sku_description': ['foo', 'bar'],
        'price': [10.0, 20.0]
    })
    sales_df = pd.DataFrame({
        'sku_id': [1, 1, 2],
        'order_id': ['O1', 'O2', 'O3'],
        'sales': [2, 3, 0],
        'orderdate_utc': ['2025-01-01', '2025-01-01', '2025-01-01']
    })
    calendar_df = pd.DataFrame({'date_id': pd.to_datetime(['2025-01-01', '2025-01-02']).date})

    df = run_etl(products_df, sales_df, calendar_df)
    # Check that 1 on 2025-01-01 has sales=5, revenue=50.0
    rec = df[(df['sku_id'] == 1) & (df['date_id'] == pd.to_datetime('2025-01-01').date())]
    assert rec['sales'].iloc[0] == 5
    assert rec['revenue'].iloc[0] == 50.0
    # 2 on any date should be zero sales/revenue
    rec_b = df[(df['sku_id'] == 2) & (df['date_id'] == pd.to_datetime('2025-01-01').date())]
    assert rec_b['sales'].iloc[0] == 0
    assert rec_b['revenue'].iloc[0] == 0.0

def test_etl_handles_missing_dates_and_zero_sales():
    products_df = pd.DataFrame({
        'sku_id': [1],
        'sku_description': ['desc'],
        'price': [5.0]
    })
    sales_df = pd.DataFrame({
        'sku_id': [],
        'order_id': [],
        'sales': [],
        'orderdate_utc': []
    })
    calendar_df = pd.DataFrame({'date_id': pd.to_datetime(['2025-01-01', '2025-01-02']).date})

    df = run_etl(products_df, sales_df, calendar_df)
    assert (df['sales'] == 0).all()
    assert (df['revenue'] == 0).all()
