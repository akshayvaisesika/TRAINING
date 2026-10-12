
"""Tests for JSON and CSV storage."""

import csv
import json

from storage import save_csv, save_json


def test_save_json(tmp_path, monkeypatch):
    monkeypatch.setattr("storage.OUTPUT_DIR", str(tmp_path))

    data = [{"id": 1, "name": "AKSHAY", "email": "akshay@example.com"}]

    save_json(data)

    file_path = tmp_path / "users.json"
    assert file_path.exists()

    with open(file_path, encoding="utf-8") as file:
        saved_data = json.load(file)

    assert saved_data == data


def test_save_csv(tmp_path, monkeypatch):
    monkeypatch.setattr("storage.OUTPUT_DIR", str(tmp_path))

    data = [{"id": 1, "name": "AKSHAY", "email": "akshay@example.com"}]

    save_csv(data)

    file_path = tmp_path / "users.csv"
    assert file_path.exists()

    with open(file_path, newline="", encoding="utf-8") as file:
        saved_data = list(csv.DictReader(file))

    assert saved_data == [
        {"id": "1", "name": "AKSHAY", "email": "akshay@example.com"}
    ]
