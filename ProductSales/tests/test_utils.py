import pandas as pd
from otto.utils import clean_df


def test_clean_df_na_and_blank_to_none():
    df = pd.DataFrame({
        "sku_id": ["A", "NA", "  ", ""],
        "price": ["10", "", "N/A", "  "]
    })
    cleaned = clean_df(df)
    # All NA/blank variants become None
    assert cleaned.isnull().iloc[1, 0]    # "NA"
    assert cleaned.isnull().iloc[2, 1]    # "N/A"
    assert cleaned.isnull().iloc[3, 0]    # ""
    assert cleaned.iloc[0, 0] == "A"      # good value remains
