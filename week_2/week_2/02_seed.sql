
-- Q11: Seed a useful dataset
-- Step: Insert departments and categories

INSERT INTO org.departments (name)
VALUES
    ('Finance'),
    ('Human Resources'),
    ('Operations'),
    ('Research')
ON CONFLICT (name) DO NOTHING;

select * from org.departments;
INSERT INTO org.categories (name)
VALUES
    ('Meals'),
    ('Lodging'),
    ('Supplies'),
    ('Training'),
    ('Software'),
    ('Unused Category')
ON CONFLICT (name) DO NOTHING;

SELECT*from org.categories;

-- Insert projects after departments exist.

INSERT INTO org.projects (name, department_id)
SELECT
    seed.project_name,
    d.department_id
FROM (
    VALUES
        ('Finance Reporting', 'Finance'),
        ('HR Analytics', 'Human Resources'),
        ('Operations Dashboard', 'Operations'),
        ('Research Analytics', 'Finance')
) AS seed(project_name, department_name)
JOIN org.departments AS d
    ON d.name = seed.department_name
ON CONFLICT (name) DO NOTHING;

-- Verify projects and their departments.
SELECT
    p.project_id,
    p.name AS project_name,
    d.name AS department_name
FROM org.projects AS p
JOIN org.departments AS d
    ON d.department_id = p.department_id
ORDER BY p.name;




-- Step : Insert the top-level manager.

INSERT INTO org.employees
    (employee_code, full_name, email, department_id,
     manager_id, hired_on, is_active)
SELECT
    'SEED001',
    'Ravi Menon',
    'ravi.menon@example.com',
    d.department_id,
    NULL,
    DATE '2025-01-15',
    TRUE
FROM org.departments AS d
WHERE d.name = 'Finance'
ON CONFLICT DO NOTHING;

select*from org.employees;

-- Verify Ravi.
SELECT employee_code, full_name, department_id, manager_id
FROM org.employees
WHERE employee_code = 'SEED001';





-- Step 4B: Insert employees reporting to Ravi Menon.

INSERT INTO org.employees
    (employee_code, full_name, email, department_id,
     manager_id, hired_on, is_active)
SELECT
    seed.employee_code,
    seed.full_name,
    seed.email,
    d.department_id,
    m.employee_id,
    seed.hired_on,
    TRUE
FROM (
    VALUES
        ('SEED002', 'Anita Das', 'anita.das@example.com',
         'Finance', DATE '2025-02-01'),
        ('SEED003', 'Suresh Pillai', 'suresh.pillai@example.com',
         'Operations', DATE '2025-02-10')
) AS seed(employee_code, full_name, email, department_name, hired_on)
JOIN org.departments AS d
    ON d.name = seed.department_name
JOIN org.employees AS m
    ON m.employee_code = 'SEED001'
ON CONFLICT DO NOTHING;

-- Verify the hierarchy so far.
SELECT
    e.employee_code,
    e.full_name,
    m.employee_code AS manager_code,
    m.full_name AS manager_name
FROM org.employees AS e
LEFT JOIN org.employees AS m
    ON m.employee_id = e.manager_id
WHERE e.employee_code IN ('SEED001', 'SEED002', 'SEED003')
ORDER BY e.employee_code;



-- Step 4C: Insert employees reporting to Anita and Suresh.

INSERT INTO org.employees
    (employee_code, full_name, email, department_id,
     manager_id, hired_on, is_active)
SELECT
    seed.employee_code,
    seed.full_name,
    seed.email,
    d.department_id,
    m.employee_id,
    seed.hired_on,
    TRUE
FROM (
    VALUES
        ('SEED004', 'Meera Nair', 'meera.nair@example.com',
         'Finance', 'SEED002', DATE '2025-03-01'),
        ('SEED005', 'Kiran Kumar', 'kiran.kumar@example.com',
         'Finance', 'SEED002', DATE '2025-03-05'),
        ('SEED006', 'Divya Raj', 'divya.raj@example.com',
         'Operations', 'SEED003', DATE '2025-03-10'),
        ('SEED007', 'Arun Das', 'arun.das@example.com',
         'Operations', 'SEED003', DATE '2025-03-15')
) AS seed(
    employee_code, full_name, email, department_name,
    manager_code, hired_on
)
JOIN org.departments AS d
    ON d.name = seed.department_name
