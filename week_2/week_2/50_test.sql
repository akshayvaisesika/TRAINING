-- =====================================================
-- Q12: Constraint Failures
-- Database: org_expenses
-- Schema: org
-- Purpose: Demonstrate rejected operations safely.
-- IMPORTANT: Preserve all existing business data.
-- =====================================================


-- Q12.1: Expected failure - duplicate employee email
BEGIN;

INSERT INTO org.employees (
    employee_code,
    full_name,
    email,
    department_id,
    hired_on,
    is_active
)
VALUES (
    'TEST_DUP_EMAIL',
    'Duplicate Email Test',
    'arun@example.com',
    1,
    DATE '2026-10-15',
    TRUE
);

ROLLBACK;



-- Q12.2: Expected failure - missing employee name
BEGIN;

INSERT INTO org.employees (
    employee_code,
    full_name,
    email,
    department_id,
    hired_on,
    is_active
)
VALUES (
    'TEST_NULL_NAME',
    NULL,
    'test.null.name@example.com',
    1,
    DATE '2026-10-15',
    TRUE
);

ROLLBACK;


-- Q12.3: Expected failure - nonpositive expense amount
BEGIN;

INSERT INTO org.expenses (
    employee_id,
    category_id,
    amount,
    occurred_on,
    description,
    status
)
VALUES (
    (SELECT employee_id FROM org.employees
     WHERE employee_code = 'SEED001'),
    (SELECT category_id FROM org.categories
     WHERE name = 'Meals'),
    0,
    DATE '2026-10-15',
    'Q12 invalid amount test',
    'draft'
);
ROLLBACK;


-- Q12.4: Expected failure - invalid expense status
BEGIN;

INSERT INTO org.expenses (
    employee_id,
    category_id,
    amount,
    occurred_on,
    description,
    status
)
VALUES (
    (SELECT employee_id FROM org.employees
     WHERE employee_code = 'SEED001'),
    (SELECT category_id FROM org.categories
     WHERE name = 'Meals'),
    50.00,
    DATE '2026-10-15',
    'Q12 invalid status test',
    'pending'
);

ROLLBACK;



-- Q12.5: Expected failure - missing category parent
BEGIN;

INSERT INTO org.expenses (
    employee_id,
    category_id,
    amount,
    occurred_on,
    description,
    status
)
VALUES (
    (SELECT employee_id FROM org.employees
     WHERE employee_code = 'SEED001'),
    -999999,
    50.00,
    DATE '2026-10-15',
    'Q12 missing parent test',
    'draft'
);

ROLLBACK;


-- Q12.6: Expected failure - duplicate project assignment
BEGIN;

INSERT INTO org.employee_projects (
    employee_id,
    project_id,
    assigned_on
)
VALUES (
    (SELECT employee_id FROM org.employees
     WHERE employee_code = 'SEED001'),
    (SELECT project_id FROM org.projects
     WHERE name = 'Finance Reporting'),
    DATE '2026-10-15'
);

ROLLBACK;


-- Q12.7: Valid control case - expense should be accepted
BEGIN;

INSERT INTO org.expenses (
    employee_id,
    category_id,
    amount,
    occurred_on,
    description,
    status
)
VALUES (
    (SELECT employee_id FROM org.employees
     WHERE employee_code = 'SEED001'),
    (SELECT category_id FROM org.categories
     WHERE name = 'Meals'),
    51.00,
    DATE '2026-10-15',
    'Q12 valid control test',
    'draft'
)
RETURNING expense_id, amount, status;

ROLLBACK;



-- Q13: Read and Filter
-- Find active employees hired before 2026-07-01.
-- Sort by name and employee_id, then return the first five.

select employee_code , full_name , email from org.employees where is_active='TRUE' and hired_on < date '2026-07-01'
ORDER BY full_name , employee_id limit 5;





-- Q14.1: Find employees without managers

SELECT
    employee_code,
    full_name,
    manager_id
FROM org.employees
WHERE manager_id IS NULL
ORDER BY full_name, employee_id;



-- Q14.2: Find descriptions containing 'taxi', regardless of case

SELECT
    expense_id,
    employee_id,
    amount,
    occurred_on,
    description
FROM org.expenses
WHERE description ILIKE '%taxi%'
ORDER BY occurred_on, expense_id;


-- Q14.3: Expenses in the date interval and amount range
select expense_id,employee_id,amount,occurred_on,description, status from org.expenses
where occurred_on >= DATE '2026-06-01'
and occurred_on <= DATE '2026-10-01'
and amount BETWEEN 100 and 1000
ORDER BY occurred_on,expense_id;




-- Q15: Insert a new expense and return its generated values

ALTER TABLE org.categories RENAME COLUMN name TO category_name;

INSERT INTO org.expenses (
    employee_id,
    category_id,
    amount,
    occurred_on,
    description,
    status
)
VALUES (
    (SELECT employee_id
     FROM org.employees
     WHERE employee_code = 'SEED001'
     LIMIT 1),

    (SELECT category_id
     FROM org.categories
     WHERE category_name = 'Meals'
     LIMIT 1),

    75.00,
    DATE '2026-10-15',
    'Q15 CRUD create/read test',
    'draft'
)
RETURNING expense_id, amount, status;

SELECT*from org.expenses;
SELECT*FROM org.categories;



-- Q15: Read back the expense created in Step 1

SELECT
    expense_id,
    employee_id,
    category_id,
    amount,
    occurred_on,
    description,
    status
FROM org.expenses
WHERE expense_id = 49;






-- Q16: Update only the expense created in Q15

UPDATE org.expenses
SET
    amount = 125.00,
    description = 'Q16 updated CRUD test',
    status = 'submitted'
WHERE expense_id = 49
RETURNING expense_id, amount, description, status;


-- Q16: Verify the updated expense

SELECT
    expense_id,
    amount,
    description,
    status
FROM org.expenses
WHERE expense_id = 49;



-- Q17: Delete only the test expense created in Q15

DELETE FROM org.expenses
WHERE expense_id = 49
RETURNING expense_id, amount, description, status;

-- Q17: Verify that the test expense was deleted

SELECT
    expense_id,
    amount,
    description,
    status
FROM org.expenses
WHERE expense_id = 49;


-- Q18: Add an optional receipt reference column
ALTER TABLE org.expenses
ADD COLUMN receipt_reference TEXT;


-- Q18: Add a sample receipt reference to an existing expense

UPDATE org.expenses
SET receipt_reference = 'RCP-2026-001'
WHERE expense_id = (
    SELECT MIN(expense_id)
    FROM org.expenses
)
RETURNING expense_id, receipt_reference;


-- Q18: Retrieve the saved receipt reference

SELECT
    expense_id,
    amount,
    occurred_on,
    receipt_reference
FROM org.expenses
WHERE receipt_reference = 'RCP-2026-001';




-- Q19: Employee directory using string scalar functions

SELECT
    employee_code,
    UPPER(full_name) AS employee_name_upper,
    LOWER(email) AS email_lowercase,
    LENGTH(full_name) AS name_length
FROM org.employees
ORDER BY full_name, employee_id;


-- Q19: Expense listing with a placeholder for NULL descriptions

SELECT
    expense_id,
    amount,
    occurred_on,
    COALESCE(description, 'No description provided') AS expense_description
FROM org.expenses
ORDER BY occurred_on, expense_id;




-- Q20.1 : Round a calculated expense amount

SELECT
    expense_id,
    amount,
    ROUND(amount * 1.05, 2) AS amount_with_5_percent
FROM org.expenses
ORDER BY expense_id
LIMIT 10;



