
"""Import employee records from JSON into PostgreSQL."""

import json
from decimal import Decimal
from pathlib import Path

from sqlalchemy.orm import Session

from employee_management.database import engine
from employee_management.models import Employee


JSON_FILE = Path(__file__).parent / "data" / "employees.json"


def import_employees():
    """Import employees while skipping IDs already in the database."""
    # Read the existing JSON data.
    with JSON_FILE.open("r", encoding="utf-8") as file:
        employees_data = json.load(file)

    if not isinstance(employees_data, list):
        raise ValueError(
            "Expected the JSON file to contain a list of employees."
        )

    imported_count = 0
    skipped_count = 0

    with Session(engine) as session:
        for item in employees_data:
            if not isinstance(item, dict):
                raise ValueError(
                    "Each employee record must be a JSON object."
                )

            required_fields = {
                "id",
                "name",
                "age",
                "department",
                "role",
                "salary",
                "email",
            }

            missing_fields = required_fields - item.keys()

            if missing_fields:
                raise ValueError(
                    "Employee record is missing fields: "
                    f"{sorted(missing_fields)}"
                )

            employee_id = str(item["id"]).strip()

            # Avoid inserting the same employee ID twice.
            existing_employee = session.get(Employee, employee_id)

            if existing_employee:
                skipped_count += 1
                continue

            employee = Employee(
                id=employee_id,
                name=str(item["name"]).strip(),
                age=int(item["age"]),
                department=str(item["department"]).strip(),
                role=str(item["role"]).strip(),
                salary=Decimal(str(item["salary"])),
                email=str(item["email"]).strip(),
            )

            session.add(employee)
            imported_count += 1

        session.commit()

    print(f"Import completed. Imported: {imported_count}")
    print(f"Skipped existing employees: {skipped_count}")


if __name__ == "__main__":
    import_employees()
