
"""Add employee phone number.

Revision ID: aa001b09f570
Revises: 518f6c2d4de5
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# Revision identifiers, used by Alembic.
revision: str = "aa001b09f570"
down_revision: Union[str, Sequence[str], None] = "518f6c2d4de5"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Add an optional phone number to employees."""
    op.add_column(
        "employees",
        sa.Column("phone_number", sa.String(length=20), nullable=True),
    )


def downgrade() -> None:
    """Remove the phone number column."""
    op.drop_column("employees", "phone_number")
