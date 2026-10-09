"""Transform user data into a standardized format."""

from logger import logger


def transform_data(data):
    """Normalize user names and email addresses.

    Args:
        data: A list of dictionaries containing user information.

    Returns:
        A list of dictionaries with IDs, uppercase names,
        and lowercase email addresses.
    """
    transformed_data = []

    for item in data:
        transformed_item = {
            "id": item["id"],
            "name": item["name"].upper(),
            "email": item["email"].lower(),
        }

        transformed_data.append(transformed_item)

    logger.info("Data transformation successful")

    return transformed_data