-- Q20.2 : Extract the year and month from expense dates

SELECT
    expense_id,
    occurred_on,
    EXTRACT(YEAR FROM occurred_on) AS expense_year,
    EXTRACT(MONTH FROM occurred_on) AS expense_month
FROM org.expenses
ORDER BY occurred_on, expense_id
LIMIT 10;



-- Q20.3 : Calculate monthly expense totals using date_trunc()

SELECT
    DATE_TRUNC('month', occurred_on::timestamp) AS expense_month,
    COUNT(*) AS expense_count,
    SUM(amount) AS total_amount
FROM org.expenses
GROUP BY DATE_TRUNC('month', occurred_on::timestamp)
ORDER BY expense_month;


-- Q20.4 : Classify expenses into small, medium and large bands

SELECT
    expense_id,
    amount,
    CASE
        WHEN amount < 500 THEN 'Small'
        WHEN amount < 2000 THEN 'Medium'
        ELSE 'Large'
    END AS expense_band
FROM org.expenses
ORDER BY amount, expense_id;


-- Q21.1: List expenses with employee, department and category names

SELECT
    ex.expense_id,
    emp.full_name,
    dep.name AS department_name,
    cat.category_name AS category_name,
    ex.amount,
    ex.occurred_on,
    ex.description,
    ex.status
FROM org.expenses AS ex
INNER JOIN org.employees AS emp
    ON ex.employee_id = emp.employee_id
INNER JOIN org.departments AS dep
    ON emp.department_id = dep.department_id
INNER JOIN org.categories AS cat
    ON ex.category_id = cat.category_id
ORDER BY ex.occurred_on, ex.expense_id;



-- Q21.2: List every employee and their expenses

SELECT
    emp.employee_id,
    emp.employee_code,
    emp.full_name,
    ex.expense_id,
    ex.amount,
    ex.occurred_on,
    ex.description
FROM org.employees AS emp
LEFT JOIN org.expenses AS ex
    ON emp.employee_id = ex.employee_id
ORDER BY
    emp.full_name,
    emp.employee_id,
    ex.occurred_on,
    ex.expense_id;

    
-- Q21.3 : List every employee and their expenses

SELECT
    emp.employee_id,
    emp.employee_code,
    emp.full_name,
    ex.expense_id,
    ex.amount,
    ex.occurred_on,
    ex.description
FROM org.employees AS emp
LEFT JOIN org.expenses AS ex
    ON emp.employee_id = ex.employee_id
ORDER BY
    emp.full_name,
    emp.employee_id,
    ex.occurred_on,
    ex.expense_id;





-- Q22.1 : LEFT JOIN with a condition in the WHERE clause

SELECT
    emp.employee_code,
    emp.full_name,
    ex.expense_id,
    ex.status,
    ex.amount
FROM org.employees AS emp
LEFT JOIN org.expenses AS ex
    ON emp.employee_id = ex.employee_id
WHERE ex.status = 'submitted'
ORDER BY emp.full_name, ex.expense_id;


-- Q22.2 : LEFT JOIN with the condition in the ON clause

SELECT
    emp.employee_code,
    emp.full_name,
    ex.expense_id,
    ex.status,
    ex.amount
FROM org.employees AS emp
LEFT JOIN org.expenses AS ex
    ON emp.employee_id = ex.employee_id
   AND ex.status = 'submitted'
ORDER BY emp.full_name, ex.expense_id;



-- Q22.3 : Compare filtering in WHERE and ON

SELECT
    'WHERE condition' AS filter_location,
    COUNT(DISTINCT emp.employee_id) AS employee_count,
    COUNT(ex.expense_id) AS expense_count
FROM org.employees AS emp
LEFT JOIN org.expenses AS ex
    ON emp.employee_id = ex.employee_id
WHERE ex.status = 'submitted'

UNION ALL

SELECT
    'ON condition' AS filter_location,
    COUNT(DISTINCT emp.employee_id) AS employee_count,
    COUNT(ex.expense_id) AS expense_count
FROM org.employees AS emp
LEFT JOIN org.expenses AS ex
    ON emp.employee_id = ex.employee_id
   AND ex.status = 'submitted';




-- Q23.1 : Display employees and their managers

SELECT
    emp.employee_code,
    emp.full_name AS employee_name,
    mgr.full_name AS manager_name
FROM org.employees AS emp
LEFT JOIN org.employees AS mgr
    ON emp.manager_id = mgr.employee_id
ORDER BY emp.full_name, emp.employee_id;



-- Q23.2: Find employees without a manager

SELECT
    employee_code,
    full_name
FROM org.employees
WHERE manager_id IS NULL
ORDER BY full_name, employee_id;



-- Q24: List employees and their project assignments

SELECT
    emp.employee_code,
    emp.full_name AS employee_name,
    p.name AS project_name,
    ep.assigned_on
FROM org.employee_projects AS ep
INNER JOIN org.employees AS emp
    ON ep.employee_id = emp.employee_id
INNER JOIN org.projects AS p
    ON ep.project_id = p.project_id
ORDER BY emp.full_name, p.name;



-- Q24: Find employees who have no project assignments

SELECT
    emp.employee_code,
    emp.full_name
FROM org.employees AS emp
WHERE NOT EXISTS (
    SELECT 1
    FROM org.employee_projects AS ep
    WHERE ep.employee_id = emp.employee_id
)
ORDER BY emp.full_name, emp.employee_id;



-- Q24: Generate a department-category reporting grid
SELECT
    d.name AS department_name,
    c.category_name AS category_name
FROM org.departments AS d
CROSS JOIN org.categories AS c
ORDER BY d.name, c.category_name;


-- Q24: Calculate the expected CROSS JOIN grid size
SELECT
    (SELECT COUNT(*) FROM org.departments) AS department_count,
    (SELECT COUNT(*) FROM org.categories) AS category_count,
    (SELECT COUNT(*) FROM org.departments)
        * (SELECT COUNT(*) FROM org.categories) AS expected_grid_rows;




-- Q25: Test aggregate functions when no rows match
SELECT
    COUNT(*) AS total_expense_rows,
    COUNT(description) AS expenses_with_description,
    SUM(amount) AS total_amount,
    AVG(amount) AS average_amount,
    MIN(amount) AS minimum_amount,
    MAX(amount) AS maximum_amount,
    COALESCE(SUM(amount), 0) AS total_amount_or_zero
FROM org.expenses
WHERE amount > 9999999999;




-- Q26.1 : Calculate expense count and total per category
SELECT
    c.category_id,
    c.category_name,
    COUNT(e.expense_id) AS expense_count,
    COALESCE(SUM(e.amount), 0) AS total_amount
FROM org.categories AS c
LEFT JOIN org.expenses AS e
    ON c.category_id = e.category_id
GROUP BY
    c.category_id,
    category_name
ORDER BY category_name;



-- Q26.2 : Calculate expense count and total by department and month
SELECT
    d.department_id,
    d.name AS department_name,
    DATE_TRUNC('month', e.occurred_on::timestamp) AS expense_month,
    COUNT(e.expense_id) AS expense_count,
    SUM(e.amount) AS total_amount
FROM org.departments AS d
INNER JOIN org.employees AS emp
    ON d.department_id = emp.department_id
INNER JOIN org.expenses AS e
    ON emp.employee_id = e.employee_id
GROUP BY
    d.department_id,
    d.name,
    DATE_TRUNC('month', e.occurred_on::timestamp)
ORDER BY
    d.name,
    expense_month;




-- Q27: Find categories meeting count and spending conditions
SELECT
    c.category_id,
    c.category_name,
    COUNT(e.expense_id) AS expense_count,
    SUM(e.amount) AS total_spend
