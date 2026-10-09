# Employee Data Management CLI

A command-line application developed using Python to manage employee records. The application supports employee CRUD operations, search and filtering, data export, input validation, exception handling, application logging, and automated testing.

## Features

* Add new employees
* Update employee information
* Delete employees
* Search employees by ID
* Filter employees by department, role, and age
* View all employee records
* Export employee data to JSON
* Export employee data to CSV
* Input validation
* Exception handling
* Application activity logging
* Automated testing using pytest

## Technologies Used

* **Python** – Application logic
* **JSON** – Employee data storage
* **CSV** – Employee data export
* **pytest** – Automated testing
* **Git** – Version control

## Project Structure

```text
employee_management_cli/
│
├── data/
│   └── employees.json
│
├── exports/
│   ├── employees.json
│   └── employees.csv
│
├── logs/
│   └── app.log
│
├── tests/
│   └── test_employee_manager.py
│
├── employee_manager.py
├── exporters.py
├── logger.py
├── main.py
├── validators.py
├── requirements.txt
├── .gitignore
└── README.md
```

## Requirements

* Python 3.13 or higher
* pip
* pytest

## Installation and Setup

### 1. Clone the repository

```bash
git clone <your-repository-url>
cd employee_management_cli
```

### 2. Create a virtual environment

```powershell
python -m venv .venv
```

### 3. Activate the virtual environment

For Windows PowerShell:

```powershell
.\.venv\Scripts\Activate.ps1
```

### 4. Install dependencies

```bash
pip install -r requirements.txt
```

## Running the Application

Run the following command from the project directory:

```bash
python main.py
```

## Menu Options

The application provides the following menu options:

1. Add Employee
2. Update Employee
3. Delete Employee
4. Search Employee
5. Filter Employees
6. View All Employees
7. Export to JSON
8. Export to CSV
9. Exit

## Searching Employees

Select option **4** and enter the employee ID.

Example:

```text
Enter employee ID to search: EMP001
```

The application searches for the employee using the provided ID.

## Filtering Employees

Select option **5** to filter employee records by:

* Department
* Role
* Age

Leave a field blank if you do not want to apply that filter.

## Exporting Employee Data

The application supports two export formats.

### JSON Export

Select option **7** to export employee records to:

```text
exports/employees.json
```

### CSV Export

Select option **8** to export employee records to:

```text
exports/employees.csv
```

## Input Validation

The application validates the following employee fields:

* Employee ID
* Employee name
* Age
* Salary
* Email address

Invalid input is reported to the user through appropriate error messages.

## Exception Handling

The application handles expected errors, including:

* Invalid user input
* Invalid JSON data
* File reading errors
* File writing errors

This helps prevent common errors from unexpectedly terminating the application.

## Logging

Application activities and errors are recorded in:

```text
logs/app.log
```

Logging helps track application behavior and troubleshoot issues.

## Testing

Automated tests are implemented using **pytest**.

Run the test suite with:

```bash
python -m pytest
```

**Current test result:** 6 tests passed.

The tests cover:

* Employee ID validation
* Employee name validation
* Age validation
* Salary validation
* Email validation
* Add employee operation

## Data and Privacy

The project uses synthetic employee data for demonstration and testing purposes.

No real employee personal information, passwords, API keys, or other secrets are intended to be stored in the repository.

## Known Limitations

* Employee records are stored in a local JSON file.
* No database integration is implemented.
* No authentication or authorization system is implemented.
* The application is intended for learning and demonstration purposes.

## Future Improvements

* Integrate a relational database such as PostgreSQL.
* Add user authentication and role-based access control.
* Expand automated test coverage to include update, delete, search, filtering, and export operations.
* Improve email validation and error reporting.
* Add structured application configuration and more comprehensive logging.