JOIN org.employees AS m
    ON m.employee_code = seed.manager_code
ON CONFLICT DO NOTHING;

-- Verify the hierarchy.
SELECT
    e.employee_code,
    e.full_name,
    m.employee_code AS manager_code,
    m.full_name AS manager_name
FROM org.employees AS e
LEFT JOIN org.employees AS m
    ON m.employee_id = e.manager_id
WHERE e.employee_code BETWEEN 'SEED001' AND 'SEED007'
ORDER BY e.employee_code;



-- Step 4D: Insert five additional employees.

INSERT INTO org.employees
    (employee_code, full_name, email, department_id,
     manager_id, hired_on, is_active)
SELECT
    seed.employee_code,
    seed.full_name,
    seed.email,
    d.department_id,
    NULL,
    seed.hired_on,
    TRUE
FROM (
    VALUES
        ('SEED008', 'Neha Thomas', 'neha.thomas@example.com',
         'Human Resources', DATE '2025-04-01'),
        ('SEED009', 'Vijay Kumar', 'vijay.kumar@example.com',
         'Human Resources', DATE '2025-04-05'),
        ('SEED010', 'Lakshmi Menon', 'lakshmi.menon@example.com',
         'Finance', DATE '2025-04-10'),
        ('SEED011', 'Rahul Nair', 'rahul.nair@example.com',
         'Operations', DATE '2025-04-15'),
        ('SEED012', 'Pooja Raj', 'pooja.raj@example.com',
         'Finance', DATE '2025-04-20')
) AS seed(employee_code, full_name, email, department_name, hired_on)
JOIN org.departments AS d
    ON d.name = seed.department_name
ON CONFLICT DO NOTHING;

-- Verify all 12 seeded employees.
SELECT employee_code, full_name
FROM org.employees
WHERE employee_code LIKE 'SEED%'
ORDER BY employee_code;




-- Step 5: Insert six employee profiles.

INSERT INTO org.employee_profiles
    (employee_id, phone, address)
SELECT
    e.employee_id,
    seed.phone,
    seed.address
FROM (
    VALUES
        ('SEED001', '9000000001', 'Kochi, Kerala'),
        ('SEED002', '9000000002', 'Thrissur, Kerala'),
        ('SEED003', '9000000003', 'Palakkad, Kerala'),
        ('SEED004', '9000000004', 'Coimbatore, Tamil Nadu'),
        ('SEED005', '9000000005', 'Chennai, Tamil Nadu'),
        ('SEED006', '9000000006', NULL)
) AS seed(employee_code, phone, address)
JOIN org.employees AS e
    ON e.employee_code = seed.employee_code
ON CONFLICT (employee_id) DO NOTHING;

-- Verify the seeded profiles.
SELECT
    e.employee_code,
    e.full_name,
    p.phone,
    p.address
FROM org.employee_profiles AS p
JOIN org.employees AS e
    ON e.employee_id = p.employee_id
WHERE e.employee_code LIKE 'SEED%'
ORDER BY e.employee_code;




-- Step 6: Insert employee-project assignments.
-- Use employee codes and project names instead of assuming IDs.

INSERT INTO org.employee_projects
    (employee_id, project_id, assigned_on)
SELECT
    e.employee_id,
    p.project_id,
    seed.assigned_on