FROM org.categories AS c
INNER JOIN org.expenses AS e
    ON c.category_id = e.category_id
WHERE e.status IN ('submitted', 'approved')
GROUP BY
    c.category_id,
    c.category_name
HAVING COUNT(e.expense_id) > 2
   AND SUM(e.amount) > 1000
ORDER BY total_spend DESC;




-- Q28.1: Find expenses above the overall average amount
SELECT
    expense_id,
    employee_id,
    amount,
    occurred_on,
    status
FROM org.expenses
WHERE amount > (
    SELECT AVG(amount)
    FROM org.expenses
)
ORDER BY amount DESC;



-- 28.2: Find employees who have no expenses
SELECT
    e.employee_id,
    e.employee_code,
    e.full_name
FROM org.employees AS e
WHERE NOT EXISTS (
    SELECT 1
    FROM org.expenses AS ex
    WHERE ex.employee_id = e.employee_id
)
ORDER BY e.employee_id;




-- Q29, Step 2: Find departments spending above the average
WITH department_totals AS (
    SELECT
        d.department_id,
        d.name AS department_name,
        COUNT(ex.expense_id) AS expense_count,
        COALESCE(SUM(ex.amount), 0) AS total_spend
    FROM org.departments AS d
    LEFT JOIN org.employees AS emp
        ON d.department_id = emp.department_id
    LEFT JOIN org.expenses AS ex
        ON emp.employee_id = ex.employee_id
    GROUP BY
        d.department_id,
        d.name
)
SELECT
    department_id,
    department_name,
    expense_count,
    total_spend
FROM department_totals
WHERE total_spend > (
    SELECT AVG(total_spend)
    FROM department_totals
)
ORDER BY total_spend DESC;



-- Q30, Step 1: Create a department spending view
CREATE OR REPLACE VIEW org.v_department_spend AS
SELECT
    d.department_id,
    d.name AS department_name,
    COUNT(ex.expense_id) AS expense_count,
    COALESCE(SUM(ex.amount), 0) AS total_amount
FROM org.departments AS d
LEFT JOIN org.employees AS emp
    ON d.department_id = emp.department_id
LEFT JOIN org.expenses AS ex
    ON emp.employee_id = ex.employee_id
GROUP BY
    d.department_id,
    d.name;


-- Q30, Step 2: Read the department spending view
SELECT
    department_id,
    department_name,
    expense_count,
    total_amount
FROM org.v_department_spend
ORDER BY department_id;




-- Q30, Step 3: Compare view totals with base expense totals
SELECT
    (SELECT COALESCE(SUM(total_amount), 0)
     FROM org.v_department_spend) AS view_total,

    (SELECT COALESCE(SUM(amount), 0)
     FROM org.expenses) AS expenses_table_total,

    (SELECT COALESCE(SUM(total_amount), 0)
     FROM org.v_department_spend)
    =
    (SELECT COALESCE(SUM(amount), 0)
     FROM org.expenses) AS totals_match;


-- Q31:
SELECT
    emp.employee_id,
    emp.full_name,
    c.category_id,
    c.category_name
FROM org.employees AS emp
CROSS JOIN org.categories AS c
ORDER BY emp.employee_id, c.category_id
LIMIT 5;

-- Insert a temporary expense and roll it back
BEGIN;

INSERT INTO org.expenses (
    employee_id,
    category_id,
    amount,
    occurred_on,
    description,
    status
)
VALUES (
    1,  -- replace with your actual employee ID
    2,  -- replace with your actual category ID
    1.00,
    CURRENT_DATE,
    'Temporary ACID rollback test',
    'submitted'
)
RETURNING expense_id, amount, description;

ROLLBACK;

-- verifying the rollback

SELECT expense_id, description
FROM org.expenses
WHERE description = 'Temporary ACID rollback test';


SELECT
    conname AS constraint_name,
    pg_get_constraintdef(oid) AS constraint_definition
FROM pg_constraint
WHERE conrelid = 'org.expenses'::regclass
ORDER BY conname;


--to check consistency
SHOW transaction_isolation;


-- Durabilty
SELECT
    emp.employee_id,
    emp.full_name,
    c.category_id,
    c.category_name
FROM org.employees AS emp
CROSS JOIN org.categories AS c
ORDER BY emp.employee_id, c.category_id
LIMIT 5;



BEGIN;

INSERT INTO org.expenses (
    employee_id,
    category_id,
    amount,
    occurred_on,
    description,
    status
)
VALUES (
    1,
    2,
    1.00,
    CURRENT_DATE,
    'Temporary ACID durability test',
    'submitted'
)
RETURNING expense_id, description;

COMMIT;

-- check the new inserted test values
SELECT expense_id, amount, description
FROM org.expenses
WHERE description = 'Temporary ACID durability test';

-- deleting the inserted test values
DELETE FROM org.expenses
WHERE description = 'Temporary ACID durability test'
RETURNING expense_id, description;



--32
SELECT
    COUNT(*) AS expense_count,
    COALESCE(SUM(amount), 0) AS total_amount
FROM org.expenses;


BEGIN;

INSERT INTO org.expenses
    (employee_id, category_id, amount, occurred_on, status, description)
VALUES
    (1, 2, 125.00, CURRENT_DATE, 'submitted',
     'Q32 temporary rollback test')
RETURNING expense_id, amount, status, description;

ROLLBACK;

UPDATE org.expenses
SET amount = -50.00
WHERE description = 'Q32 temporary rollback test';


SELECT
    COUNT(*) AS remaining_test_rows
FROM org.expenses
WHERE description = 'Q32 temporary rollback test';

-- testing again with commit
BEGIN;

INSERT INTO org.expenses
    (employee_id, category_id, amount, occurred_on, status, description)
VALUES
    (1, 2, 200.00, CURRENT_DATE, 'submitted',
     'Q32 temporary commit test')
RETURNING expense_id, amount, status, description;

UPDATE org.expenses
SET description = 'Q32 temporary commit test - updated'
WHERE description = 'Q32 temporary commit test'
RETURNING expense_id, amount, status, description;

COMMIT;

-- verify
SELECT
    expense_id,
    amount,
    status,
    description
FROM org.expenses
WHERE description = 'Q32 temporary commit test - updated';

-- to delete the test insert
DELETE FROM org.expenses
WHERE description = 'Q32 temporary commit test - updated'
RETURNING expense_id, amount, description;


-- Step 1: Begin a transaction and insert the first valid expense

BEGIN;

INSERT INTO org.expenses
    (employee_id, category_id, amount, occurred_on, status, description)
VALUES
    (1, 2, 150.00, CURRENT_DATE, 'submitted',
     'Q33 savepoint first valid test')
RETURNING expense_id, amount, status, description;

SAVEPOINT before_invalid_expense; -- created a savepoint

INSERT INTO org.expenses
    (employee_id, category_id, amount, occurred_on, status, description)
VALUES
    (1, 2, -75.00, CURRENT_DATE, 'submitted',
     'Q33 invalid expense test');

ROLLBACK to SAVEPOINT before_invalid_expense;

-- inserting  new valid expense data
INSERT INTO org.expenses
    (employee_id, category_id, amount, occurred_on, status, description)
VALUES
    (1, 2, 250.00, CURRENT_DATE, 'submitted',
     'Q33 savepoint second valid test')
RETURNING expense_id, amount, status, description;

COMMIT;

-- verifying both the valid data
SELECT
    expense_id,
    amount,
    status,
    description
