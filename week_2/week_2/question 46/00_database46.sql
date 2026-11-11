-- Q46: Disposable database for the clean rebuild.
-- Execute this command while connected to another database,
-- such as postgres, not while connected to org_expenses.

CREATE DATABASE org_expenses_q46;


-- Confirm that both databases exist.
SELECT datname
FROM pg_database
WHERE datname IN ('org_expenses', 'org_expenses_q46')
ORDER BY datname;
