-- Active: 1791964644828@@127.0.0.1@5432@org_expenses_q46
SELECT current_database();

-- Q46: Seed the disposable organization expense database.
-- Run only while connected to org_expenses_q46.

-- 1. Departments
INSERT INTO org.departments (name)
VALUES
    ('Finance'),
    ('Human Resources'),
    ('Operations'),
    ('Research')
ON CONFLICT (name) DO NOTHING;

-- 2. Expense categories
INSERT INTO org.categories (name)
VALUES
    ('Meals'),
    ('Lodging'),
    ('Supplies'),
    ('Training'),
    ('Software'),
    ('Unused Category')
ON CONFLICT (name) DO NOTHING;

-- 3. Projects
INSERT INTO org.projects (name, department_id)
SELECT v.project_name, d.department_id
FROM (
    VALUES
        ('Finance Reporting', 'Finance'),
        ('HR Analytics', 'Human Resources'),
        ('Operations Dashboard', 'Operations'),
        ('Research Analytics', 'Finance')
) AS v(project_name, department_name)
JOIN org.departments d
    ON d.name = v.department_name
ON CONFLICT (name) DO NOTHING;

-- Verify these three groups.
SELECT 'departments' AS item, COUNT(*) AS total
FROM org.departments
UNION ALL
SELECT 'categories', COUNT(*)
FROM org.categories
UNION ALL
SELECT 'projects', COUNT(*)
FROM org.projects;



-- 4. Employees
INSERT INTO org.employees
    (employee_code, full_name, email, department_id, manager_id, hired_on)
SELECT
    v.employee_code,
    v.full_name,
    v.email,
    d.department_id,
    m.employee_id,
    v.hired_on::DATE
FROM (
    VALUES
        ('SEED001', 'Ravi Menon', 'ravi.menon@example.com', 'Finance', NULL, '2025-01-15'),
        ('SEED002', 'Anita Das', 'anita.das@example.com', 'Finance', 'SEED001', '2025-02-01'),
        ('SEED003', 'Suresh Pillai', 'suresh.pillai@example.com', 'Operations', 'SEED001', '2025-02-10'),
        ('SEED004', 'Meera Nair', 'meera.nair@example.com', 'Finance', 'SEED002', '2025-03-01'),
        ('SEED005', 'Kiran Kumar', 'kiran.kumar@example.com', 'Finance', 'SEED002', '2025-03-05'),
        ('SEED006', 'Divya Raj', 'divya.raj@example.com', 'Operations', 'SEED003', '2025-03-10'),
        ('SEED007', 'Arun Das', 'arun.das@example.com', 'Operations', 'SEED003', '2025-03-15'),
        ('SEED008', 'Neha Thomas', 'neha.thomas@example.com', 'Human Resources', NULL, '2025-04-01'),
        ('SEED009', 'Vijay Kumar', 'vijay.kumar@example.com', 'Human Resources', NULL, '2025-04-05'),
        ('SEED010', 'Lakshmi Menon', 'lakshmi.menon@example.com', 'Finance', NULL, '2025-04-10'),
        ('SEED011', 'Rahul Nair', 'rahul.nair@example.com', 'Operations', NULL, '2025-04-15'),
        ('SEED012', 'Pooja Raj', 'pooja.raj@example.com', 'Finance', NULL, '2025-04-20')
) AS v(employee_code, full_name, email, department_name, manager_code, hired_on)
JOIN org.departments d
    ON d.name = v.department_name
LEFT JOIN org.employees m
    ON m.employee_code = v.manager_code
ON CONFLICT (employee_code) DO NOTHING;

-- Verify employee count.
SELECT COUNT(*) AS employee_count
FROM org.employees;

-- Check managers and departments.
SELECT
    e.employee_code,
    e.full_name,
    d.name AS department,
    m.full_name AS manager
FROM org.employees e
LEFT JOIN org.departments d
    ON d.department_id = e.department_id
LEFT JOIN org.employees m
    ON m.employee_id = e.manager_id
ORDER BY e.employee_code;


-- 5. Employee profiles
INSERT INTO org.employee_profiles
    (employee_id, phone, address)
SELECT
    e.employee_id,
    v.phone,
    v.address
