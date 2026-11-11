from datetime import date
from decimal import Decimal

from sqlalchemy import Date ,Integer, Numeric, String
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column


class Base(DeclarativeBase):
    """Base class for SQLAlchemy models."""
    pass


class Employee(Base):
    """Employee table model."""

    __tablename__ = "employees"

    id: Mapped[str] = mapped_column(String(20), primary_key=True)
    name: Mapped[str] = mapped_column(String(100), nullable=False)
    age: Mapped[int] = mapped_column(Integer, nullable=False)
    department: Mapped[str] = mapped_column(String(100), nullable=False)
    role: Mapped[str] = mapped_column(String(100), nullable=False)
    salary: Mapped[Decimal] = mapped_column(Numeric(12, 2), nullable=False)
    email: Mapped[str] = mapped_column(String(255), nullable=False)
    phone_number: Mapped[str | None] = mapped_column(String(20),nullable=True,)
    join_date:Mapped[date | None]=mapped_column(Date,nullable=True,)
    gender:Mapped[str | None] = mapped_column(String(20),nullable=True)

    def __repr__(self):
        return (
            f"Employee(id={self.id!r}, name={self.name!r}, "
            f"department={self.department!r}, role={self.role!r})"
        )
