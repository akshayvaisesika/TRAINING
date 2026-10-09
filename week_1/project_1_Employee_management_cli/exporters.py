"""Export employee records to JSON and CSV files."""

import csv
import json
import os

from logger import logger


EXPORT_DIR = "exports"

JSON_EXPORT_FILE = os.path.join(
    EXPORT_DIR,
    "employees.json",
)

CSV_EXPORT_FILE = os.path.join(
    EXPORT_DIR,
    "employees.csv",
)


def export_to_json(employees):
    """Export employee records to a JSON file.

    Args:
        employees (list): Employee records to export.

    Returns:
        bool: True if the export succeeds, otherwise False.
    """
    try:
        if not employees:
            print("No employee data available to export.")
            logger.warning(
                "JSON export attempted with no employee data."
            )
            return False

        os.makedirs(EXPORT_DIR, exist_ok=True)

        with open(
            JSON_EXPORT_FILE,
            "w",
            encoding="utf-8",
        ) as file:
            json.dump(employees, file, indent=4)

        print(f"Employee data exported to {JSON_EXPORT_FILE}")
        logger.info(
            "Employee data exported successfully to JSON."
        )
        return True

    except OSError as error:
        print("Error: Unable to export employee data to JSON.")
        logger.error("JSON export failed: %s", error)
        return False


def export_to_csv(employees):
    """Export employee records to a CSV file.

    Args:
        employees (list): Employee records to export.

    Returns:
        bool: True if the export succeeds, otherwise False.
    """
    try:
        if not employees:
            print("No employee data available to export.")
            logger.warning(
                "CSV export attempted with no employee data."
            )
            return False

        os.makedirs(EXPORT_DIR, exist_ok=True)

        fieldnames = [
            "id",
            "name",
            "age",
            "department",
            "role",
            "salary",
            "email",
        ]

        with open(
            CSV_EXPORT_FILE,
            "w",
            newline="",
            encoding="utf-8",
        ) as file:
            writer = csv.DictWriter(
                file,
                fieldnames=fieldnames,
            )
            writer.writeheader()
            writer.writerows(employees)

        print(f"Employee data exported to {CSV_EXPORT_FILE}")
        logger.info(
            "Employee data exported successfully to CSV."
        )
        return True

    except OSError as error:
        print("Error: Unable to export employee data to CSV.")
        logger.error("CSV export failed: %s", error)
        return False