FROM org.expenses
WHERE description IN (
    'Q33 savepoint first valid test',
    'Q33 savepoint second valid test',
    'Q33 invalid expense test'
)
ORDER BY expense_id;


-- Clean up the temporary records
DELETE FROM org.expenses
WHERE description IN (
    'Q33 savepoint first valid test',
    'Q33 savepoint second valid test',
    'Q33 invalid expense test'
)
RETURNING expense_id, amount, description;

-- verifying the cleanup
SELECT
    COUNT(*) AS remaining_test_rows
FROM org.expenses
WHERE description IN (
    'Q33 savepoint first valid test',
    'Q33 savepoint second valid test',
    'Q33 invalid expense test'
);



-- 36: Least Privilege Roles.

SELECT
    current_database() AS database_name,
    current_user AS current_user,
    session_user AS login_user;

-- Check the existing tables and sequences

SELECT
    table_name,
    table_type
FROM information_schema.tables
WHERE table_schema = 'org'
ORDER BY table_name;

SELECT
    sequence_name
FROM information_schema.sequences
WHERE sequence_schema = 'org'
ORDER BY sequence_name;


-- Check ID-generation strategies

SELECT
    table_name,
    column_name,
    data_type,
    column_default,
    is_identity
FROM information_schema.columns
WHERE table_schema = 'org'
  AND column_name LIKE '%id%'
ORDER BY table_name, ordinal_position;

-- 36.2 creating 2 roles
CREATE ROLE trainee_reader NOLOGIN;
CREATE ROLE trainee_writer NOLOGIN;

-- 36.3 connecting roles to database
GRANT CONNECT ON DATABASE org_expenses
TO trainee_reader, trainee_writer;

--36.4 granting schema usage
GRANT USAGE ON SCHEMA org
TO trainee_reader, trainee_writer;


--36.5 granting reader permission
GRANT SELECT ON ALL TABLES IN SCHEMA org
TO trainee_reader;

--36.6 granting writer permission
GRANT SELECT, INSERT, UPDATE, DELETE
ON ALL TABLES IN SCHEMA org
TO trainee_writer;

SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'org'
  AND table_type = 'BASE TABLE'
ORDER BY table_name;


-- Remove the broad table permissions
REVOKE SELECT ON ALL TABLES IN SCHEMA org
FROM trainee_reader;

REVOKE SELECT, INSERT, UPDATE, DELETE
ON ALL TABLES IN SCHEMA org
FROM trainee_writer;

-- Reader: read-only access to business tables
GRANT SELECT ON
    org.categories,
    org.departments,
    org.employee_profiles,
    org.employee_projects,
    org.employees,
    org.expenses,
    org.projects
TO trainee_reader;

-- Writer: read and modify business tables
GRANT SELECT, INSERT, UPDATE, DELETE ON
    org.categories,
    org.departments,
    org.employee_profiles,
    org.employee_projects,
    org.employees,
    org.expenses,
    org.projects
TO trainee_writer;


-- We granted USAGE on the five identity sequences to trainee_writer. 
-- Now let's verify that PostgreSQL recognizes those permissions.
SELECT
    table_name,
    column_name,
    pg_get_serial_sequence(
        format('%I.%I', table_schema, table_name),
        column_name
    ) AS sequence_name
FROM information_schema.columns
WHERE table_schema = 'org'
  AND is_identity = 'YES'
ORDER BY table_name, column_name;



SELECT
    grantee,
    table_name,
    privilege_type
FROM information_schema.role_table_grants
WHERE table_schema = 'org'
  AND grantee IN ('trainee_reader', 'trainee_writer')
ORDER BY grantee, table_name, privilege_type;

SELECT
    s.schemaname AS schema_name,
    s.sequencename AS sequence_name,
    has_sequence_privilege(
        'trainee_writer',
        format('%I.%I', s.schemaname, s.sequencename),
        'USAGE'
    ) AS writer_has_usage
FROM pg_sequences AS s
WHERE s.schemaname = 'org'
ORDER BY s.sequencename;



### testing reader

SET ROLE trainee_reader;

SELECT *
FROM org.departments
LIMIT 5;

RESET ROLE;

-- Verify the reader cannot insert

SET ROLE trainee_reader;

INSERT INTO org.categories (name)
VALUES ('Q36_permission_test');

RESET ROLE;



-- testing the trainer_writer
BEGIN;

SET LOCAL ROLE trainee_writer;

UPDATE org.categories
SET category_name = name
WHERE category_id = -1;

ROLLBACK;


-- Test the writer's INSERT permission

BEGIN;

SET LOCAL ROLE trainee_writer;

INSERT INTO org.categories (category_name)
VALUES ('Q36_permission_test');

ROLLBACK;


-- to Verify the writer cannot create tables

SET ROLE trainee_writer;

CREATE TABLE org.q36_permission_test (
    test_id INTEGER
);

RESET ROLE;


-- Verify the current role

RESET ROLE;

SELECT
    current_user,
    session_user;


SELECT
    rolname,
    rolsuper,
    rolcreatedb,
    rolcreaterole,
    rolcanlogin
FROM pg_roles
WHERE rolname IN ('trainee_reader', 'trainee_writer')
ORDER BY rolname;




-- Q37. Revoke and Restore Table Permissions
-- deleting the delete acces to the trainer_writer for a check
REVOKE DELETE
ON TABLE org.expenses
FROM trainee_writer;

--testing
SET ROLE trainee_writer;

DELETE FROM org.expenses
WHERE expense_id = -1;

RESET ROLE;

-- reseting the delete access
GRANT DELETE
ON TABLE org.expenses
TO trainee_writer;




-- 38 


SELECT
    schemaname,
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname = 'org'
ORDER BY tablename, indexname;




-- Q38: Inspect the columns in the expenses table.
-- Purpose: Identify the columns and data types before choosing indexes.
-- This query only reads metadata; it does not modify the database.

SELECT
    column_name,      -- Name of each column
    data_type,        -- Data type, such as integer, date, or text
    is_nullable,      -- Whether NULL values are allowed
    column_default    -- Default value, if one is defined
FROM information_schema.columns
WHERE table_schema = 'org'   -- Inspect the org schema
  AND table_name = 'expenses' -- Inspect the expenses table
ORDER BY ordinal_position;   -- Display columns in their defined order


-- Q38: Create a composite index for employee expense history.
-- Purpose: Speed up queries filtering by employee_id and occurred_on.
-- Column order matters: employee_id is the leading column.
-- IF NOT EXISTS avoids creating another index with the same name.

CREATE INDEX IF NOT EXISTS idx_expenses_employee_occurred_on
ON org.expenses (employee_id, occurred_on);



-- Q38: Create an expression index for case-insensitive description searches.
-- Purpose: Index the lowercase version of each description.
-- Benefit: Can help queries that use LOWER(description) in their filter.
-- NULL descriptions are permitted, but do not match ordinary text searches.

CREATE INDEX IF NOT EXISTS idx_expenses_lower_description
ON org.expenses (LOWER(description));




-- Q38: Verify indexes on the expenses table.
-- Purpose: List existing and newly created indexes for org.expenses.
-- This query reads metadata and does not modify any data.

SELECT
    indexname,  -- Name of the index
    indexdef    -- Definition, including indexed columns and conditions
FROM pg_indexes
WHERE schemaname = 'org'
  AND tablename = 'expenses'
ORDER BY indexname;




-- Q39, Step 1: Check the current database and user.
-- Purpose: Confirm where the query editor is connected.
-- We need to keep performance experiments separate
-- from the baseline org_expenses database.

SELECT
    current_database() AS current_database,
    current_user AS current_user;



