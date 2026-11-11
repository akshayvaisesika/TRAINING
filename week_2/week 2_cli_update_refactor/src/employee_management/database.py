
import os

from dotenv import load_dotenv
from sqlalchemy import URL, create_engine, text
from sqlalchemy.exc import SQLAlchemyError

# Load settings from the .env file.
load_dotenv()

# Read database settings from environment variables.
database_url = URL.create(
    drivername="postgresql+psycopg",
    username=os.getenv("DB_USER"),
    password=os.getenv("DB_PASSWORD"),
    host=os.getenv("DB_HOST", "localhost"),
    port=int(os.getenv("DB_PORT", "5432")),
    database=os.getenv("DB_NAME"),
)

# Create the SQLAlchemy engine.
engine = create_engine(database_url)


def test_connection():
    """Check whether Python can connect to PostgreSQL."""
    try:
        with engine.connect() as connection:
            result = connection.execute(text("SELECT version()"))
            print("PostgreSQL connection successful!")
            print(result.scalar())

    except SQLAlchemyError as error:
        print("Could not connect to PostgreSQL.")
        print(f"Error: {error.__class__.__name__}")
        print("Check your .env settings and PostgreSQL credentials.")


if __name__ == "__main__":
    test_connection()
