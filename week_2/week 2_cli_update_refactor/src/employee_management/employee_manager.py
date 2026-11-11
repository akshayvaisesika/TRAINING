"""Manage employee records using PostgreSQL."""

from datetime import date

from sqlalchemy.exc import SQLAlchemyError

from .employee_service import (
    add_employee as db_add_employee,
    delete_employee as db_delete_employee,
    filter_employees as db_filter_employees,
    get_employee,
    list_employees,
    update_employee as db_update_employee,
)
from .validators import (
    validate_age,
    validate_email,
    validate_employee_id,
    validate_name,
    validate_salary,
)
from .logger import logger


def refresh_employees(employees):
    """Refresh the existing list from PostgreSQL."""
    employees[:] = list_employees()
    return employees


def load_employees():
    """Load employees from PostgreSQL."""
    try:
        employees = list_employees()
        logger.info("Employee data loaded from PostgreSQL.")
        return employees
    except SQLAlchemyError:
        logger.exception("Unable to load employees from PostgreSQL.")
        print("Error: Unable to load employee data from PostgreSQL.")
        return []


def add_employee(employees):
    """Validate and add a new employee to PostgreSQL."""
    try:
        emp_id = validate_employee_id(input("Enter employee ID: "))

        if get_employee(emp_id):
            print("Error: Employee ID already exists.")
            logger.warning("Duplicate employee ID attempted: %s", emp_id)
            return

        name = validate_name(input("Enter employee name: "))

        while True:
            try:
                age = validate_age(input("Enter employee age: "))
                break
            except ValueError as error:
                print(f"Invalid age: {error}")

        department = input("Enter department: ").strip()
        role = input("Enter role: ").strip()

        while True:
            try:
                salary = validate_salary(input("Enter salary: "))
                break
            except ValueError as error:
                print(f"Invalid salary: {error}")

        while True:
            try:
                email = validate_email(input("Enter email: "))
                break
            except ValueError as error:
                print(f"Invalid email: {error}")

        phone_number = input(
            "Enter phone number (optional): "
        ).strip() or None

        join_date_input = input(
            "Enter joining date (YYYY-MM-DD, optional): "
        ).strip()

        if join_date_input:
            try:
                join_date = date.fromisoformat(join_date_input)
            except ValueError:
                print("Invalid date. Use YYYY-MM-DD format.")
                return
        else:
            join_date = None
        gender = input("Enter gender (optional): ").strip() or None

        data = {
            "id": emp_id,
            "name": name,
            "age": age,
            "department": department,
            "role": role,
            "salary": salary,
            "email": email,
            "phone_number": phone_number,
            "join_date": join_date,
            "gender":gender,
        }

        db_add_employee(data)
        refresh_employees(employees)

        logger.info("Employee %s added successfully.", emp_id)
        print("Employee added successfully.")

    except ValueError as error:
        print(f"Invalid input: {error}")
    except SQLAlchemyError:
        logger.exception("Failed to add employee.")
        print("Error: Unable to save the employee to PostgreSQL.")


def search_employee(employees):
    """Search for an employee by ID in PostgreSQL."""
    try:
        emp_id = validate_employee_id(
            input("Enter employee ID to search: ")
        )
        employee = get_employee(emp_id)

        if employee is None:
            print("Employee not found.")
            logger.warning("Employee %s not found.", emp_id)
            return None

        print("\nEmployee Found")
        print("-" * 30)

        for key, value in employee.items():
            print(f"{key.replace('_', ' ').title()}: {value}")

        logger.info("Employee %s searched successfully.", emp_id)
        return employee

    except ValueError as error:
        print(f"Invalid input: {error}")
        return None
    except SQLAlchemyError:
        logger.exception("Employee search failed.")
        print("Error: Unable to search PostgreSQL.")
        return None