-- Q39, Step 2: Create a separate database for performance testing.
-- Purpose: Keep synthetic benchmark data separate from org_expenses.
-- Run this while connected to a database other than performance_expenses.
-- CREATE DATABASE must not run inside a transaction block.

CREATE DATABASE performance_expenses;



-- Q39, Step 4: Verify the active database.
-- All benchmark tables and generated expenses must stay
-- in the disposable performance database, not org_expenses.

SELECT
    current_database() AS current_database,
    current_user AS current_user;




-- Q39, Step 5: Create the benchmark schema and tables.
-- IMPORTANT: Run this only in performance_expenses.
-- These tables are isolated from the baseline org_expenses database.

-- Create the schema for benchmark objects.
CREATE SCHEMA IF NOT EXISTS org;

-- Create departments for employee foreign keys.
CREATE TABLE org.departments (
    department_id INTEGER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE
);

-- Create employees with a required department reference.
CREATE TABLE org.employees (
    employee_id INTEGER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    employee_code VARCHAR(30) NOT NULL UNIQUE,
    full_name VARCHAR(150) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    department_id INTEGER NOT NULL
        REFERENCES org.departments(department_id)
);

-- Create expenses using the assignment's key data rules.
CREATE TABLE org.expenses (
    expense_id BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    employee_id INTEGER NOT NULL
        REFERENCES org.employees(employee_id),
    category_id INTEGER NOT NULL,
    amount NUMERIC(12,2) NOT NULL CHECK (amount > 0),
    occurred_on DATE NOT NULL,
    description TEXT,
    status VARCHAR(20) NOT NULL DEFAULT 'draft'
        CHECK (status IN ('draft', 'submitted', 'approved', 'rejected')),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);




-- Q39, Step 6: Create categories and enforce the category foreign key.
-- Run this only in the performance_expenses database.

-- Create categories for the synthetic benchmark expenses.
CREATE TABLE org.categories (
    category_id INTEGER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    category_name VARCHAR(100) NOT NULL UNIQUE
);

-- Ensure every expense references an existing category.
ALTER TABLE org.expenses
ADD CONSTRAINT expenses_category_id_fkey
FOREIGN KEY (category_id)
REFERENCES org.categories(category_id);



-- Q39, Step 7: Insert supporting benchmark data.
-- Run this only in the performance_expenses database.
-- These are synthetic records, separate from the baseline project.

-- 1. Create four departments.
INSERT INTO org.departments (name)
SELECT 'Perf Department ' || n
FROM generate_series(1, 4) AS n;

-- 2. Create ten expense categories.
INSERT INTO org.categories (category_name)
SELECT 'Perf Category ' || n
FROM generate_series(1, 10) AS n;

-- 3. Create 100 employees, distributed across four departments.
INSERT INTO org.employees
    (employee_code, full_name, email, department_id)
SELECT
    'PERF-E' || lpad(n::text, 4, '0'),
    'Performance Employee ' || n,
    'perf-e' || lpad(n::text, 4, '0') || '@example.test',
    d.department_id
FROM generate_series(1, 100) AS n
JOIN org.departments AS d
    ON d.name = 'Perf Department ' || (((n - 1) % 4) + 1);

-- 4. Verify the supporting records.
SELECT 'departments' AS record_type, COUNT(*) AS total
FROM org.departments
WHERE name LIKE 'Perf Department %'

UNION ALL

SELECT 'categories', COUNT(*)
FROM org.categories
WHERE category_name LIKE 'Perf Category %'

UNION ALL

SELECT 'employees', COUNT(*)
FROM org.employees
WHERE employee_code LIKE 'PERF-E%';




-- Q39, Step 8: Generate exactly 50,000 synthetic expenses.
-- Run this only in the performance_expenses database.
-- Each expense uses an existing employee and category.
-- The generated amounts are positive and the statuses are valid.

INSERT INTO org.expenses
    (employee_id, category_id, amount, occurred_on, description, status)
SELECT
    e.employee_id,
    c.category_id,
    ((g.n % 50000) + 100)::numeric / 10,
    DATE '2026-01-01' + (g.n % 270),
    'Synthetic performance expense ' || g.n,
    CASE g.n % 4
        WHEN 0 THEN 'draft'
        WHEN 1 THEN 'submitted'
        WHEN 2 THEN 'approved'
        ELSE 'rejected'
    END
FROM generate_series(1, 50000) AS g(n)
JOIN org.employees AS e
    ON e.employee_code =
       'PERF-E' || lpad((((g.n - 1) % 100) + 1)::text, 4, '0')
JOIN org.categories AS c
    ON c.category_name = 'Perf Category ' || (((g.n - 1) % 10) + 1);



-- Q39, Step 9: Verify the synthetic expense data.
-- Confirm that the benchmark data satisfies the expected rules.

-- Check the total number of expenses.
SELECT COUNT(*) AS total_expenses
FROM org.expenses;

-- Check that all amounts are positive.
SELECT COUNT(*) AS invalid_amounts
FROM org.expenses
WHERE amount <= 0;

-- Check that every expense has an allowed status.
SELECT COUNT(*) AS invalid_statuses
FROM org.expenses
WHERE status NOT IN ('draft', 'submitted', 'approved', 'rejected');

-- Check the date range and employee coverage.
SELECT
    MIN(occurred_on) AS earliest_expense,
    MAX(occurred_on) AS latest_expense,
    COUNT(DISTINCT employee_id) AS employees_with_expenses
FROM org.expenses;



-- Q39, Step 10.1: Find the benchmark employee's actual ID.
SELECT employee_id, employee_code
FROM org.employees
WHERE employee_code = 'PERF-E0001';



-- Q39, Step 10.2: Measure expense lookup before creating the index.
-- EXPLAIN ANALYZE executes the SELECT and reports actual performance.
-- BUFFERS reports the database pages accessed during execution.

EXPLAIN (ANALYZE, BUFFERS)
SELECT expense_id, employee_id, occurred_on, amount
FROM org.expenses
WHERE employee_id = 1
  AND occurred_on >= DATE '2026-03-01'
  AND occurred_on < DATE '2026-03-08';



-- Q39, Step 11: Create a composite index for employee/date searches.
-- This index belongs only to the disposable performance database.
CREATE INDEX idx_perf_expenses_employee_occurred_on
ON org.expenses (employee_id, occurred_on);

-- Refresh statistics so PostgreSQL can estimate row counts.
ANALYZE org.expenses;




-- Q39, Step 12: Measure expense lookup after creating the index.
-- Keep the filters identical to the before-index query.
-- EXPLAIN ANALYZE executes the SELECT and reports actual timings.

EXPLAIN (ANALYZE, BUFFERS)
SELECT expense_id, employee_id, occurred_on, amount
FROM org.expenses
WHERE employee_id = 1
  AND occurred_on >= DATE '2026-03-01'
  AND occurred_on < DATE '2026-03-08';




-- Q39, Step 13: Repeat the after-index benchmark.
-- Keep the query identical so the measurements remain comparable.

EXPLAIN (ANALYZE, BUFFERS)
SELECT expense_id, employee_id, occurred_on, amount
FROM org.expenses
WHERE employee_id = 1
  AND occurred_on >= DATE '2026-03-01'
  AND occurred_on < DATE '2026-03-08';



-- Q39, Step 15.1: Temporarily remove the benchmark index.
-- Run this only in performance_expenses.
-- This does not delete any expense data.

DROP INDEX org.idx_perf_expenses_employee_occurred_on;

-- Refresh table statistics for the benchmark.
ANALYZE org.expenses;



-- Q39, Step 15.2: Repeat the query without the benchmark index.

