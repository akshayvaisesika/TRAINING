
-- ============================================================
-- Organization Expense Database
-- File: 03_tables.sql
-- Purpose: Create all tables in the org schema.
--
-- IMPORTANT:
-- This script is intended for an empty database.
-- Do not execute it against the existing org_expenses database,
-- because its tables already exist and contain assignment data.
-- ============================================================


-- Q1: Departments
-- Departments must exist before employees and projects.

CREATE TABLE org.departments (
    department_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE
);


-- Q2: Expense categories

CREATE TABLE org.categories (
    category_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE
);


-- Q3: Employees
-- Each employee belongs to a department.
-- manager_id references another employee in the same table.

CREATE TABLE org.employees (
    employee_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    employee_code VARCHAR(20) NOT NULL UNIQUE,
    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    department_id INTEGER NOT NULL,
    manager_id INTEGER,
    hired_on DATE NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    CONSTRAINT fk_employees_department
        FOREIGN KEY (department_id)
        REFERENCES org.departments(department_id),

    CONSTRAINT fk_employees_manager
        FOREIGN KEY (manager_id)
        REFERENCES org.employees(employee_id),

    CONSTRAINT chk_employee_not_own_manager
        CHECK (
            manager_id IS NULL
            OR manager_id <> employee_id
        )
);


-- Q4: Employee profiles
-- Each profile belongs to one employee.

CREATE TABLE org.employee_profiles (
    employee_id INTEGER PRIMARY KEY,
    phone VARCHAR(20),
    address TEXT,

    CONSTRAINT fk_employee_profiles_employee
        FOREIGN KEY (employee_id)
        REFERENCES org.employees(employee_id)
);


-- Q5: Projects
-- Each project belongs to a department.

CREATE TABLE org.projects (
    project_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    department_id INTEGER NOT NULL,

    CONSTRAINT fk_projects_department
        FOREIGN KEY (department_id)
        REFERENCES org.departments(department_id)
);


-- Q6: Expenses
-- Each expense belongs to an employee and a category.

CREATE TABLE org.expenses (
    expense_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    employee_id INTEGER NOT NULL,
    category_id INTEGER NOT NULL,
    amount NUMERIC(12,2) NOT NULL,
    occurred_on DATE NOT NULL,
    description TEXT,
    status VARCHAR(20) NOT NULL DEFAULT 'draft',
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_expenses_employee
        FOREIGN KEY (employee_id)
        REFERENCES org.employees(employee_id)
        ON DELETE RESTRICT,

    CONSTRAINT fk_expenses_category
        FOREIGN KEY (category_id)
        REFERENCES org.categories(category_id)
        ON DELETE RESTRICT,

    CONSTRAINT chk_expenses_positive_amount
        CHECK (amount > 0),

    CONSTRAINT chk_expenses_status
        CHECK (
            status IN ('draft', 'submitted', 'approved', 'rejected')
        )
);


-- Q7: Employee-project assignments
-- This junction table implements a many-to-many relationship.

CREATE TABLE org.employee_projects (
    employee_id INTEGER NOT NULL,
    project_id INTEGER NOT NULL,
    assigned_on DATE NOT NULL DEFAULT CURRENT_DATE,

    CONSTRAINT pk_employee_projects
        PRIMARY KEY (employee_id, project_id),

    CONSTRAINT fk_employee_projects_employee
        FOREIGN KEY (employee_id)
        REFERENCES org.employees(employee_id)
        ON DELETE CASCADE,

    CONSTRAINT fk_employee_projects_project
        FOREIGN KEY (project_id)
        REFERENCES org.projects(project_id)
        ON DELETE CASCADE
);


-- Verification: list all tables created in the org schema.
-- This query reads metadata and does not modify data.

SELECT
    table_schema,
    table_name
FROM information_schema.tables
WHERE table_schema = 'org'
  AND table_type = 'BASE TABLE'
ORDER BY table_name;
