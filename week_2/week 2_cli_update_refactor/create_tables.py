
"""Create database tables from SQLAlchemy models."""

from employee_management.database import engine
from employee_management.models import Base


def create_tables():
    """Create tables that do not already exist."""
    Base.metadata.create_all(bind=engine)
    print("Database tables created successfully!")


if __name__ == "__main__":
    create_tables()