EXPLAIN (ANALYZE, BUFFERS)
SELECT expense_id, employee_id, occurred_on, amount
FROM org.expenses
WHERE employee_id = 1
  AND occurred_on >= DATE '2026-03-01'
  AND occurred_on < DATE '2026-03-08';



-- Q39, Step 16: Restore the composite performance index.
-- Recreate the index after completing the before-index tests.

CREATE INDEX idx_perf_expenses_employee_occurred_on
ON org.expenses (employee_id, occurred_on);

-- Refresh statistics after restoring the index.
ANALYZE org.expenses;

-- Verify that the index exists.
SELECT indexname, indexdef
FROM pg_indexes
WHERE schemaname = 'org'
  AND indexname = 'idx_perf_expenses_employee_occurred_on';




-- Q41: Check whether the expense_band function already exists.
SELECT
    current_database() AS database_name,
    n.nspname AS schema_name,
    p.proname AS function_name,
    pg_get_function_identity_arguments(p.oid) AS arguments,
    pg_get_function_result(p.oid) AS return_type
FROM pg_proc AS p
JOIN pg_namespace AS n
    ON n.oid = p.pronamespace
WHERE n.nspname = 'org'
  AND p.proname = 'expense_band';


-- Q41: Create a function to classify expenses by amount.
-- Small:  amount < 500
-- Medium: amount >= 500 and amount < 2000
-- Large:  amount >= 2000
-- NULL input returns NULL.
-- Zero or negative amounts raise an exception.

CREATE OR REPLACE FUNCTION org.expense_band(p_amount NUMERIC)
RETURNS TEXT
LANGUAGE plpgsql
IMMUTABLE
AS $$
BEGIN
    -- Handle NULL input.
    IF p_amount IS NULL THEN
        RETURN NULL;
    END IF;

    -- Reject zero and negative amounts.
    IF p_amount <= 0 THEN
        RAISE EXCEPTION
            'Expense amount must be positive. Received: %',
            p_amount;
    END IF;

    -- Classify the expense amount.
    IF p_amount < 500 THEN
        RETURN 'Small';
    ELSIF p_amount < 2000 THEN
        RETURN 'Medium';
    ELSE
        RETURN 'Large';
    END IF;
END;
$$;


-- Q42: Create the writer role if it does not already exist.
-- LOGIN allows the role to connect when configured with authentication.
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_roles WHERE rolname = 'trainee_writer'
    ) THEN
        CREATE ROLE trainee_writer LOGIN;
    END IF;
END
$$;

-- Q42: Create a non-login owner for the audit function.
-- This role will own the SECURITY DEFINER function.
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_roles WHERE rolname = 'expense_audit_owner'
    ) THEN
        CREATE ROLE expense_audit_owner NOLOGIN;
    END IF;
END
$$;

-- Verify that both roles now exist.
SELECT rolname, rolcanlogin, rolsuper, rolcreatedb
FROM pg_roles
WHERE rolname IN ('trainee_writer', 'expense_audit_owner')
ORDER BY rolname;


-- Q42: Create a table to record INSERT, UPDATE, and DELETE operations.
-- Deliberately omit a foreign key to org.expenses so audit history
-- remains available even after an expense is deleted.

CREATE TABLE IF NOT EXISTS org.expense_audit (
    audit_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    expense_id BIGINT NOT NULL,

    operation_type TEXT NOT NULL
        CHECK (operation_type IN ('INSERT', 'UPDATE', 'DELETE')),

    old_data JSONB,
    new_data JSONB,

    changed_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),

    actor_role NAME NOT NULL,
    definer_role NAME NOT NULL
);

-- Verify that the audit table exists and inspect its columns.
SELECT
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'org'
  AND table_name = 'expense_audit'
ORDER BY ordinal_position;


-- Q42: Allow the audit owner role to access the org schema.
GRANT USAGE ON SCHEMA org TO expense_audit_owner;

-- Allow the audit owner role to insert audit records.
GRANT INSERT ON TABLE org.expense_audit TO expense_audit_owner;

-- Allow the audit owner role to generate audit IDs.
GRANT USAGE, SELECT
ON SEQUENCE org.expense_audit_audit_id_seq
TO expense_audit_owner;

-- Allow the writer role to use the org schema.
GRANT USAGE ON SCHEMA org TO trainee_writer;

-- Allow the writer role to perform the required expense operations.
GRANT SELECT, INSERT, UPDATE, DELETE
ON TABLE org.expenses TO trainee_writer;

-- Prevent the writer from creating objects in the org schema.
REVOKE CREATE ON SCHEMA org FROM trainee_writer;

-- Remove any direct privileges on the audit table from the writer.
REVOKE ALL PRIVILEGES
ON TABLE org.expense_audit
FROM trainee_writer;

-- Remove direct access to the audit ID sequence from the writer.
REVOKE ALL PRIVILEGES
ON SEQUENCE org.expense_audit_audit_id_seq
FROM trainee_writer;


-- Q42: Verify schema and table privileges.
SELECT
    has_schema_privilege('trainee_writer', 'org', 'USAGE')
        AS writer_can_use_schema,
    has_schema_privilege('trainee_writer', 'org', 'CREATE')
        AS writer_can_create_objects,
    has_table_privilege('trainee_writer', 'org.expenses', 'INSERT')
        AS writer_can_insert_expenses,
    has_table_privilege('trainee_writer', 'org.expense_audit', 'INSERT')
        AS writer_can_insert_audit,
    has_table_privilege('trainee_writer', 'org.expense_audit', 'UPDATE')
        AS writer_can_update_audit;


-- Q42: Create a secure function to audit expense changes.
CREATE OR REPLACE FUNCTION org.write_expense_audit()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $$
DECLARE
    v_actor_role NAME;
BEGIN
    -- Record the active role, falling back to the session login.
    v_actor_role :=
        COALESCE(
            NULLIF(current_setting('role', true), 'none'),
            session_user::text
        )::name;

    -- Record inserted expenses.
    IF TG_OP = 'INSERT' THEN
        INSERT INTO org.expense_audit (
            expense_id, operation_type, old_data, new_data,
            changed_at, actor_role, definer_role
        )
        VALUES (
            NEW.expense_id, TG_OP, NULL, to_jsonb(NEW),
            clock_timestamp(), v_actor_role, current_user
        );

        RETURN NEW;

    -- Record changes before and after an update.
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO org.expense_audit (
            expense_id, operation_type, old_data, new_data,
            changed_at, actor_role, definer_role
        )
        VALUES (
            NEW.expense_id, TG_OP, to_jsonb(OLD), to_jsonb(NEW),
            clock_timestamp(), v_actor_role, current_user
        );

        RETURN NEW;

    -- Record deleted expenses before they disappear.
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO org.expense_audit (
            expense_id, operation_type, old_data, new_data,
            changed_at, actor_role, definer_role
        )
        VALUES (
            OLD.expense_id, TG_OP, to_jsonb(OLD), NULL,
            clock_timestamp(), v_actor_role, current_user
        );

        RETURN OLD;
    END IF;

    RAISE EXCEPTION 'Unsupported audit operation: %', TG_OP;
END;
$$;

-- Q42: Make the dedicated non-login role the function owner.
ALTER FUNCTION org.write_expense_audit()
OWNER TO expense_audit_owner;

-- Prevent public users from calling the trigger function directly.
REVOKE ALL
ON FUNCTION org.write_expense_audit()
FROM PUBLIC;

-- Prevent trainee_writer from calling it directly.
REVOKE ALL
ON FUNCTION org.write_expense_audit()
FROM trainee_writer;


