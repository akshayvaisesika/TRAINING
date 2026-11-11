-- Question 36: Least Privilege Roles
-- Database: org_expenses
-- Schema: org
-- Run as an authorized database administrator/owner.

-- 1. Create group roles (already created during the walkthrough).
-- CREATE ROLE trainee_reader NOLOGIN;
-- CREATE ROLE trainee_writer NOLOGIN;

-- 2. Allow both roles to connect to the database.
GRANT CONNECT ON DATABASE org_expenses
TO trainee_reader, trainee_writer;

-- 3. Allow both roles to use the org schema.
GRANT USAGE ON SCHEMA org
TO trainee_reader, trainee_writer;

-- 4. Reader: SELECT only on business tables.
GRANT SELECT ON
    org.categories,
    org.departments,
    org.employee_profiles,
    org.employee_projects,
    org.employees,
    org.expenses,
    org.projects
TO trainee_reader;

-- 5. Writer: read and modify business-table data.
GRANT SELECT, INSERT, UPDATE, DELETE ON
    org.categories,
    org.departments,
    org.employee_profiles,
    org.employee_projects,
    org.employees,
    org.expenses,
    org.projects
TO trainee_writer;

-- 6. Writer: use identity sequences for generated IDs.
GRANT USAGE ON SEQUENCE
    org.categories_category_id_seq,
    org.departments_department_id_seq,
    org.employees_employee_id_seq,
    org.expenses_expense_id_seq,
    org.projects_project_id_seq
TO trainee_writer;

-- No ownership or superuser privileges are granted.