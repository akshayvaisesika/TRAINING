
"""Tests for API response validation."""

import pytest

from validator import validate_data


def test_valid_data():
    data = [
        {"id": 1, "name": "Leanne Graham", "email": "test@example.com"}
    ]

    assert validate_data(data) is True


def test_empty_data():
    with pytest.raises(ValueError, match="API response is empty"):
        validate_data([])


def test_response_is_not_a_list():
    with pytest.raises(ValueError, match="API response must be a list"):
        validate_data({"id": 1, "name": "Test", "email": "test@example.com"})


def test_item_is_not_a_dictionary():
    with pytest.raises(ValueError, match="not a dictionary"):
        validate_data(["invalid item"])


def test_missing_required_field():
    data = [{"id": 1, "name": "Leanne Graham"}]

    with pytest.raises(ValueError, match="Missing required field 'email'"):
        validate_data(data)
