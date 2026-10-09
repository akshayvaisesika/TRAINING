"""Fetch user data from an external API."""

import requests

from logger import logger


API_URL = "https://jsonplaceholder.typicode.com/users"


def fetch_data():
    """Fetch user data from the API and handle request errors."""
    try:
        logger.info("Starting API request")

        response = requests.get(API_URL, timeout=10)
        response.raise_for_status()

        logger.info("API request successful")

        return response.json()

    except requests.exceptions.Timeout:
        logger.error("API request timed out")
        raise

    except requests.exceptions.ConnectionError:
        logger.error("Unable to connect to API")
        raise

    except requests.exceptions.HTTPError as error:
        logger.error("HTTP error occurred: %s", error)
        raise

    except requests.exceptions.RequestException as error:
        logger.error("Request failed: %s", error)
        raise

    except ValueError:
        logger.error("API returned invalid JSON")
        raise