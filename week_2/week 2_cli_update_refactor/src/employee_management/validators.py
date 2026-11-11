"""Provide validation functions for employee records."""


def validate_employee_id(emp_id):
    """Validate and normalize an employee ID.

    Args:
        emp_id (str): Employee ID to validate.

    Returns:
        str: Employee ID stripped of whitespace and converted
        to uppercase.

    Raises:
        ValueError: If the employee ID is empty.
    """
    if not emp_id.strip():
        raise ValueError("Employee ID cannot be empty")

    return emp_id.strip().upper()


def validate_name(name):
    """Validate an employee's name.

    Args:
        name (str): Employee name to validate.

    Returns:
        str: Employee name stripped of surrounding whitespace.

    Raises:
        ValueError: If the employee name is empty.
    """
    if not name.strip():
        raise ValueError("Employee name cannot be empty")

    return name.strip()


def validate_age(emp_age):
    """Validate an employee's age.

    Args:
        emp_age (int | str): Employee age to validate.

    Returns:
        int: Validated employee age.

    Raises:
        ValueError: If the age is not an integer or is outside
        the permitted range of 18 to 60.
    """
    emp_age = int(emp_age)

    if emp_age < 18 or emp_age > 60:
        raise ValueError("Age must be between 18 and 60")

    return emp_age


def validate_salary(emp_salary):
    """Validate an employee's salary.

    Args:
        emp_salary (int | float | str): Salary to validate.

    Returns:
        float: Validated salary.

    Raises:
        ValueError: If the salary is invalid or negative.
    """
    salary = float(emp_salary)

    if salary < 0:
        raise ValueError("Salary cannot be negative")

    return salary


def validate_email(email):
    """Perform basic validation of an email address.

    Args:
        email (str): Email address to validate.

    Returns:
        str: Email address stripped of surrounding whitespace.

    Raises:
        ValueError: If the email lacks an '@' or a period.
    """
    email = email.strip()

    if "@" not in email or "." not in email:
        raise ValueError("Please enter a valid email address")

    return email
