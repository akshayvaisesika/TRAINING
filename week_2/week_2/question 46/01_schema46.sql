
-- Q46: Create the org schema in the disposable database.
-- Run this script while connected to org_expenses_q46.
-- This does not modify the original org_expenses database.

CREATE SCHEMA IF NOT EXISTS org;

-- Verify that the schema exists.
SELECT schema_name
FROM information_schema.schemata
WHERE schema_name = 'org';
