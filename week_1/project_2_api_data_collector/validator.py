"""Validate API response data before processing."""

from logger import logger


REQUIRED_FIELDS = ["id", "name", "email"]


def validate_data(data):
    """Validate the structure of API response data.

    Args:
        data: A list of dictionaries containing user information.

    Returns:
        True if the data passes validation.

    Raises:
        ValueError: If the response is empty, has an invalid
            structure, or is missing required fields.
    """
    if not isinstance(data, list):
        raise ValueError("API response must be a list")

    if not data:
        raise ValueError("API response is empty")

    for index, item in enumerate(data):
        if not isinstance(item, dict):
            raise ValueError(
                f"Item at index {index} is not a dictionary"
            )

        for field in REQUIRED_FIELDS:
            if field not in item:
                raise ValueError(
                    f"Missing required field '{field}' "
                    f"at index {index}"
                )

    logger.info("Data validation successful")

    return True
