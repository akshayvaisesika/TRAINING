from decimal import Decimal
from sqlalchemy import select
from sqlalchemy.orm import Session

from .database import engine
from .models import Employee


def list_employees():
    """Return all employees from PostgreSQL as dictionaries."""
    with Session(engine) as session:
        employees = session.scalars(
            select(Employee).order_by(Employee.id)
        ).all()

        return [employee_to_dict(employee) for employee in employees]


def get_employee(employee_id):
    """Find one employee by employee ID."""
    with Session(engine) as session:
        employee = session.get(Employee, employee_id)

        if employee is None:
            return None

        return employee_to_dict(employee)


def add_employee(data):
    """Add an employee to PostgreSQL."""
    with Session(engine) as session:
        if session.get(Employee, data["id"]) is not None:
            raise ValueError("Employee ID already exists.")

        employee = Employee(
            id=data["id"],
            name=data["name"],
            age=data["age"],
            department=data["department"],
            role=data["role"],
            salary=Decimal(str(data["salary"])),
            email=data["email"],
            phone_number=data.get("phone_number"),
            join_date=data.get("join_date"),
            gender=data.get("gender"),
        )

        session.add(employee)
        session.commit()
        session.refresh(employee)

        return employee_to_dict(employee)


def update_employee(employee_id, updates):
    """Update selected fields for an employee."""
    allowed_fields = {
        "name",
        "age",
        "department",
        "role",
        "salary",
        "email",
        "phone_number",
        "join_date",
        "gender",
    }

    with Session(engine) as session:
        employee = session.get(Employee, employee_id)

        if employee is None:
            return None

        for field, value in updates.items():
            if field not in allowed_fields:
                raise ValueError(f"Cannot update field: {field}")

            if field == "salary":
                value = Decimal(str(value))

            setattr(employee, field, value)

        session.commit()
        session.refresh(employee)

        return employee_to_dict(employee)


def delete_employee(employee_id):
    """Delete an employee. Return True if found."""
    with Session(engine) as session:
        employee = session.get(Employee, employee_id)

        if employee is None:
            return False

        session.delete(employee)
        session.commit()

        return True


def filter_employees(department=None, role=None, age=None):
    """Filter employees by department, role, and age."""
    statement = select(Employee)

    if department:
        statement = statement.where(
            Employee.department.ilike(department)
        )

    if role:
        statement = statement.where(
            Employee.role.ilike(role)
        )

    if age is not None:
        statement = statement.where(Employee.age == age)

    statement = statement.order_by(Employee.id)

    with Session(engine) as session:
        employees = session.scalars(statement).all()
        return [employee_to_dict(employee) for employee in employees]


def employee_to_dict(employee):
    """Convert a SQLAlchemy Employee object to a dictionary."""
    return {
        "id": employee.id,
        "name": employee.name,
        "age": employee.age,
        "department": employee.department,
        "role": employee.role,
        "salary": float(employee.salary),
        "email": employee.email,
        "phone_number": employee.phone_number,
        "join_date": (
            employee.join_date.isoformat()
            if employee.join_date
            else None
            ),
        "gender":employee.gender,
        
        }
        
