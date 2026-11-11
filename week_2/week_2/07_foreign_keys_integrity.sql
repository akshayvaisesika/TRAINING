
-- ============================================================
-- Q40: Foreign Keys and Integrity
-- Database: performance_expenses
-- Purpose:
-- 1. Inspect foreign-key constraints and indexes.
-- 2. Demonstrate ON DELETE RESTRICT.
-- 3. Demonstrate ON DELETE CASCADE.
-- ============================================================


-- ------------------------------------------------------------
-- PART 1: Catalog query
-- Check whether each single-column foreign key has an index
-- that begins with its referencing column.
-- ------------------------------------------------------------

SELECT
    ns.nspname AS schema_name,
    tbl.relname AS table_name,
    con.conname AS foreign_key_name,
    att.attname AS referencing_column,
    pg_get_constraintdef(con.oid) AS foreign_key_definition,
    EXISTS (
        SELECT 1
        FROM pg_index AS idx
        WHERE idx.indrelid = con.conrelid
          AND idx.indisvalid
          AND idx.indkey[0] = att.attnum
    ) AS has_leading_column_index
FROM pg_constraint AS con
JOIN pg_class AS tbl
    ON tbl.oid = con.conrelid
JOIN pg_namespace AS ns
    ON ns.oid = tbl.relnamespace
JOIN LATERAL unnest(con.conkey)
    WITH ORDINALITY AS fk(attnum, ord)
    ON TRUE
JOIN pg_attribute AS att
    ON att.attrelid = con.conrelid
   AND att.attnum = fk.attnum
WHERE con.contype = 'f'
  AND ns.nspname = 'org'
  AND cardinality(con.conkey) = 1
ORDER BY tbl.relname, con.conname;


-- ------------------------------------------------------------
-- PART 2: RESTRICT demonstration
-- Parent deletion is rejected while a child references it.
-- These tables were created and populated during the test.
-- ------------------------------------------------------------

-- Table definitions used for the test:
--
-- CREATE TABLE org.q40_restrict_parent (
--     parent_id INTEGER PRIMARY KEY,
--     parent_name TEXT NOT NULL
-- );
--
-- CREATE TABLE org.q40_restrict_child (
--     child_id INTEGER PRIMARY KEY,
--     parent_id INTEGER NOT NULL,
--     CONSTRAINT q40_restrict_child_parent_fk
--         FOREIGN KEY (parent_id)
--         REFERENCES org.q40_restrict_parent(parent_id)
--         ON DELETE RESTRICT
-- );

-- The following DELETE is EXPECTED TO FAIL while child 101 exists.
-- Run this statement separately to observe the foreign-key error.
--
-- DELETE FROM org.q40_restrict_parent
-- WHERE parent_id = 1;

-- Verify that the parent remains after the rejected deletion.
SELECT
    parent_id,
    parent_name
FROM org.q40_restrict_parent
WHERE parent_id = 1;

-- Verify the referencing child.
SELECT
    child_id,
    parent_id
FROM org.q40_restrict_child
WHERE parent_id = 1;


-- ------------------------------------------------------------
-- PART 3: CASCADE demonstration
-- Deleting a parent automatically deletes its referencing children.
-- These tables were created and populated during the test.
-- ------------------------------------------------------------

-- Table definitions used for the test:
--
-- CREATE TABLE org.q40_cascade_parent (
--     parent_id INTEGER PRIMARY KEY,
--     parent_name TEXT NOT NULL
-- );
--
-- CREATE TABLE org.q40_cascade_child (
--     child_id INTEGER PRIMARY KEY,
--     parent_id INTEGER NOT NULL,
--     CONSTRAINT q40_cascade_child_parent_fk
--         FOREIGN KEY (parent_id)
--         REFERENCES org.q40_cascade_parent(parent_id)
--         ON DELETE CASCADE
-- );

-- Initial test data:
--
-- INSERT INTO org.q40_cascade_parent (parent_id, parent_name)
-- VALUES (1, 'Parent for CASCADE test');
--
-- INSERT INTO org.q40_cascade_child (child_id, parent_id)
-- VALUES (201, 1), (202, 1);

-- The following DELETE was executed successfully during the test.
-- It deleted the parent and automatically deleted both child rows.
--
-- DELETE FROM org.q40_cascade_parent
-- WHERE parent_id = 1;

-- Verify the parent no longer exists.
SELECT
    parent_id,
    parent_name
FROM org.q40_cascade_parent
WHERE parent_id = 1;

-- Verify both referencing children were automatically deleted.
SELECT
    child_id,
    parent_id
FROM org.q40_cascade_child
WHERE parent_id = 1
ORDER BY child_id;