FROM (
    VALUES
        ('SEED001', 'Finance Reporting', DATE '2026-07-01'),
        ('SEED002', 'Finance Reporting', DATE '2026-07-02'),
        ('SEED004', 'Finance Reporting', DATE '2026-07-03'),
        ('SEED005', 'Finance Reporting', DATE '2026-07-04'),
        ('SEED003', 'Operations Dashboard', DATE '2026-07-05'),
        ('SEED006', 'Operations Dashboard', DATE '2026-07-06'),
        ('SEED007', 'Operations Dashboard', DATE '2026-07-07'),
        ('SEED008', 'HR Analytics', DATE '2026-07-08'),
        ('SEED009', 'HR Analytics', DATE '2026-07-09'),
        ('SEED010', 'Research Analytics', DATE '2026-07-10'),
        ('SEED011', 'Finance Reporting', DATE '2026-07-11'),
        ('SEED012', 'HR Analytics', DATE '2026-07-12'),
        ('SEED001', 'Operations Dashboard', DATE '2026-07-13'),
        ('SEED003', 'Finance Reporting', DATE '2026-07-14')
) AS seed(employee_code, project_name, assigned_on)
JOIN org.employees AS e
    ON e.employee_code = seed.employee_code
JOIN org.projects AS p
    ON p.name = seed.project_name
ON CONFLICT (employee_id, project_id) DO NOTHING;

-- Verify the assignments.
SELECT
    e.employee_code,
    e.full_name,
    p.name AS project_name,
    ep.assigned_on
FROM org.employee_projects AS ep
JOIN org.employees AS e
    ON e.employee_id = ep.employee_id
JOIN org.projects AS p
    ON p.project_id = ep.project_id
WHERE e.employee_code LIKE 'SEED%'
ORDER BY e.employee_code, p.name;




-- Step 7A: Insert expenses 1-20.
-- Use employee codes and category names to look up IDs.
-- The NOT EXISTS check helps avoid duplicate seed rows on reruns.

INSERT INTO org.expenses
    (employee_id, category_id, amount, occurred_on, description, status)
SELECT
    e.employee_id,
    c.category_id,
    seed.amount,
    seed.occurred_on,
    seed.description,
    seed.status
FROM (
    VALUES
        ('SEED001', 'Meals',    100.00::NUMERIC(12,2), DATE '2026-07-01', 'Seed expense 01', 'submitted'),
        ('SEED002', 'Meals',    250.00::NUMERIC(12,2), DATE '2026-07-02', 'Seed expense 02', 'approved'),
        ('SEED004', 'Meals',     99.99::NUMERIC(12,2), DATE '2026-07-03', 'Seed expense 03', 'approved'),
        ('SEED005', 'Meals',    150.01::NUMERIC(12,2), DATE '2026-07-04', 'Seed expense 04', 'submitted'),
        ('SEED001', 'Lodging',  400.00::NUMERIC(12,2), DATE '2026-07-05', 'Seed expense 05', 'approved'),
        ('SEED002', 'Lodging',  350.00::NUMERIC(12,2), DATE '2026-07-06', 'Seed expense 06', 'submitted'),
        ('SEED003', 'Lodging',  999.99::NUMERIC(12,2), DATE '2026-07-07', 'Seed expense 07', 'approved'),
        ('SEED006', 'Lodging', 1000.01::NUMERIC(12,2), DATE '2026-07-08', 'Seed expense 08', 'submitted'),
        ('SEED004', 'Supplies',  75.00::NUMERIC(12,2), DATE '2026-07-09', 'Seed expense 09', 'draft'),
        ('SEED005', 'Supplies', 125.00::NUMERIC(12,2), DATE '2026-07-10', 'Seed expense 10', 'rejected'),
        ('SEED007', 'Training',  80.00::NUMERIC(12,2), DATE '2026-07-11', 'Seed expense 11', 'rejected'),
        ('SEED008', 'Training', 120.00::NUMERIC(12,2), DATE '2026-07-12', 'Seed expense 12', 'submitted'),
        ('SEED010', 'Software', 500.00::NUMERIC(12,2), DATE '2026-07-13', 'Seed expense 13', 'approved'),
        ('SEED011', 'Software', 750.00::NUMERIC(12,2), DATE '2026-07-14', 'Seed expense 14', 'submitted'),
        ('SEED001', 'Meals',    200.00::NUMERIC(12,2), DATE '2026-08-01', 'Seed expense 15', 'approved'),
        ('SEED002', 'Meals',    200.00::NUMERIC(12,2), DATE '2026-08-01', 'Seed expense 16', 'approved'),
        ('SEED003', 'Lodging',  300.00::NUMERIC(12,2), DATE '2026-08-02', 'Seed expense 17', 'draft'),
        ('SEED004', 'Lodging',  450.00::NUMERIC(12,2), DATE '2026-08-03', NULL,              'submitted'),
        ('SEED005', 'Meals',    600.00::NUMERIC(12,2), DATE '2026-08-04', 'Seed expense 19', 'approved'),
        ('SEED006', 'Meals',    700.00::NUMERIC(12,2), DATE '2026-08-05', 'Seed expense 20', 'submitted')
) AS seed(employee_code, category_name, amount, occurred_on, description, status)
JOIN org.employees AS e
    ON e.employee_code = seed.employee_code
