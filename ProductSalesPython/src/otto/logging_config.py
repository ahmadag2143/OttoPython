import logging
from otto.config import config

logging.basicConfig(
    level=getattr(logging, config.log_level.upper()),
    format=config.log_format
)

logger = logging.getLogger("otto")
