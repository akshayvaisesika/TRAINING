
-- Q07: Create the org schema.
-- Run this while connected to the org_expenses database.

CREATE SCHEMA IF NOT EXISTS org;

-- Verify that the schema exists.
SELECT schema_name FROM information_schema.schemata WHERE schema_name = 'org';
