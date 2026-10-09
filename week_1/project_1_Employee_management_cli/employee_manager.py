"""Manage employee records using JSON file storage."""

import json
import os

from validators import (
    validate_age,
    validate_email,
    validate_employee_id,
    validate_name,
    validate_salary,
)
from logger import logger


DATA_FILE = "data/employees.json"


def load_employees():
    """Load employee records from the JSON file.

    Returns:
        list: Employee records loaded from the file.
    """
    try:
        if not os.path.exists(DATA_FILE):
            return []

        with open(DATA_FILE, "r", encoding="utf-8") as file:
            employees = json.load(file)

        logger.info("Employee data loaded successfully.")
        return employees

    except json.JSONDecodeError:
        logger.error("Employee JSON file contains invalid data.")
        print("Error: Employee data file is corrupted.")
        return []

    except OSError as error:
        logger.error("Error reading employee data: %s", error)
        print("Error: Unable to read employee data.")
        return []


def save_employees(employees):
    """Save employee records to the JSON file.

    Args:
        employees (list): List of employee records to save.
    """
    try:
        with open(DATA_FILE, "w", encoding="utf-8") as file:
            json.dump(employees, file, indent=4)

        logger.info("Employee data saved successfully.")

    except OSError as error:
        logger.error("Error saving employee data: %s", error)
        print("Error: Unable to save employee data.")


def add_employee(employees):
    """Validate and add a new employee.

    Args:
        employees (list): List of existing employee records.
    """
    # Employee ID validation
    while True:
        try:
            emp_id = validate_employee_id(
                input("Enter employee ID: ")
            )

            duplicate = False

            for employee in employees:
                if employee["id"] == emp_id:
                    duplicate = True
                    break

            if duplicate:
                print("Error: Employee ID already exists.")
                logger.warning(
                    "Duplicate employee ID attempted: %s",
                    emp_id,
                )
                continue

            break

        except ValueError as error:
            print(f"Invalid employee ID: {error}")

    # Employee name
    name = validate_name(input("Enter employee name: "))

    # Age validation
    while True:
        try:
            age = validate_age(input("Enter employee age: "))
            break
        except ValueError as error:
            print(f"Invalid age: {error}")

    # Department
    department = input("Enter department: ").strip()

    # Role
    role = input("Enter role: ").strip()

    # Salary validation
    while True:
        try:
            salary = validate_salary(input("Enter salary: "))
            break
        except ValueError as error:
            print(f"Invalid salary: {error}")

    # Email validation
    while True:
        try:
            email = validate_email(input("Enter email: "))
            break
        except ValueError as error:
            print(f"Invalid email: {error}")

    # Create employee
    employee = {
        "id": emp_id,
        "name": name,
        "age": age,
        "department": department,
        "role": role,
        "salary": salary,
        "email": email,
    }

    employees.append(employee)

    save_employees(employees)
    logger.info("Employee %s added successfully.", emp_id)
    print("Employee added successfully.")


def search_employee(employees):
    """Search for an employee using their employee ID.

    Args:
        employees (list): Employee records to search.

    Returns:
        dict | None: The employee record if found, otherwise None.
    """
    try:
        emp_id = validate_employee_id(
            input("Enter employee ID to search: ")
        )

        for employee in employees:
            if employee["id"] == emp_id:
                print("\nEmployee Found")
                print("-" * 30)

                for key, value in employee.items():
                    print(f"{key.capitalize()}: {value}")

                logger.info(
                    "Employee %s searched successfully.",
                    emp_id,
                )
                return employee

        print("Employee not found.")
        logger.warning(
            "Employee %s not found during search.",
            emp_id,
        )
        return None

    except ValueError as error:
        print(f"Invalid input: {error}")
        logger.error("Invalid search input: %s", error)
        return None


