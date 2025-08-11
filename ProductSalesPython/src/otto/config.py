"""
Configuration management for the Otto ETL pipeline.
Handles environment variables and default settings.
"""
import os
from pathlib import Path


class Config:
    """Configuration class for Otto ETL pipeline."""

    def __init__(self):
        # Database configuration
        self.database_url: str = os.getenv(
            "DATABASE_URL",
            self._get_default_db_path()
        )

        # Date range configuration
        self.start_date: str = os.getenv("START_DATE", "2025-01-01")
        self.end_date: str = os.getenv("END_DATE", "2025-01-31")

        # Logging configuration
        self.log_level: str = os.getenv("LOG_LEVEL", "INFO")
        self.log_format: str = os.getenv(
            "LOG_FORMAT",
            "%(asctime)s %(levelname)s %(name)s %(message)s"
        )

        # ETL configuration
        self.batch_size: int = int(os.getenv("BATCH_SIZE", "10000"))
        self.enable_pydantic_validation: bool = self._str_to_bool(
            os.getenv("ENABLE_PYDANTIC_VALIDATION", "true")
        )
        self.enable_pandera_validation: bool = self._str_to_bool(
            os.getenv("ENABLE_PANDERA_VALIDATION", "true")
        )

        # Performance configuration
        self.max_retries: int = int(os.getenv("MAX_RETRIES", "3"))
        self.retry_delay: float = float(os.getenv("RETRY_DELAY", "1.0"))

        # Environment
        self.environment: str = os.getenv("ENVIRONMENT", "development")
        self.debug: bool = self._str_to_bool(os.getenv("DEBUG", "false"))

    def _get_default_db_path(self) -> str:
        """Get the default database path relative to project root."""
        # Get project root (3 levels up from src/otto/config.py)
        project_root = Path(__file__).parent.parent.parent
        return str(project_root / "product_sales.db")

    def _str_to_bool(self, value: str) -> bool:
        """Convert string to boolean."""
        return value.lower() in ("true", "1", "yes", "on")

    def is_production(self) -> bool:
        """Check if running in production environment."""
        return self.environment.lower() == "production"

    def is_development(self) -> bool:
        """Check if running in development environment."""
        return self.environment.lower() == "development"

    def validate(self) -> None:
        """Validate configuration settings."""
        # Validate dates
        from datetime import datetime
        try:
            datetime.strptime(self.start_date, "%Y-%m-%d")
            datetime.strptime(self.end_date, "%Y-%m-%d")
        except ValueError as e:
            raise ValueError(f"Invalid date format: {e}")

        # Validate batch size
        if self.batch_size <= 0:
            raise ValueError("BATCH_SIZE must be positive")

        # Validate retry settings
        if self.max_retries < 0:
            raise ValueError("MAX_RETRIES must be non-negative")

        if self.retry_delay < 0:
            raise ValueError("RETRY_DELAY must be non-negative")

    def __repr__(self) -> str:
        """String representation of config (excluding sensitive data)."""
        return (
            f"Config(environment={self.environment}, "
            f"log_level={self.log_level}, "
            f"database_url={'***' if 'password' in self.database_url.lower() else self.database_url}, "
            f"start_date={self.start_date}, "
            f"end_date={self.end_date})"
        )


# Global configuration instance
config = Config()
