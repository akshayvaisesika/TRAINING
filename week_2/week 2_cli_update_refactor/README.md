# Employee Management CLI

A Python command-line application for managing employee records using PostgreSQL and SQLAlchemy. The project follows Separation of Concerns (SoC), uses a `src/` package layout, and uses Alembic for database schema migrations.

## Features

- Add, update, and delete employees
- Search employees by ID
- Filter employees by department, role, and age
- View all employee records
- Export employee data to JSON and CSV
- Validate employee input
- Handle expected application and database errors
- Log application activities and errors
- Run automated tests using pytest
- Manage database schema migrations with Alembic

## Technologies Used

- **Python** — application logic
- **PostgreSQL** — relational database
- **SQLAlchemy** — ORM and database access
- **Alembic** — database schema migrations
- **pytest** — automated testing
- **JSON and CSV** — data import and export
- **Git** — version control

## Project Structure

```text
week 2_cli_update_refactor/
├── alembic/
│   └── versions/
├── src/
│   └── employee_management/
│       ├── __init__.py
│       ├── main.py
│       ├── employee_manager.py
│       ├── employee_service.py
│       ├── database.py
│       ├── models.py
│       ├── validators.py
│       ├── exporters.py
│       └── logger.py
├── tests/
│   └── test_employee_manager.py
├── data/
│   └── employees.json
├── exports/
├── logs/
├── .env.example
├── .gitignore
├── alembic.ini
├── create_tables.py
├── import_employees.py
├── pyproject.toml
├── requirements.txt
└── README.md
```

## Requirements

- Python 3.13 or a compatible version supported by the dependencies
- PostgreSQL
- pip
- Git

## Installation and Setup

### 1. Clone the repository

Replace the placeholder with your actual repository URL.

```bash
git clone <your-repository-url>
cd <your-repository-folder>
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

```powershell
python -m pip install -r requirements.txt
python -m pip install -e .
```

The editable installation makes the `employee_management` package importable from the `src/` directory.

### 5. Configure database credentials

Use `.env.example` as a template to create a local `.env` file. Configure the environment variables expected by `employee_management.database` for your PostgreSQL connection.

**Never commit database passwords or other secrets.** The `.env.example` file should contain placeholder values only.

### 6. Prepare the database

Create the PostgreSQL database and configure the connection before running the application.

For a new database, review the SQLAlchemy models and migration history before applying migrations.

```powershell
python -m alembic upgrade head
```

**Important:** This command applies pending migrations. For an existing database, check its current Alembic revision and schema first. Do not reset or recreate an existing database as part of routine setup.

## Running the Application

From the project root, run:

```powershell
python -m employee_management.main
```

## Menu Options

1. Add Employee
2. Update Employee
3. Delete Employee
4. Search Employee
5. Filter Employees
6. View All Employees
7. Export to JSON
8. Export to CSV
9. Exit

## Database and ORM

PostgreSQL stores the employee records. SQLAlchemy provides the `Employee` model and database access operations.

The employee model includes:

- Employee ID
- Name
- Age
- Department
- Role
- Salary
- Email address

The command-line interface, database operations, validation, export logic, and logging are separated into different modules.

## Database Migrations

Alembic manages database schema changes over time.

Check the current migration revision:

```powershell
python -m alembic current
```

After changing a SQLAlchemy model, generate a migration:

```powershell
python -m alembic revision --autogenerate -m "describe schema change"
```

Review the generated migration before applying it. Autogeneration may not detect every schema change correctly.

Apply pending