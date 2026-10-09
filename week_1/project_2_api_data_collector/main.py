"""Main entry point for the API data collection application."""

from api_client import fetch_data
from logger import logger
from storage import save_csv, save_json
from transformer import transform_data
from validator import validate_data


def main():
    """Run the API data collection pipeline."""
    logger.info("Application started")

    try:
        # Step 1: Fetch data
        data = fetch_data()

        # Step 2: Validate data
        validate_data(data)

        # Step 3: Transform data
        transformed_data = transform_data(data)

        # Step 4: Save data
        save_json(transformed_data)
        save_csv(transformed_data)

        logger.info("Application completed successfully")
        print("Data collection completed successfully.")

    except Exception as error:
        logger.exception("Application failed")
        print(f"Error: {error}")


if __name__ == "__main__":
    main()