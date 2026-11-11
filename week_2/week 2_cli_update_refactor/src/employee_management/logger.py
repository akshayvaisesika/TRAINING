"""Configure application logging for the Employee Management System."""

import logging
import os


# Create the logs directory if it does not exist
os.makedirs("logs", exist_ok=True)


# Configure logging settings
logging.basicConfig(
    filename="logs/app.log",
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s",
)


# Create the application logger
logger = logging.getLogger(__name__)
