
"""Configure Alembic for the Employee Management project."""

from logging.config import fileConfig

from alembic import context

from employee_management.database import engine
from employee_management.models import Base


# Access Alembic's configuration.
config = context.config

# Configure logging using alembic.ini.
if config.config_file_name is not None:
    fileConfig(config.config_file_name)

# Tell Alembic about our SQLAlchemy models.
# Alembic uses this metadata to detect database schema changes.
target_metadata = Base.metadata


def run_migrations_offline() -> None:
    """Generate migration SQL without opening a database connection."""

    context.configure(
        url=engine.url,
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
        compare_type=True,
    )

    with context.begin_transaction():
        context.run_migrations()


def run_migrations_online() -> None:
    """Run migrations using a live database connection."""

    with engine.connect() as connection:
        context.configure(
            connection=connection,
            target_metadata=target_metadata,
            compare_type=True,
        )

        with context.begin_transaction():
            context.run_migrations()


if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()