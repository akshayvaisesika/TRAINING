
"""Tests for the API client."""

import pytest
import requests

from api_client import fetch_data


class FakeResponse:
    """Simulate a successful API response."""

    def raise_for_status(self):
        pass

    def json(self):
        return [
            {
                "id": 1,
                "name": "Leanne Graham",
                "email": "test@example.com",
            }
        ]


def test_fetch_data_success(monkeypatch):
    """Test that API data is fetched successfully."""

    def fake_get(url, timeout):
        assert url == "https://jsonplaceholder.typicode.com/users"
        assert timeout == 10
        return FakeResponse()

    monkeypatch.setattr("api_client.requests.get", fake_get)

    result = fetch_data()

    assert len(result) == 1
    assert result[0]["id"] == 1
    assert result[0]["name"] == "Leanne Graham"


def test_fetch_data_timeout(monkeypatch):
    """Test that a timeout error is handled and re-raised."""

    def fake_get(*args, **kwargs):
        raise requests.exceptions.Timeout("Request timed out")

    monkeypatch.setattr("api_client.requests.get", fake_get)

    with pytest.raises(requests.exceptions.Timeout):
        fetch_data()


def test_fetch_data_connection_error(monkeypatch):
    """Test that a connection error is handled and re-raised."""

    def fake_get(*args, **kwargs):
        raise requests.exceptions.ConnectionError("Connection failed")

    monkeypatch.setattr("api_client.requests.get", fake_get)

    with pytest.raises(requests.exceptions.ConnectionError):
        fetch_data()


def test_fetch_data_http_error(monkeypatch):
    """Test that HTTP errors are handled and re-raised."""

    class ErrorResponse:
        def raise_for_status(self):
            raise requests.exceptions.HTTPError("404 Not Found")

    monkeypatch.setattr(
        "api_client.requests.get",
        lambda *args, **kwargs: ErrorResponse(),
    )

    with pytest.raises(requests.exceptions.HTTPError):
        fetch_data()