-- Q42: Audit every inserted, updated, or deleted expense.
DROP TRIGGER IF EXISTS trg_expenses_audit ON org.expenses;

CREATE TRIGGER trg_expenses_audit
AFTER INSERT OR UPDATE OR DELETE
ON org.expenses
FOR EACH ROW
EXECUTE FUNCTION org.write_expense_audit();

-- Q42: Verify the function security settings.
SELECT
    p.proname AS function_name,
    pg_get_userbyid(p.proowner) AS function_owner,
    p.prosecdef AS is_security_definer,
    p.proconfig AS function_settings
FROM pg_proc AS p
JOIN pg_namespace AS n
    ON n.oid = p.pronamespace
WHERE n.nspname = 'org'
  AND p.proname = 'write_expense_audit';

-- Q42: Verify the audit trigger.
SELECT
    trigger_name,
    event_manipulation,
    action_timing
FROM information_schema.triggers
WHERE event_object_schema = 'org'
  AND event_object_table = 'expenses'
  AND trigger_name = 'trg_expenses_audit'
ORDER BY event_manipulation;


-- Q42: Find valid foreign-key values for a temporary test expense.
SELECT
    (SELECT employee_id FROM org.employees ORDER BY employee_id LIMIT 1)
        AS test_employee_id,
    (SELECT category_id FROM org.categories ORDER BY category_id LIMIT 1)
        AS test_category_id;


-- Find valid employee and category IDs for the Q42 test.
SELECT
    (SELECT employee_id
     FROM org.employees
     ORDER BY employee_id
     LIMIT 1) AS test_employee_id,

    (SELECT category_id
     FROM org.categories
     ORDER BY category_id
     LIMIT 1) AS test_category_id;



-- Q42: Test INSERT, UPDATE, and DELETE audit events safely.
-- The final ROLLBACK removes both the test expense and its audit rows.

BEGIN;

-- 1. Insert a temporary test expense.
INSERT INTO org.expenses (
    employee_id,
    category_id,
    amount,
    occurred_on,
    description,
    status
)
VALUES (
    1,
    1,
    123.45,
    CURRENT_DATE,
    'Q42 audit test - rollback',
    'draft'
)
RETURNING expense_id;

-- 2. Update the temporary expense.
UPDATE org.expenses
SET description = 'Q42 audit test - updated'
WHERE description = 'Q42 audit test - rollback';

-- 3. Delete the temporary expense.
DELETE FROM org.expenses
WHERE description = 'Q42 audit test - updated';

-- 4. Inspect the three audit events before rolling back.
SELECT
    audit_id,
    expense_id,
    operation_type,
    actor_role,
    definer_role,
    old_data ->> 'description' AS old_description,
    new_data ->> 'description' AS new_description
FROM org.expense_audit
WHERE old_data ->> 'description' LIKE 'Q42 audit test%'
   OR new_data ->> 'description' LIKE 'Q42 audit test%'
ORDER BY audit_id;

-- 5. Remove all test changes.
ROLLBACK;



-- Q42: Verify that trainee_writer cannot directly modify audit records.
SELECT
    has_table_privilege(
        'trainee_writer',
        'org.expense_audit',
        'SELECT'
    ) AS can_read_audit,
    has_table_privilege(
        'trainee_writer',
        'org.expense_audit',
        'INSERT'
    ) AS can_insert_audit,
    has_table_privilege(
        'trainee_writer',
        'org.expense_audit',
        'UPDATE'
    ) AS can_update_audit,
    has_table_privilege(
        'trainee_writer',
        'org.expense_audit',
        'DELETE'
    ) AS can_delete_audit;


-- Q42: Begin a transaction for the writer-role audit test.
BEGIN;

-- Switch to the trainee_writer role.
SET LOCAL ROLE trainee_writer;

-- Confirm the active role.
SELECT current_user;


-- Q42: Update one existing expense without changing its business data.
-- This changes only the description, and the transaction will be rolled back.
UPDATE org.expenses
SET description = COALESCE(description, '') || ' [Q42 audit test]'
WHERE expense_id = (
    SELECT expense_id
    FROM org.expenses
    WHERE status = 'draft'
    ORDER BY expense_id
    LIMIT 1
)
RETURNING expense_id, description, status;


-- Q42: Switch back to the session role to inspect the audit record.
RESET ROLE;

-- Find the audit record for the test update.
SELECT
    audit_id,
    expense_id,
    operation_type,
    actor_role,
    definer_role,
    old_data ->> 'description' AS old_description,
    new_data ->> 'description' AS new_description,
    changed_at
FROM org.expense_audit
WHERE operation_type = 'UPDATE'
  AND new_data ->> 'description' LIKE '%[Q42 audit test]%'
ORDER BY audit_id DESC
LIMIT 5;

-- Q42: Remove the temporary test update and its audit record.
ROLLBACK;

-- Q43: Protect approved expenses and refresh updated_at.
CREATE OR REPLACE FUNCTION org.protect_approved_expense()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    -- Prevent changes to protected fields for approved expenses.
    IF OLD.status = 'approved' THEN
        IF NEW.amount IS DISTINCT FROM OLD.amount
           OR NEW.category_id IS DISTINCT FROM OLD.category_id
           OR NEW.employee_id IS DISTINCT FROM OLD.employee_id
           OR NEW.occurred_on IS DISTINCT FROM OLD.occurred_on
           OR NEW.status IS DISTINCT FROM OLD.status
        THEN
            RAISE EXCEPTION
                'Approved expenses cannot change amount, category, employee, date, or status. Description edits are allowed.';
        END IF;
    END IF;

    -- Refresh the timestamp for every accepted update.
    NEW.updated_at := clock_timestamp();

    RETURN NEW;
END;
$$;


-- Q43: Apply protection before every expense update.
CREATE TRIGGER trg_protect_approved_expense
BEFORE UPDATE ON org.expenses
FOR EACH ROW
EXECUTE FUNCTION org.protect_approved_expense();

-- Q43: Confirm the protection trigger is installed.
SELECT
    trigger_name,
    event_manipulation,
    action_timing
FROM information_schema.triggers
WHERE event_object_schema = 'org'
  AND event_object_table = 'expenses'
  AND trigger_name = 'trg_protect_approved_expense';


-- Q43: Select an approved expense for testing.
SELECT
    expense_id,
    amount,
    category_id,
    employee_id,
    occurred_on,
    description,
    status,
    updated_at
FROM org.expenses
WHERE status = 'approved'
ORDER BY expense_id
LIMIT 1;


-- Q43: Begin a transaction for the protection test.
BEGIN;

-- Test that a description-only edit is allowed.
UPDATE org.expenses
SET description = COALESCE(description, '') || ' [Q43 test]'
WHERE expense_id = 5
  AND status = 'approved'
RETURNING
    expense_id,
    description,
    updated_at;

-- Q43: This should raise an exception for an approved expense.
UPDATE org.expenses
SET amount = amount + 1
WHERE expense_id = 5;

-- Q43: Discard all test changes.
ROLLBACK;





-- Q44 Step 1: Confirm the database and inspect expense statuses.
-- This query only reads data; it does not modify anything.

SELECT
    current_database() AS database_name,
    status,
    COUNT(*) AS expense_count
FROM org.expenses
GROUP BY status
ORDER BY status;


-- Q44: Create a procedure to submit a draft expense.
-- Only expenses with status 'draft' can be submitted.
-- Missing IDs and expenses in other states raise clear errors.

