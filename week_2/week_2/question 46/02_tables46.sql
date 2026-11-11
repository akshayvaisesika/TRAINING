-- Q46: Create all core organization tables.
-- IMPORTANT: Run this script only in org_expenses_q46.

-- 1. Departments
CREATE TABLE IF NOT EXISTS org.departments (
    department_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    department_name VARCHAR(100) NOT NULL UNIQUE
);

-- 2. Categories
CREATE TABLE IF NOT EXISTS org.categories (
    category_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    category_name VARCHAR(100) NOT NULL UNIQUE
);

-- 3. Employees
CREATE TABLE IF NOT EXISTS org.employees (
    employee_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    employee_code VARCHAR(20) NOT NULL UNIQUE,
    full_name VARCHAR(150) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    department_id INTEGER REFERENCES org.departments(department_id),
    manager_id INTEGER REFERENCES org.employees(employee_id),
    hired_on DATE NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT chk_employee_not_own_manager
        CHECK (manager_id IS NULL OR manager_id <> employee_id)
);

-- 4. Employee profiles
CREATE TABLE IF NOT EXISTS org.employee_profiles (
    employee_id INTEGER PRIMARY KEY
        REFERENCES org.employees(employee_id) ON DELETE CASCADE,
    phone VARCHAR(30),
    address TEXT
);

-- 5. Projects
CREATE TABLE IF NOT EXISTS org.projects (
    project_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    project_name VARCHAR(150) NOT NULL UNIQUE,
    department_id INTEGER NOT NULL
        REFERENCES org.departments(department_id)
);

-- 6. Expenses
CREATE TABLE IF NOT EXISTS org.expenses (
    expense_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    employee_id INTEGER NOT NULL
        REFERENCES org.employees(employee_id) ON DELETE RESTRICT,
    category_id INTEGER NOT NULL
        REFERENCES org.categories(category_id) ON DELETE RESTRICT,
    amount NUMERIC(12, 2) NOT NULL CHECK (amount > 0),
    occurred_on DATE NOT NULL,
    description TEXT,
    status VARCHAR(20) NOT NULL DEFAULT 'draft',
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_expense_status
        CHECK (status IN ('draft', 'submitted', 'approved', 'rejected'))
);

-- 7. Employee-project assignments
CREATE TABLE IF NOT EXISTS org.employee_projects (
    employee_id INTEGER NOT NULL
        REFERENCES org.employees(employee_id) ON DELETE CASCADE,
    project_id INTEGER NOT NULL
        REFERENCES org.projects(project_id) ON DELETE CASCADE,
    assigned_on DATE NOT NULL DEFAULT CURRENT_DATE,
    PRIMARY KEY (employee_id, project_id)
);

-- Verification: confirm that all seven tables exist.
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'org'
  AND table_type = 'BASE TABLE'
ORDER BY table_name;



ALTER TABLE org.departments
    RENAME COLUMN department_name TO name;

ALTER TABLE org.categories
    RENAME COLUMN category_name TO name;

ALTER TABLE org.projects
    RENAME COLUMN project_name TO name;


select*from org.projects;


SELECT table_name, column_name
FROM information_schema.columns
WHERE table_schema = 'org'
  AND table_name IN ('departments', 'categories', 'projects')
ORDER BY table_name, ordinal_position;