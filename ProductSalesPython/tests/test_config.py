import os
import pytest
from unittest.mock import patch
from otto.config import Config


def test_config_defaults():
    """Test that configuration has sensible defaults."""
    config = Config()

    assert config.start_date == "2025-01-01"
    assert config.end_date == "2025-01-31"
    assert config.log_level == "INFO"
    assert config.batch_size == 10000
    assert config.enable_pydantic_validation is True
    assert config.enable_pandera_validation is True
    assert config.max_retries == 3
    assert config.retry_delay == 1.0
    assert config.environment == "development"
    assert config.debug is False


def test_config_environment_variables():
    """Test that configuration reads from environment variables."""
    with patch.dict(os.environ, {
        'LOG_LEVEL': 'DEBUG',
        'START_DATE': '2024-01-01',
        'END_DATE': '2024-12-31',
        'BATCH_SIZE': '5000',
        'ENABLE_PYDANTIC_VALIDATION': 'false',
        'ENVIRONMENT': 'production',
        'DEBUG': 'true'
    }):
        config = Config()

        assert config.log_level == "DEBUG"
        assert config.start_date == "2024-01-01"
        assert config.end_date == "2024-12-31"
        assert config.batch_size == 5000
        assert config.enable_pydantic_validation is False
        assert config.environment == "production"
        assert config.debug is True


def test_config_boolean_conversion():
    """Test boolean conversion from string environment variables."""
    config = Config()

    # Test true values
    assert config._str_to_bool("true") is True
    assert config._str_to_bool("True") is True
    assert config._str_to_bool("1") is True
    assert config._str_to_bool("yes") is True
    assert config._str_to_bool("on") is True

    # Test false values
    assert config._str_to_bool("false") is False
    assert config._str_to_bool("False") is False
    assert config._str_to_bool("0") is False
    assert config._str_to_bool("no") is False
    assert config._str_to_bool("off") is False


def test_config_environment_methods():
    """Test environment detection methods."""
    with patch.dict(os.environ, {'ENVIRONMENT': 'production'}):
        config = Config()
        assert config.is_production() is True
        assert config.is_development() is False

    with patch.dict(os.environ, {'ENVIRONMENT': 'development'}):
        config = Config()
        assert config.is_production() is False
        assert config.is_development() is True


def test_config_validation():
    """Test configuration validation."""
    config = Config()

    # Valid configuration should not raise
    config.validate()

    # Test invalid date format
    config.start_date = "invalid-date"
    with pytest.raises(ValueError, match="Invalid date format"):
        config.validate()

    # Reset and test invalid batch size
    config.start_date = "2025-01-01"
    config.batch_size = -1
    with pytest.raises(ValueError, match="BATCH_SIZE must be positive"):
        config.validate()

    # Reset and test invalid max retries
    config.batch_size = 1000
    config.max_retries = -1
    with pytest.raises(ValueError, match="MAX_RETRIES must be non-negative"):
        config.validate()


def test_config_repr():
    """Test configuration string representation."""
    config = Config()
    repr_str = repr(config)

    assert "Config(" in repr_str
    assert "environment=development" in repr_str
    assert "log_level=INFO" in repr_str
    assert "start_date=2025-01-01" in repr_str


def test_config_sensitive_data_masking():
    """Test that sensitive data is masked in repr."""
    with patch.dict(os.environ, {'DATABASE_URL': 'postgres://user:password@host/db'}):
        config = Config()
        repr_str = repr(config)
        assert "***" in repr_str  # Password should be masked
