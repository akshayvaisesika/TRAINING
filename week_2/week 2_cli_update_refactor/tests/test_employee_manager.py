
import pytest

from employee_management.validators import (
    validate_employee_id,
    validate_name,
    validate_age,
    validate_salary,
    validate_email,
)

import employee_management.employee_manager as employee_manager


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
        "EMP101",
        "Test User 2",
        "25",
        "IT",
        "Data Analyst",
        "50000",
        "test2@example.com",
        "7902858270",
        "2026-10-21",
        "male"
    ])

    monkeypatch.setattr(
        "builtins.input",
        lambda _: next(inputs),
    )

    monkeypatch.setattr(
        employee_manager,
        "get_employee",
        lambda employee_id: None,
    )

    monkeypatch.setattr(
        employee_manager,
        "db_add_employee",
        lambda data: data,
    )

    def fake_refresh(records):
        records[:] = [{
            "id": "EMP101",
            "name": "Test User 2",
            "age": 25,
            "department": "IT",
            "role": "Data Analyst",
            "salary": 50000.0,
            "email": "test2@example.com",
            "phone_number":"7902858270",
            "join_date":"2001-01-01",
            "gender":"male",
        }]

    monkeypatch.setattr(
        employee_manager,
        "refresh_employees",
        fake_refresh,
    )

    employee_manager.add_employee(employees)

    assert len(employees) == 1
    assert employees[0]["id"] == "EMP101"
    assert employees[0]["name"] == "Test User 2"