def update_employee(employees):
    """Update an existing employee in PostgreSQL."""
    try:
        emp_id = validate_employee_id(
            input("Enter employee ID to update: ")
        )
        employee = get_employee(emp_id)

        if employee is None:
            print("Employee not found.")
            return None

        print("\nEmployee found.")
        print("Press Enter to keep the existing value.\n")

        updates = {}

        name = input(f"Name [{employee['name']}]: ").strip()
        age = input(f"Age [{employee['age']}]: ").strip()
        department = input(
            f"Department [{employee['department']}]: "
        ).strip()
        role = input(f"Role [{employee['role']}]: ").strip()
        salary = input(f"Salary [{employee['salary']}]: ").strip()
        email = input(f"Email [{employee['email']}]: ").strip()
        phone_number = input(
            f"Phone number [{employee.get('phone_number') or ''}]: "
        ).strip()
        join_date_input = input(
            f"Joining date [{employee.get('join_date') or ''}] "
            "(YYYY-MM-DD): "
        ).strip()
        gender=input(f"gender[{employee.get('gender')or ''}]: ").strip()

        if name:
            updates["name"] = validate_name(name)

        if age:
            updates["age"] = validate_age(age)

        if department:
            updates["department"] = department

        if role:
            updates["role"] = role

        if salary:
            updates["salary"] = validate_salary(salary)

        if email:
            updates["email"] = validate_email(email)

        if phone_number:
            updates["phone_number"] = phone_number

        if join_date_input:
            try:
                updates["join_date"] = date.fromisoformat(
                    join_date_input
                )
            except ValueError:
                print("Invalid date. Use YYYY-MM-DD format.")
                return None
        if gender:
            updates["gender"] = gender
        

        updated = db_update_employee(emp_id, updates)
        refresh_employees(employees)

        if updated is not None:
            logger.info("Employee %s updated successfully.", emp_id)
            print("Employee updated successfully.")

        return updated

    except ValueError as error:
        print(f"Invalid input: {error}")
        return None
    except SQLAlchemyError:
        logger.exception("Employee update failed.")
        print("Error: Unable to update the employee in PostgreSQL.")
        return None


def delete_employee(employees):
    """Delete an employee from PostgreSQL."""
    try:
        emp_id = validate_employee_id(
            input("Enter employee ID to delete: ")
        )

        if not db_delete_employee(emp_id):
            print("Employee not found.")
            return

        refresh_employees(employees)
        logger.info("Employee %s deleted successfully.", emp_id)
        print("Employee deleted successfully.")

    except ValueError as error:
        print(f"Invalid input: {error}")
    except SQLAlchemyError:
        logger.exception("Employee deletion failed.")
        print("Error: Unable to delete the employee from PostgreSQL.")


def filter_employees(employees):
    """Filter employees using PostgreSQL."""
    department = input(
        "Enter department (leave blank to ignore): "
    ).strip()
    role = input(
        "Enter role (leave blank to ignore): "
    ).strip()
    age_input = input(
        "Enter age (leave blank to ignore): "
    ).strip()

    try:
        age = int(age_input) if age_input else None

        if age is not None and not 18 <= age <= 60:
            print("Invalid age. Enter an age between 18 and 60.")
            return []

        results = db_filter_employees(
            department=department or None,
            role=role or None,
            age=age,
        )

        if not results:
            print("No matching employees found.")
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
        return []
    except SQLAlchemyError:
        logger.exception("Employee filtering failed.")
        print("Error: Unable to filter employees in PostgreSQL.")
        return []


def view_all_employees(employees):
    """Display all employees stored in PostgreSQL."""
    try:
        refresh_employees(employees)

        if not employees:
            print("\nNo employees available.")
            return

        print("\n" + "=" * 80)
        print("                         ALL EMPLOYEES")
        print("=" * 80)

        for employee in employees:
            print(f"ID           : {employee['id']}")
            print(f"Name         : {employee['name']}")
            print(f"Age          : {employee['age']}")
            print(f"Department   : {employee['department']}")
            print(f"Role         : {employee['role']}")
            print(f"Salary       : {employee['salary']:.2f}")
            print(f"Email        : {employee['email']}")
            print(
                f"Phone Number : "
                f"{employee.get('phone_number') or 'Not provided'}"
            )
            print(
                f"Joining Date : "
                f"{employee.get('join_date') or 'Not provided'}"
            )
            print(f"Gender : {employee['gender']}")
            print("-" * 80)

        logger.info(
            "Displayed %d employee record(s).",
            len(employees),
        )

    except SQLAlchemyError:
        logger.exception("Unable to display employees.")
        print("Error: Unable to retrieve employees from PostgreSQL.")