CREATE OR REPLACE PROCEDURE org.submit_expense(
    p_expense_id BIGINT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_status TEXT;
BEGIN
    -- Find the current status of the requested expense.
    SELECT status
    INTO v_status
    FROM org.expenses
    WHERE expense_id = p_expense_id
    FOR UPDATE;

    -- Raise an error if the expense does not exist.
    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Expense ID % does not exist.', p_expense_id;
    END IF;

    -- Only draft expenses can be submitted.
    IF v_status IS DISTINCT FROM 'draft' THEN
        RAISE EXCEPTION
            'Cannot submit expense ID % because its status is "%". Only draft expenses can be submitted.',
            p_expense_id, v_status;
    END IF;

    -- Change the status to submitted.
    -- Existing audit and updated_at triggers should run automatically.
    UPDATE org.expenses
    SET status = 'submitted'
    WHERE expense_id = p_expense_id;

    -- The caller controls COMMIT or ROLLBACK.
END;
$$;



-- Q44 Step 3A: Find a draft expense to use for testing.
-- This query only reads data.

SELECT expense_id, status, amount, description
FROM org.expenses
WHERE status = 'draft'
ORDER BY expense_id
LIMIT 1;



-- Q44 Step 4: Test the procedure without permanently changing data.
-- Expense ID 1 was identified as a draft expense.
-- ROLLBACK restores its original status and rolls back the audit row too.

BEGIN;

CALL org.submit_expense(1);

-- Verify the status change inside this transaction.
SELECT expense_id, status, updated_at
FROM org.expenses
WHERE expense_id = 1;

-- Undo the test so the baseline data stays unchanged.
ROLLBACK;

-- Confirm the original status after rollback.
SELECT expense_id, status, updated_at
FROM org.expenses
WHERE expense_id = 1;


-- Q44 Step 5A: Find an approved expense for the rejection test.
-- This query only reads data.

SELECT expense_id, status
FROM org.expenses
WHERE status = 'approved'
ORDER BY expense_id
LIMIT 1;


-- Q44: An ID that does not exist should raise an exception.
CALL org.submit_expense(-999999);


-- Q44: Approved expenses must not be submitted again.
-- Expense ID 5 was identified as approved.
CALL org.submit_expense(5);




-- Q45 Step 1: Inspect the columns needed for the monthly spending report.
-- This query reads PostgreSQL metadata and does not change data.

SELECT
    table_name,
    column_name,
    data_type
FROM information_schema.columns
WHERE table_schema = 'org'
  AND table_name IN ('expenses', 'employees', 'departments')
ORDER BY table_name, ordinal_position;



-- Q45 Step 2: Calculate monthly spending for each employee.
-- Grouping by employee and month ensures one row per employee per month.
-- Only approved expenses are included in the spending report.

SELECT
    e.employee_id,
    e.full_name,
    d.name AS department_name,
    DATE_TRUNC('month', x.occurred_on)::date AS expense_month,
    SUM(x.amount) AS monthly_spending
FROM org.expenses AS x
JOIN org.employees AS e
    ON e.employee_id = x.employee_id
JOIN org.departments AS d
    ON d.department_id = e.department_id
WHERE x.status = 'approved'
GROUP BY
    e.employee_id,
    e.full_name,
    d.name,
    DATE_TRUNC('month', x.occurred_on)::date
ORDER BY
    department_name,
    expense_month,
    monthly_spending DESC,
    e.employee_id;





-- Q45 Step 3: Rank monthly spending within each department and month.
-- DENSE_RANK assigns equal ranks to employees with equal spending.
-- SUM OVER calculates each employee's running total across months.
-- The explicit ROWS frame defines how the running total accumulates.

WITH monthly_spending AS (
    SELECT
        e.employee_id,
        e.full_name,
        d.name AS department_name,
        DATE_TRUNC('month', x.occurred_on)::date AS expense_month,
        SUM(x.amount) AS monthly_spending
    FROM org.expenses AS x
    JOIN org.employees AS e
        ON e.employee_id = x.employee_id
    JOIN org.departments AS d
        ON d.department_id = e.department_id
    WHERE x.status = 'approved'
    GROUP BY
        e.employee_id,
        e.full_name,
        d.name,
        DATE_TRUNC('month', x.occurred_on)::date
)
SELECT
    employee_id,
    full_name,
    department_name,
    expense_month,
    monthly_spending,

    -- Rank employees within each department and month.
    DENSE_RANK() OVER (
        PARTITION BY department_name, expense_month
        ORDER BY monthly_spending DESC
    ) AS spending_rank,

    -- Running total for each employee across months.
    SUM(monthly_spending) OVER (
        PARTITION BY employee_id
        ORDER BY expense_month, employee_id
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_total

FROM monthly_spending
ORDER BY
    department_name,
    expense_month,
    spending_rank,
    employee_id;



-- ============================================================
-- Q46: Verify the row counts in all seven core tables
-- ============================================================

-- Confirm the database first.
SELECT current_database();

-- Check the number of rows in each table.
SELECT 'departments' AS table_name, COUNT(*) AS row_count
FROM org.departments

UNION ALL

SELECT 'categories', COUNT(*)
FROM org.categories

UNION ALL

SELECT 'employees', COUNT(*)
FROM org.employees

UNION ALL

SELECT 'employee_profiles', COUNT(*)
FROM org.employee_profiles

UNION ALL

SELECT 'projects', COUNT(*)
FROM org.projects

UNION ALL

SELECT 'employee_projects', COUNT(*)
FROM org.employee_projects

UNION ALL

SELECT 'expenses', COUNT(*)
FROM org.expenses

ORDER BY table_name;




-- ============================================================
-- Q46: Verify foreign-key constraints
-- ============================================================

SELECT
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS referenced_table,
    ccu.column_name AS referenced_column,
    tc.constraint_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
   AND tc.constraint_schema = kcu.constraint_schema
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
   AND ccu.constraint_schema = tc.constraint_schema
WHERE tc.constraint_type = 'FOREIGN KEY'
  AND tc.constraint_schema = 'org'
ORDER BY
    tc.table_name,
    kcu.column_name;



-- ============================================================
-- Q46: Check expense records for orphaned references
-- ============================================================

-- Both counts should be zero.
-- An orphaned reference means an expense points to a
-- nonexistent employee or category.

SELECT
    COUNT(*) FILTER (
        WHERE emp.employee_id IS NULL
    ) AS expenses_with_missing_employees,

    COUNT(*) FILTER (
        WHERE cat.category_id IS NULL
    ) AS expenses_with_missing_categories

FROM org.expenses AS e
LEFT JOIN org.employees AS emp
    ON e.employee_id = emp.employee_id
LEFT JOIN org.categories AS cat
    ON e.category_id = cat.category_id;



-- Q46: Check employee-project assignment integrity
-- Both counts should be zero.

SELECT
    COUNT(*) FILTER (
        WHERE emp.employee_id IS NULL
    ) AS assignments_with_missing_employees,

    COUNT(*) FILTER (
        WHERE p.project_id IS NULL
    ) AS assignments_with_missing_projects

FROM org.employee_projects AS ep
LEFT JOIN org.employees AS emp
    ON ep.employee_id = emp.employee_id
LEFT JOIN org.projects AS p
    ON ep.project_id = p.project_id;


-- Q46: Check expense data validity
-- Both counts should be zero.

SELECT
    COUNT(*) FILTER (
        WHERE amount IS NULL OR amount <= 0
    ) AS invalid_amounts,

    COUNT(*) FILTER (
        WHERE status IS NULL
           OR status NOT IN (
               'draft',
               'submitted',
               'approved',
               'rejected'
           )
    ) AS invalid_statuses

FROM org.expenses;