def update_employee(employees):
    """Update an existing employee's information.

    Args:
        employees (list): Employee records to update.

    Returns:
        dict | None: Updated employee record or None if not found
        or the input is invalid.
    """
    try:
        emp_id = validate_employee_id(
            input("Enter employee ID to update: ")
        )

        for employee in employees:
            if employee["id"] == emp_id:
                print("\nEmployee found.")
                print("Press Enter to keep the existing value.\n")

                name = input(
                    f"Name [{employee['name']}]: "
                ).strip()

                age = input(
                    f"Age [{employee['age']}]: "
                ).strip()

                department = input(
                    f"Department [{employee['department']}]: "
                ).strip()

                role = input(
                    f"Role [{employee['role']}]: "
                ).strip()

                salary = input(
                    f"Salary [{employee['salary']}]: "
                ).strip()

                email = input(
                    f"Email [{employee['email']}]: "
                ).strip()

                if name:
                    employee["name"] = validate_name(name)

                if age:
                    employee["age"] = validate_age(age)

                if department:
                    employee["department"] = department

                if role:
                    employee["role"] = role

                if salary:
                    employee["salary"] = validate_salary(salary)

                if email:
                    employee["email"] = validate_email(email)

                save_employees(employees)

                logger.info(
                    "Employee %s updated successfully.",
                    emp_id,
                )
                print("Employee updated successfully.")
                return employee

        print("Employee not found.")
        logger.warning(
            "Employee %s not found during update.",
            emp_id,
        )
        return None

    except ValueError as error:
        print(f"Invalid input: {error}")
        logger.error("Invalid update input: %s", error)
        return None


def delete_employee(employees):
    """Delete an employee using their employee ID.

    Args:
        employees (list): Employee records to search and modify.
    """
    try:
        emp_id = validate_employee_id(
            input("Enter employee ID to delete: ")
        )

        for employee in employees:
            if employee["id"] == emp_id:
                employees.remove(employee)
                save_employees(employees)

                logger.info(
                    "Employee %s deleted successfully.",
                    emp_id,
                )
                print("Employee deleted successfully.")
                return

        print("Employee not found.")
        logger.warning(
            "Employee %s not found during deletion.",
            emp_id,
        )

    except ValueError as error:
        print(f"Invalid input: {error}")
        logger.error("Invalid delete input: %s", error)


def filter_employees(employees):
    """Filter employees by department, role, and age.

    Args:
        employees (list): Employee records to filter.

    Returns:
        list: Employee records matching the supplied filters.
    """
    department = input(
        "Enter department (leave blank to ignore): "
    ).strip().lower()

    role = input(
        "Enter role (leave blank to ignore): "
    ).strip().lower()

    age_input = input(
        "Enter age (leave blank to ignore): "
    ).strip()

    try:
        age = int(age_input) if age_input else None
        results = []

        for employee in employees:
            department_match = (
                not department
                or employee["department"].lower() == department
            )

            role_match = (
                not role
                or employee["role"].lower() == role
            )

            age_match = (
                age is None
                or employee["age"] == age
            )

            if (
                department_match
                and role_match
                and age_match
            ):
                results.append(employee)

        if not results:
            print("No matching employees found.")
            logger.warning(
                "Employee filter returned no results."
            )
            return []

        print("\nMatching Employees")
        print("-" * 30)

        for employee in results:
            print(employee)

        logger.info(
            "Employee filter returned %d result(s).",
            len(results),
        )
        return results

    except ValueError:
        print("Invalid age. Please enter a valid number.")
        logger.error(
            "Invalid age entered during employee filtering."
        )
        return []


def view_all_employees(employees):
    """Display all employee records.

    Args:
        employees (list): Employee records to display.
    """
    if not employees:
        print("\nNo employees available.")
        return

    print("\n" + "=" * 80)
    print("                         ALL EMPLOYEES")
    print("=" * 80)

    for employee in employees:
        print(f"ID         : {employee['id']}")
        print(f"Name       : {employee['name']}")
        print(f"Age        : {employee['age']}")
        print(f"Department : {employee['department']}")
        print(f"Role       : {employee['role']}")
        print(f"Salary     : {employee['salary']}")
        print(f"Email      : {employee['email']}")
        print("-" * 80)

    logger.info(
        "Displayed %d employee record(s).",
        len(employees),
    )