# db_utils.py

import sqlite3
import pandas as pd
from otto.logging_config import logger


def get_connection(db_path: str) -> sqlite3.Connection:
    """
    Establish a connection to the SQLite database at the given path.

    Args:
        db_path (str): Path to the SQLite database file.

    Returns:
        sqlite3.Connection: SQLite connection object.
    """
    logger.info(f"Connecting to database at {db_path}")
    try:
        conn = sqlite3.connect(db_path)
        logger.info("Database connection established")
        return conn
    except Exception as e:
        logger.error(f"Failed to connect to database: {e}")
        raise


def read_table(conn: sqlite3.Connection, table_name: str, columns: list[str] = None) -> pd.DataFrame:
    """
    Read a table from the database into a DataFrame.

    Args:
        conn (sqlite3.Connection): SQLite connection object.
        table_name (str): Name of the table to read.
        columns (list[str], optional): List of columns to read. Reads all if None.

    Returns:
        pd.DataFrame: DataFrame containing the table data.
    """
    cols = '*' if columns is None else ', '.join(columns)
    logger.info(f"Reading table '{table_name}' columns: {cols}")
    try:
        df = pd.read_sql(f"SELECT {cols} FROM {table_name}", conn)
        logger.info(f"Read {len(df)} rows from '{table_name}'")
        return df
    except Exception as e:
        logger.error(f"Failed to read table '{table_name}': {e}")
        raise


def write_table(conn: sqlite3.Connection, df: pd.DataFrame, table_name: str) -> None:
    """
    Write a DataFrame to a table in the database.

    Args:
        conn (sqlite3.Connection): SQLite connection object.
        df (pd.DataFrame): DataFrame to write.
        table_name (str): Name of the table to write to.
    """
    logger.info(f"Writing {len(df)} rows to table '{table_name}'")
    try:
        df.to_sql(table_name, conn, if_exists='replace', index=False)
        logger.info(f"Write to '{table_name}' successful")
    except Exception as e:
        logger.error(f"Failed to write to table '{table_name}': {e}")
        raise


def read_calendar(conn: sqlite3.Connection, start_date: str, end_date: str) -> pd.DataFrame:
    """
    Read calendar dates from the database within a specified range.

    Args:
        conn (sqlite3.Connection): SQLite connection object.
        start_date (str): Start date (inclusive).
        end_date (str): End date (inclusive).

    Returns:
        pd.DataFrame: DataFrame containing calendar dates in the range.
    """
    query = """
        SELECT date_id FROM calendar
        WHERE date_id >= ? AND date_id <= ?
        ORDER BY date_id
    """
    logger.info(f"Reading calendar from {start_date} to {end_date}")
    try:
        df = pd.read_sql(query, conn, params=(start_date, end_date))
        logger.info(f"Read {len(df)} calendar rows")
        return df
    except Exception as e:
        logger.error(f"Failed to read calendar: {e}")
        raise