JOIN org.categories AS c
    ON c.name = seed.category_name
WHERE NOT EXISTS (
    SELECT 1
    FROM org.expenses AS existing
    WHERE existing.employee_id = e.employee_id
      AND existing.category_id = c.category_id
      AND existing.occurred_on = seed.occurred_on
      AND existing.description IS NOT DISTINCT FROM seed.description
      AND existing.amount = seed.amount
      AND existing.status = seed.status
);

-- Verify the seeded expenses inserted so far.
SELECT
    COUNT(*) AS seeded_expense_count,
    MIN(occurred_on) AS first_expense_date,
    MAX(occurred_on) AS last_expense_date
FROM org.expenses
WHERE description LIKE 'Seed expense %'
   OR description IS NULL;




-- Step 7B: Insert expenses 21-40.

INSERT INTO org.expenses
    (employee_id, category_id, amount, occurred_on, description, status)
SELECT
    e.employee_id,
    c.category_id,
    seed.amount,
    seed.occurred_on,
    seed.description,
    seed.status
FROM (
    VALUES
        ('SEED007', 'Meals',     300.00::NUMERIC(12,2), DATE '2026-08-06', 'Seed expense 21', 'submitted'),
        ('SEED008', 'Meals',     400.00::NUMERIC(12,2), DATE '2026-08-07', 'Seed expense 22', 'approved'),
        ('SEED010', 'Lodging',   500.00::NUMERIC(12,2), DATE '2026-08-08', 'Seed expense 23', 'submitted'),
        ('SEED011', 'Lodging',   600.00::NUMERIC(12,2), DATE '2026-08-09', 'Seed expense 24', 'approved'),
        ('SEED001', 'Meals',     250.00::NUMERIC(12,2), DATE '2026-08-10', 'Seed expense 25', 'submitted'),
        ('SEED002', 'Meals',     250.00::NUMERIC(12,2), DATE '2026-08-11', 'Seed expense 26', 'approved'),
        ('SEED003', 'Lodging',   200.00::NUMERIC(12,2), DATE '2026-08-12', 'Seed expense 27', 'submitted'),
        ('SEED004', 'Lodging',   300.00::NUMERIC(12,2), DATE '2026-08-13', 'Seed expense 28', 'approved'),
        ('SEED005', 'Meals',     350.00::NUMERIC(12,2), DATE '2026-08-14', 'Seed expense 29', 'submitted'),
        ('SEED006', 'Meals',     450.00::NUMERIC(12,2), DATE '2026-08-15', 'Seed expense 30', 'approved'),
        ('SEED007', 'Supplies',  999.00::NUMERIC(12,2), DATE '2026-09-01', 'Seed expense 31', 'draft'),
        ('SEED008', 'Supplies', 1001.00::NUMERIC(12,2), DATE '2026-09-02', 'Seed expense 32', 'submitted'),
        ('SEED010', 'Software',  800.00::NUMERIC(12,2), DATE '2026-09-03', 'Seed expense 33', 'approved'),
        ('SEED011', 'Software',  900.00::NUMERIC(12,2), DATE '2026-09-04', 'Seed expense 34', 'submitted'),
        ('SEED001', 'Meals',     125.00::NUMERIC(12,2), DATE '2026-09-05', 'Seed expense 35', 'approved'),
        ('SEED002', 'Meals',     175.00::NUMERIC(12,2), DATE '2026-09-06', 'Seed expense 36', 'rejected'),
        ('SEED003', 'Lodging',   225.00::NUMERIC(12,2), DATE '2026-09-07', 'Seed expense 37', 'approved'),
        ('SEED004', 'Lodging',   275.00::NUMERIC(12,2), DATE '2026-09-08', 'Seed expense 38', 'submitted'),
        ('SEED005', 'Training',  325.00::NUMERIC(12,2), DATE '2026-09-09', 'Seed expense 39', 'rejected'),
        ('SEED006', 'Training',  425.00::NUMERIC(12,2), DATE '2026-09-10', 'Seed expense 40', 'rejected')
) AS seed(employee_code, category_name, amount, occurred_on, description, status)
JOIN org.employees AS e
    ON e.employee_code = seed.employee_code
