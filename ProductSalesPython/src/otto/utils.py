
from otto.logging_config import logger


def validate_df_with_model(df, Model):
    """
    Validate DataFrame rows using a Pydantic model.

    Args:
        df (pd.DataFrame): DataFrame to validate.
        Model: Pydantic model class to validate each row.

    Raises:
        ValidationError: If any row is invalid according to the model.
    """
    logger.info(f"Validating DataFrame with model {Model.__name__}, rows: {len(df)}")
    try:
        for row in df.to_dict(orient="records"):
            Model(**row)
        logger.info("Validation successful")
    except Exception as e:
        logger.error(f"Validation failed: {e}", exc_info=True)
        raise


def clean_df(df):
    """
    Clean a DataFrame by replacing NA/N/A/empty strings with None and stripping strings.

    Args:
        df (pd.DataFrame): DataFrame to clean.

    Returns:
        pd.DataFrame: Cleaned DataFrame.
    """
    logger.info(f"Cleaning DataFrame with shape {df.shape}")
    try:
        df = df.replace(["NA", "N/A", ""], [None, None, None])
        df = df.map(lambda x: x.strip() if isinstance(x, str) else x)
        logger.info("Data cleaning successful")
        return df
    except Exception as e:
        logger.error(f"Data cleaning failed: {e}", exc_info=True)
        raise
