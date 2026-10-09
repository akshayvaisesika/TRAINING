"""Save transformed user data to JSON and CSV files."""

import csv
import json
import os

from logger import logger


OUTPUT_DIR = "output"


def save_json(data):
    """Save user data to a JSON file."""
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    file_path = os.path.join(OUTPUT_DIR, "users.json")

    with open(file_path, "w", encoding="utf-8") as file:
        json.dump(data, file, indent=4)

    logger.info("JSON file saved: %s", file_path)


def save_csv(data):
    """Save user data to a CSV file."""
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    file_path = os.path.join(OUTPUT_DIR, "users.csv")

    fieldnames = ["id", "name", "email"]

    with open(
        file_path,
        "w",
        newline="",
        encoding="utf-8",
    ) as file:
        writer = csv.DictWriter(
            file,
            fieldnames=fieldnames,
        )

        writer.writeheader()
        writer.writerows(data)

    logger.info("CSV file saved: %s", file_path)