JOIN org.categories AS c
    ON c.name = seed.category_name
WHERE NOT EXISTS (
    SELECT 1
    FROM org.expenses AS existing
    WHERE existing.employee_id = e.employee_id
      AND existing.category_id = c.category_id
      AND existing.occurred_on = seed.occurred_on
      AND existing.description IS NOT DISTINCT FROM seed.description
      AND existing.amount = seed.amount
      AND existing.status = seed.status
);

-- Verify seeded expenses by month and status.
SELECT
    DATE_TRUNC('month', occurred_on)::DATE AS expense_month,
    status,
    COUNT(*) AS expense_count,
    SUM(amount) AS total_amount
FROM org.expenses
WHERE description LIKE 'Seed expense %'
GROUP BY DATE_TRUNC('month', occurred_on)::DATE, status
ORDER BY expense_month, status;




-- Step 8: Verify Q11 seed requirements.
-- These queries are read-only.

-- 1. Count records in each required table.
SELECT 'departments' AS table_name, COUNT(*) AS row_count
FROM org.departments
UNION ALL
SELECT 'employees', COUNT(*) FROM org.employees
UNION ALL
SELECT 'employee_profiles', COUNT(*) FROM org.employee_profiles
UNION ALL
SELECT 'categories', COUNT(*) FROM org.categories
UNION ALL
SELECT 'projects', COUNT(*) FROM org.projects
UNION ALL
SELECT 'employee_projects', COUNT(*) FROM org.employee_projects
UNION ALL
SELECT 'expenses', COUNT(*) FROM org.expenses
ORDER BY table_name;

-- 2. Check seeded expenses by month.
SELECT
    DATE_TRUNC('month', occurred_on)::DATE AS expense_month,
    COUNT(*) AS expense_count,
    SUM(amount) AS total_amount
FROM org.expenses
WHERE description LIKE 'Seed expense %'
GROUP BY DATE_TRUNC('month', occurred_on)::DATE
ORDER BY expense_month;

-- 3. Check all expense statuses in the database.
SELECT status, COUNT(*) AS expense_count
FROM org.expenses
GROUP BY status
ORDER BY status;

-- 4. Check totals by category.
SELECT
    c.name AS category_name,
    COUNT(e.expense_id) AS expense_count,
    COALESCE(SUM(e.amount), 0) AS total_amount,
    COUNT(*) FILTER (WHERE e.status = 'approved') AS approved_count,
    COUNT(*) FILTER (WHERE e.status = 'submitted') AS submitted_count,
    COUNT(*) FILTER (WHERE e.status = 'rejected') AS rejected_count
FROM org.categories AS c
LEFT JOIN org.expenses AS e
    ON e.category_id = c.category_id
GROUP BY c.category_id, c.name
ORDER BY c.name;

-- 5. Check employees without expenses.
SELECT e.employee_code, e.full_name
FROM org.employees AS e
WHERE NOT EXISTS (
    SELECT 1
    FROM org.expenses AS x
    WHERE x.employee_id = e.employee_id
)
ORDER BY e.employee_code;

-- 6. Check employees without project assignments.
SELECT e.employee_code, e.full_name
FROM org.employees AS e
WHERE NOT EXISTS (
    SELECT 1
    FROM org.employee_projects AS ep
    WHERE ep.employee_id = e.employee_id
)
ORDER BY e.employee_code;

