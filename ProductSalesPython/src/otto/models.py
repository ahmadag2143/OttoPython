
from pydantic import BaseModel, Field, field_validator
from datetime import date
from otto.logging_config import logger


class Product(BaseModel):
    sku_id: int
    # sku_description: str
    price: float = Field(..., gt=0)

    @field_validator("sku_id")
    @classmethod
    def sku_id_must_be_positive(cls, v):
        if v <= 0:
            logger.error("sku_id must be positive")
            raise ValueError("sku_id must be positive")
        return v


class SalesRecord(BaseModel):
    sku_id: int
    order_id: str
    sales: int = Field(..., ge=0)
    orderdate_utc: str

    @field_validator("order_id")
    @classmethod
    def order_id_not_empty(cls, v):
        if not v.strip():
            logger.error("order_id must not be empty")
            raise ValueError("order_id must not be empty")
        return v

    @field_validator("sku_id")
    @classmethod
    def sku_id_must_be_positive(cls, v):
        if v <= 0:
            logger.error("sku_id must be positive")
            raise ValueError("sku_id must be positive")
        return v


class RevenueRow(BaseModel):
    sku_id: int
    date_id: date
    price: float = Field(..., ge=0)
    sales: int = Field(..., ge=0)
    revenue: float = Field(..., ge=0)

    @field_validator("sku_id")
    @classmethod
    def sku_id_must_be_positive(cls, v):
        if v <= 0:
            logger.error("sku_id must be positive")
            raise ValueError("sku_id must be positive")
        return v