FROM (
    VALUES
        ('SEED001', '9000000001', 'Kochi, Kerala'),
        ('SEED002', '9000000002', 'Thrissur, Kerala'),
        ('SEED003', '9000000003', 'Palakkad, Kerala'),
        ('SEED004', '9000000004', 'Coimbatore, Tamil Nadu'),
        ('SEED005', '9000000005', 'Chennai, Tamil Nadu'),
        ('SEED006', '9000000006', NULL)
) AS v(employee_code, phone, address)
JOIN org.employees e
    ON e.employee_code = v.employee_code
ON CONFLICT (employee_id) DO NOTHING;

-- Verify employee profiles.
SELECT
    e.employee_code,
    e.full_name,
    ep.phone,
    ep.address
FROM org.employee_profiles ep
JOIN org.employees e
    ON e.employee_id = ep.employee_id
ORDER BY e.employee_code;

SELECT COUNT(*) AS profile_count
FROM org.employee_profiles;





-- 6. Employee-project assignments
INSERT INTO org.employee_projects
    (employee_id, project_id, assigned_on)
SELECT
    e.employee_id,
    p.project_id,
    v.assigned_on::DATE
FROM (
    VALUES
        ('SEED001', 'Finance Reporting', '2026-07-01'),
        ('SEED002', 'Finance Reporting', '2026-07-02'),
        ('SEED004', 'Finance Reporting', '2026-07-03'),
        ('SEED005', 'Finance Reporting', '2026-07-04'),
        ('SEED003', 'Operations Dashboard', '2026-07-05'),
        ('SEED006', 'Operations Dashboard', '2026-07-06'),
        ('SEED007', 'Operations Dashboard', '2026-07-07'),
        ('SEED008', 'HR Analytics', '2026-07-08'),
        ('SEED009', 'HR Analytics', '2026-07-09'),
        ('SEED010', 'Research Analytics', '2026-07-10'),
        ('SEED011', 'Finance Reporting', '2026-07-11'),
        ('SEED012', 'HR Analytics', '2026-07-12'),
        ('SEED001', 'Operations Dashboard', '2026-07-13'),
        ('SEED003', 'Finance Reporting', '2026-07-14')
) AS v(employee_code, project_name, assigned_on)
JOIN org.employees e
    ON e.employee_code = v.employee_code
JOIN org.projects p
    ON p.name = v.project_name
ON CONFLICT (employee_id, project_id) DO NOTHING;

-- Verify project assignments.
SELECT COUNT(*) AS assignment_count
FROM org.employee_projects;

SELECT
    e.employee_code,
    e.full_name,
    p.name AS project,
    ep.assigned_on
FROM org.employee_projects ep
JOIN org.employees e
    ON e.employee_id = ep.employee_id
JOIN org.projects p
    ON p.project_id = ep.project_id
ORDER BY ep.assigned_on;



-- 7. Seed expenses
INSERT INTO org.expenses
    (employee_id, category_id, amount, occurred_on, description, status)
SELECT
    e.employee_id,
    c.category_id,
    v.amount::NUMERIC(12,2),
    v.occurred_on::DATE,
    v.description,
    v.status
