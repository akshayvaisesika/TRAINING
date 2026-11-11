
"""Initial employee schema.

Revision ID: 518f6c2d4de5
Revises:
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# Revision identifiers, used by Alembic.
revision: str = "518f6c2d4de5"
down_revision: Union[str, Sequence[str], None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Create the employees table."""
    op.create_table(
        "employees",
        sa.Column("id", sa.String(length=20), nullable=False),
        sa.Column("name", sa.String(length=100), nullable=False),
        sa.Column("age", sa.Integer(), nullable=False),
        sa.Column("department", sa.String(length=100), nullable=False),
        sa.Column("role", sa.String(length=100), nullable=False),
        sa.Column("salary", sa.Numeric(precision=12, scale=2), nullable=False),
        sa.Column("email", sa.String(length=255), nullable=False),
        sa.PrimaryKeyConstraint("id", name="employees_pkey"),
    )


def downgrade() -> None:
    """Remove the employees table."""
    op.drop_table("employees")
