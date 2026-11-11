-- ============================================================
-- Q38: Index Selection and Justification
-- Database: org_expenses
-- Schema: org
-- Purpose: Add indexes for selected query workloads.
-- ============================================================

-- 1. Composite index for employee expense history.
-- Supports filtering by employee_id and then occurred_on.
-- The leading column is employee_id.

CREATE INDEX IF NOT EXISTS idx_expenses_employee_occurred_on
ON org.expenses (employee_id, occurred_on);


-- 2. Partial index for submitted expenses.
-- Includes only rows where status = 'submitted'.
-- Supports submitted-expense queries filtered or ordered by date.

CREATE INDEX IF NOT EXISTS idx_expenses_submitted
ON org.expenses (occurred_on)
WHERE status = 'submitted';


-- 3. Expression index for case-normalized description lookups.
-- Supports compatible queries using LOWER(description),
-- especially exact-match and prefix-match searches.
-- It does not generally accelerate leading-wildcard searches.

CREATE INDEX IF NOT EXISTS idx_expenses_lower_description
ON org.expenses (LOWER(description));


-- 4. Verify indexes on the expenses table.
-- This query lists existing and newly created indexes.

SELECT
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname = 'org'
  AND tablename = 'expenses'
ORDER BY indexname;