FROM (
    VALUES
        ('SEED001', 'Meals', 100.00, '2026-07-01', 'Seed expense 01', 'submitted'),
        ('SEED002', 'Meals', 250.00, '2026-07-02', 'Seed expense 02', 'approved'),
        ('SEED004', 'Meals', 99.99, '2026-07-03', 'Seed expense 03', 'approved'),
        ('SEED005', 'Meals', 150.01, '2026-07-04', 'Seed expense 04', 'submitted'),
        ('SEED001', 'Lodging', 400.00, '2026-07-05', 'Seed expense 05', 'approved'),
        ('SEED002', 'Lodging', 350.00, '2026-07-06', 'Seed expense 06', 'submitted'),
        ('SEED003', 'Lodging', 999.99, '2026-07-07', 'Seed expense 07', 'approved'),
        ('SEED006', 'Lodging', 1000.01, '2026-07-08', 'Seed expense 08', 'submitted'),
        ('SEED004', 'Supplies', 75.00, '2026-07-09', 'Seed expense 09', 'draft'),
        ('SEED005', 'Supplies', 125.00, '2026-07-10', 'Seed expense 10', 'rejected'),
        ('SEED007', 'Training', 80.00, '2026-07-11', 'Seed expense 11', 'rejected'),
        ('SEED008', 'Training', 120.00, '2026-07-12', 'Seed expense 12', 'submitted'),
        ('SEED010', 'Software', 500.00, '2026-07-13', 'Seed expense 13', 'approved'),
        ('SEED011', 'Software', 750.00, '2026-07-14', 'Seed expense 14', 'submitted'),
        ('SEED001', 'Meals', 200.00, '2026-08-01', 'Seed expense 15', 'approved'),
        ('SEED002', 'Meals', 200.00, '2026-08-01', 'Seed expense 16', 'approved'),
        ('SEED003', 'Lodging', 300.00, '2026-08-02', 'Seed expense 17', 'draft'),
        ('SEED004', 'Lodging', 450.00, '2026-08-03', NULL, 'submitted'),
        ('SEED005', 'Meals', 600.00, '2026-08-04', 'Seed expense 19', 'approved'),
        ('SEED006', 'Meals', 700.00, '2026-08-05', 'Seed expense 20', 'submitted'),
        ('SEED007', 'Meals', 300.00, '2026-08-06', 'Seed expense 21', 'submitted'),
        ('SEED008', 'Meals', 400.00, '2026-08-07', 'Seed expense 22', 'approved'),
        ('SEED010', 'Lodging', 500.00, '2026-08-08', 'Seed expense 23', 'submitted'),
        ('SEED011', 'Lodging', 600.00, '2026-08-09', 'Seed expense 24', 'approved'),
        ('SEED001', 'Meals', 250.00, '2026-08-10', 'Seed expense 25', 'submitted'),
        ('SEED002', 'Meals', 250.00, '2026-08-11', 'Seed expense 26', 'approved'),
        ('SEED003', 'Lodging', 200.00, '2026-08-12', 'Seed expense 27', 'submitted'),
        ('SEED004', 'Lodging', 300.00, '2026-08-13', 'Seed expense 28', 'approved'),
        ('SEED005', 'Meals', 350.00, '2026-08-14', 'Seed expense 29', 'submitted'),
        ('SEED006', 'Meals', 450.00, '2026-08-15', 'Seed expense 30', 'approved'),
        ('SEED007', 'Supplies', 999.00, '2026-09-01', 'Seed expense 31', 'draft'),
        ('SEED008', 'Supplies', 1001.00, '2026-09-02', 'Seed expense 32', 'submitted'),
        ('SEED010', 'Software', 800.00, '2026-09-03', 'Seed expense 33', 'approved'),
        ('SEED011', 'Software', 900.00, '2026-09-04', 'Seed expense 34', 'submitted'),
        ('SEED001', 'Meals', 125.00, '2026-09-05', 'Seed expense 35', 'approved'),
        ('SEED002', 'Meals', 175.00, '2026-09-06', 'Seed expense 36', 'rejected'),
        ('SEED003', 'Lodging', 225.00, '2026-09-07', 'Seed expense 37', 'approved'),
        ('SEED004', 'Lodging', 275.00, '2026-09-08', 'Seed expense 38', 'submitted'),
        ('SEED005', 'Training', 325.00, '2026-09-09', 'Seed expense 39', 'rejected'),
        ('SEED006', 'Training', 425.00, '2026-09-10', 'Seed expense 40', 'rejected')
) AS v(employee_code, category_name, amount, occurred_on, description, status)
JOIN org.employees e
    ON e.employee_code = v.employee_code
JOIN org.categories c
    ON c.name = v.category_name;


-- Verify seeded row counts.
SELECT 'departments' AS table_name, COUNT(*) AS total FROM org.departments
UNION ALL
SELECT 'categories', COUNT(*) FROM org.categories
UNION ALL
SELECT 'projects', COUNT(*) FROM org.projects
UNION ALL
SELECT 'employees', COUNT(*) FROM org.employees
UNION ALL
SELECT 'employee_profiles', COUNT(*) FROM org.employee_profiles
UNION ALL
SELECT 'employee_projects', COUNT(*) FROM org.employee_projects
UNION ALL
SELECT 'expenses', COUNT(*) FROM org.expenses;


SELECT current_database();

SELECT 'departments' AS table_name, COUNT(*) AS total
FROM org.departments
UNION ALL
SELECT 'categories', COUNT(*) FROM org.categories
UNION ALL
SELECT 'projects', COUNT(*) FROM org.projects
UNION ALL
SELECT 'employees', COUNT(*) FROM org.employees
UNION ALL
SELECT 'employee_profiles', COUNT(*) FROM org.employee_profiles
UNION ALL
SELECT 'employee_projects', COUNT(*) FROM org.employee_projects
UNION ALL
SELECT 'expenses', COUNT(*) FROM org.expenses
ORDER BY table_name;