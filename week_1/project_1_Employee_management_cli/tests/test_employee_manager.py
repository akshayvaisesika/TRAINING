import pytest

from validators import (
    validate_employee_id,
    validate_name,
    validate_age,
    validate_salary,
    validate_email
)


from employee_manager import add_employee

def test_validate_employee_id():
    assert validate_employee_id("emp001") == "EMP001"

def test_validate_name():
    assert validate_name(" Akshay ") == "Akshay"

def test_validate_age():
    assert validate_age("25") == 25

def test_validate_salary():
    assert validate_salary("45000") == 45000.0

def test_validate_email():
    assert validate_email("akshay@gmail.com") == "akshay@gmail.com"


def test_add_employee(monkeypatch):

    employees = []

    inputs = iter([
        "EMP100",
        "Test User",
        "25",
        "IT",
        "Data Analyst",
        "50000",
        "test@example.com"
    ])

    monkeypatch.setattr("builtins.input",lambda _: next(inputs))

    add_employee(employees)

    assert len(employees) == 1
    assert employees[0]["id"] == "EMP100"
    assert employees[0]["name"] == "Test User"