-- 7. Check departments without employees.
SELECT d.name AS department_name
FROM org.departments AS d
WHERE NOT EXISTS (
    SELECT 1
    FROM org.employees AS e
    WHERE e.department_id = d.department_id
);

-- 8. Check categories without expenses.
SELECT c.name AS category_name
FROM org.categories AS c
WHERE NOT EXISTS (
    SELECT 1
    FROM org.expenses AS e
    WHERE e.category_id = c.category_id
);

-- 9. Record the overall expense baseline.
SELECT
    COUNT(*) AS expense_row_count,
    COALESCE(SUM(amount), 0) AS total_expense_amount,
    MIN(occurred_on) AS earliest_expense_date,
    MAX(occurred_on) AS latest_expense_date
FROM org.expenses;




SELECT
    c.name AS category,
    COUNT(e.expense_id) AS total_expenses,
    COUNT(e.expense_id) FILTER (
        WHERE e.status = 'submitted'
    ) AS submitted_count,
    COUNT(e.expense_id) FILTER (
        WHERE e.status = 'approved'
    ) AS approved_count,
    COUNT(e.expense_id) FILTER (
        WHERE e.status = 'rejected'
    ) AS rejected_count,
    COALESCE(
        SUM(e.amount) FILTER (
            WHERE e.status IN ('submitted', 'approved')
        ), 0
    ) AS submitted_approved_total
FROM org.categories c
LEFT JOIN org.expenses e
    ON e.category_id = c.category_id
GROUP BY c.category_id, c.name
ORDER BY c.name;




-- 1. Check employee hierarchy
SELECT
    e.employee_code,
    e.full_name,
    m.employee_code AS manager_code,
    m.full_name AS manager_name
FROM org.employees e
LEFT JOIN org.employees m
    ON e.manager_id = m.employee_id
WHERE e.employee_code LIKE 'SEED%'
ORDER BY e.employee_code;

-- 2. Find employees assigned to multiple projects
SELECT
    e.employee_code,
    e.full_name,
    COUNT(ep.project_id) AS project_count
FROM org.employees e
JOIN org.employee_projects ep
    ON e.employee_id = ep.employee_id
GROUP BY e.employee_id, e.employee_code, e.full_name
HAVING COUNT(ep.project_id) >= 2;

-- 3. Check NULL expense descriptions
SELECT
    expense_id,
    amount,
    occurred_on,
    status
FROM org.expenses
WHERE description IS NULL;





-- 1. Overall baseline
SELECT
    COUNT(*) AS expense_row_count,
    COALESCE(SUM(amount), 0) AS total_expense_amount,
    MIN(occurred_on) AS earliest_expense_date,
    MAX(occurred_on) AS latest_expense_date
FROM org.expenses;

-- 2. Baseline totals by category
SELECT
    c.name AS category,
    COUNT(e.expense_id) AS expense_count,
    COALESCE(SUM(e.amount), 0) AS total_amount
FROM org.categories c
LEFT JOIN org.expenses e
    ON e.category_id = c.category_id
GROUP BY c.category_id, c.name
ORDER BY c.name;




SELECT
    conrelid::regclass AS table_name,
    conname AS constraint_name,
    confrelid::regclass AS referenced_table,
    CASE confdeltype
        WHEN 'a' THEN 'NO ACTION'
        WHEN 'r' THEN 'RESTRICT'
        WHEN 'c' THEN 'CASCADE'
        WHEN 'n' THEN 'SET NULL'
        WHEN 'd' THEN 'SET DEFAULT'
    END AS on_delete
FROM pg_constraint
WHERE contype = 'f'
  AND connamespace = 'org'::regnamespace
ORDER BY conrelid::regclass::TEXT, conname;



SELECT
    amount,
    COUNT(*) AS expense_count
FROM org.expenses
WHERE amount IN (
    99.99, 100.00, 100.01,
    999.99, 1000.00, 1000.01
)
GROUP BY amount
ORDER BY amount;


