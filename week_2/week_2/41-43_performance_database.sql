-- Active: 1791964644828@@127.0.0.1@5432@org_expenses
-- Q40, Step 1: Confirm the current database and schema.
SELECT
    current_database() AS database_name,
    current_schema() AS schema_name,
    current_user AS connected_user;

-- Q40, Step 2: List foreign-key constraints in the current database.
SELECT
    ns.nspname AS schema_name,
    tbl.relname AS table_name,
    con.conname AS constraint_name,
    pg_get_constraintdef(con.oid) AS foreign_key_definition
FROM pg_constraint AS con
JOIN pg_class AS tbl
    ON tbl.oid = con.conrelid
JOIN pg_namespace AS ns
    ON ns.oid = tbl.relnamespace
WHERE con.contype = 'f'
  AND ns.nspname = 'org'
ORDER BY tbl.relname, con.conname;

-- Q40, Step 3: Inspect indexes on tables containing foreign keys.
SELECT
    tbl.relname AS table_name,
    con.conname AS foreign_key_name,
    pg_get_constraintdef(con.oid) AS foreign_key_definition,
    idx.indexname AS index_name,
    idx.indexdef AS index_definition
FROM pg_constraint AS con
JOIN pg_class AS tbl
    ON tbl.oid = con.conrelid
JOIN pg_namespace AS ns
    ON ns.oid = tbl.relnamespace
LEFT JOIN pg_indexes AS idx
    ON idx.schemaname = ns.nspname
   AND idx.tablename = tbl.relname
WHERE con.contype = 'f'
  AND ns.nspname = 'org'
ORDER BY tbl.relname, con.conname, idx.indexname;

-- Q40, Step 4.1: Create a disposable parent table.
-- This table is only for testing foreign-key behavior.

CREATE TABLE org.q40_restrict_parent (
    parent_id INTEGER PRIMARY KEY,
    parent_name TEXT NOT NULL
);

-- Q40, Step 4.2: Create a disposable child table.
-- ON DELETE RESTRICT prevents deleting a referenced parent.

CREATE TABLE org.q40_restrict_child (
    child_id INTEGER PRIMARY KEY,
    parent_id INTEGER NOT NULL,

    CONSTRAINT q40_restrict_child_parent_fk
        FOREIGN KEY (parent_id)
        REFERENCES org.q40_restrict_parent(parent_id)
        ON DELETE RESTRICT
);

-- Q40, Step 4.3: Insert one test parent record.

INSERT INTO org.q40_restrict_parent (
    parent_id,
    parent_name
)
VALUES (
    1,
    'Parent for RESTRICT test'
);


-- Q40, Step 4.4: Insert a child that references parent_id = 1.
INSERT INTO org.q40_restrict_child (
    child_id,
    parent_id
)
VALUES (
    101,
    1
);

-- Q40, Step 4.5: Verify the parent-child relationship.
SELECT
    p.parent_id,
    p.parent_name,
    c.child_id,
    c.parent_id AS child_parent_id
FROM org.q40_restrict_parent AS p
JOIN org.q40_restrict_child AS c
    ON c.parent_id = p.parent_id;

-- Q40, Step 4.6: Expected failure.
-- The parent cannot be deleted while a child references it.

DELETE FROM org.q40_restrict_parent
WHERE parent_id = 1;

-- Q40, Step 4.7: Confirm the parent survived the rejected DELETE.
SELECT
    parent_id,
    parent_name
FROM org.q40_restrict_parent
WHERE parent_id = 1;



-- Q40, Step 5.1: Create a disposable parent table for CASCADE testing.

CREATE TABLE org.q40_cascade_parent (
    parent_id INTEGER PRIMARY KEY,
    parent_name TEXT NOT NULL
);

-- Q40, Step 5.2: Create a disposable child table for CASCADE testing.
-- Deleting a parent will automatically delete its referencing children.

CREATE TABLE org.q40_cascade_child (
    child_id INTEGER PRIMARY KEY,
    parent_id INTEGER NOT NULL,

    CONSTRAINT q40_cascade_child_parent_fk
        FOREIGN KEY (parent_id)
        REFERENCES org.q40_cascade_parent(parent_id)
        ON DELETE CASCADE
);

-- Q40, Step 5.3: Insert a parent row for the CASCADE test.
INSERT INTO org.q40_cascade_parent (
    parent_id,
    parent_name
)
VALUES (
    1,
    'Parent for CASCADE test'
);

-- Q40, Step 5.4: Insert two child rows referencing the same parent.
INSERT INTO org.q40_cascade_child (
    child_id,
    parent_id
)
VALUES
    (201, 1),
    (202, 1);


-- Q40, Step 5.5: Verify the CASCADE parent-child relationship.
SELECT
    p.parent_id,
    p.parent_name,
    c.child_id,
    c.parent_id AS child_parent_id
FROM org.q40_cascade_parent AS p
JOIN org.q40_cascade_child AS c
    ON c.parent_id = p.parent_id
WHERE p.parent_id = 1
ORDER BY c.child_id;


-- Q40, Step 5.6: Delete the parent and trigger CASCADE.
-- PostgreSQL should automatically delete its two referencing children.
DELETE FROM org.q40_cascade_parent
WHERE parent_id = 1;

-- Q40, Step 5.7: Check whether the parent still exists.
-- The expected result is zero rows because the parent was deleted.
SELECT
    parent_id,
    parent_name
FROM org.q40_cascade_parent
WHERE parent_id = 1;

-- Q40, Step 5.8: Verify that CASCADE removed both child rows.
SELECT
    child_id,
    parent_id
FROM org.q40_cascade_child
WHERE parent_id = 1
ORDER BY child_id;


-- Q40, Step 6.1: Check indexes on single-column foreign keys.
-- PostgreSQL does not automatically create indexes on referencing columns.
-- This query checks whether an index starts with each foreign-key column.

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


-- Q41, Step 1: Create a scalar function to classify expense amounts.
-- Uses the same thresholds as Q20.
-- NULL input returns NULL.
-- Zero or negative input raises an exception.

CREATE OR REPLACE FUNCTION org.expense_band(p_amount NUMERIC)
RETURNS TEXT
LANGUAGE plpgsql
IMMUTABLE
AS $$
BEGIN
    -- A NULL amount returns NULL.
    IF p_amount IS NULL THEN
        RETURN NULL;
    END IF;

    -- Reject zero and negative amounts.
    IF p_amount <= 0 THEN
        RAISE EXCEPTION
            'Expense amount must be positive. Received: %',
            p_amount;
    END IF;

    -- Apply the Q20 expense bands.
    IF p_amount < 500 THEN
        RETURN 'Small';
    ELSIF p_amount < 2000 THEN
        RETURN 'Medium';
    ELSE
        RETURN 'Large';
    END IF;
END;
$$;


-- Q41, Step 2: Test expense-band boundaries and NULL handling.
-- Expected bands: Small < 500, Medium < 2000, otherwise Large.
-- NULL input should return NULL.

SELECT
    test.amount,
    org.expense_band(test.amount) AS expense_band
FROM (
    VALUES
        (499.99::NUMERIC),
        (500::NUMERIC),
        (1999.99::NUMERIC),
        (2000::NUMERIC),
        (NULL::NUMERIC)
) AS test(amount);


-- Q41, Step 3.1: Test zero as an invalid expense amount.
-- Expected: PostgreSQL raises an exception.

SELECT org.expense_band(0::NUMERIC);

-- Q41, Step 3.2: Test a negative expense amount.
-- Expected: PostgreSQL raises an exception.

SELECT org.expense_band(-100::NUMERIC);



-- Q41, Step 4.1: Demonstrate a built-in scalar function.
-- ROUND() takes a numeric input and returns a numeric result.

SELECT
    ROUND(123.456::NUMERIC, 2) AS rounded_amount;



-- Q41, Step 4.2: Create a simple procedure for comparison.
-- The procedure displays a message using RAISE NOTICE.
-- Unlike a scalar function, it does not return an expense band.

CREATE OR REPLACE PROCEDURE org.show_expense_band_example(
    p_amount NUMERIC
)
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE NOTICE 'The supplied expense amount is: %', p_amount;
END;
$$;

-- Call the procedure using CALL.
CALL org.show_expense_band_example(750::NUMERIC);




-- Q42, Step 1: Verify the current database and login role.
-- We will use this information to configure auditing permissions safely.

SELECT
    current_database() AS database_name,
    current_user AS current_role,
    session_user AS session_login;

-- Q42, Step 2: Verify that the expenses table exists.
-- We need this table for the audit trigger.

SELECT
    table_schema,
    table_name
FROM information_schema.tables
WHERE table_schema = 'org'
  AND table_name = 'expenses';


-- Q42, Step 3: Inspect the expenses table structure.
-- The audit trigger needs to capture the complete OLD and NEW rows.

SELECT
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'org'
  AND table_name = 'expenses'
ORDER BY ordinal_position;


-- Q42, Step 4: Create the audit table.
-- Store the operation, expense identifier, old/new snapshots,
-- event timestamp, invoking role, and function definer identity.
-- Do not add a foreign key to org.expenses: audit history must
-- remain after an expense is deleted.

CREATE TABLE org.expense_audit (
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


-- Q42, Step 5: Check whether the required writer role exists.
-- Also inspect the current role and audit table owner.

SELECT
    r.rolname AS role_name,
    r.rolsuper AS is_superuser,
    r.rolcreaterole AS can_create_roles,
    r.rolcreatedb AS can_create_databases
FROM pg_roles AS r
WHERE r.rolname IN (
    'trainee_writer',
    current_user
)
ORDER BY r.rolname;

-- Q42, Step 5.2: Inspect the owner of the audit table.

SELECT
    schemaname,
    tablename,
    tableowner
FROM pg_tables
WHERE schemaname = 'org'
  AND tablename = 'expense_audit';


-- Q42, Step 6: Inspect privileges on the org schema.
-- We need to ensure trainee_writer cannot create objects there.

SELECT
    n.nspname AS schema_name,
    r.rolname AS role_name,
    has_schema_privilege(r.rolname,n.oid,'USAGE') AS can_use_schema,
    has_schema_privilege(r.rolname,n.oid,'CREATE') AS can_create_in_schema
FROM pg_namespace AS n
CROSS JOIN pg_roles AS r
WHERE n.nspname = 'org'
  AND r.rolname IN ('postgres', 'trainee_writer')
ORDER BY r.rolname;

-- Q42, Step 7: Allow the writer to access objects in org.
-- This does not grant permission to create objects in the schema.

GRANT USAGE ON SCHEMA org TO trainee_writer;
-- Q42, Step 8: Grant only the required DML privileges.
-- The writer can insert, update, and delete expenses.
-- This does not grant direct permission to edit the audit table.

GRANT SELECT, INSERT, UPDATE, DELETE
ON TABLE org.expenses
TO trainee_writer;

-- Q42, Step 9: Remove direct privileges on the audit table.
-- The writer must not be able to read, insert, update, or delete
-- audit records directly. The secure trigger function will write them.

REVOKE ALL PRIVILEGES
ON TABLE org.expense_audit
FROM trainee_writer;


-- Q42, Step 10: Create a secure audit trigger function.
-- SECURITY DEFINER allows this function to insert audit records
-- using the function owner's privileges.
-- A fixed search_path and schema-qualified objects reduce risk.

CREATE OR REPLACE FUNCTION org.write_expense_audit()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO org.expense_audit (
            expense_id,
            operation_type,
            old_data,
            new_data,
            changed_at,
            actor_role,
            definer_role
        )
        VALUES (
            NEW.expense_id,
            TG_OP,
            NULL,
            to_jsonb(NEW),
            clock_timestamp(),
            session_user,
            current_user
        );

        RETURN NEW;

    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO org.expense_audit (
            expense_id,
            operation_type,
            old_data,
            new_data,
            changed_at,
            actor_role,
            definer_role
        )
        VALUES (
            NEW.expense_id,
            TG_OP,
            to_jsonb(OLD),
            to_jsonb(NEW),
            clock_timestamp(),
            session_user,
            current_user
        );

        RETURN NEW;

    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO org.expense_audit (
            expense_id,
            operation_type,
            old_data,
            new_data,
            changed_at,
            actor_role,
            definer_role
        )
        VALUES (
            OLD.expense_id,
            TG_OP,
            to_jsonb(OLD),
            NULL,
            clock_timestamp(),
            session_user,
            current_user
        );

        RETURN OLD;
    END IF;

    RAISE EXCEPTION 'Unsupported audit operation: %', TG_OP;
END;
$$;


-- Q42, Step 11: Create a dedicated owner for the audit function.
-- NOLOGIN prevents anyone from connecting directly as this role.

CREATE ROLE expense_audit_owner NOLOGIN;

-- Allow the function owner to access the org schema.
GRANT USAGE ON SCHEMA org TO expense_audit_owner;

-- Give the function owner only the permission needed to write audit rows.
GRANT INSERT ON TABLE org.expense_audit TO expense_audit_owner;


-- Q42, Step 12: Assign the function to its dedicated owner.
ALTER FUNCTION org.write_expense_audit()
OWNER TO expense_audit_owner;

-- Remove the default permission that allows PUBLIC to execute the function.
REVOKE ALL PRIVILEGES
ON FUNCTION org.write_expense_audit()
FROM PUBLIC;

-- Explicitly prevent trainee_writer from executing the function directly.
REVOKE ALL PRIVILEGES
ON FUNCTION org.write_expense_audit()
FROM trainee_writer;

-- Ensure trainee_writer cannot create objects in the org schema.
REVOKE CREATE
ON SCHEMA org
FROM trainee_writer;


-- Q42, Step 13: Create the row-level audit trigger.
-- The trigger records every inserted, updated, or deleted expense.
-- AFTER triggers run after the row operation.
-- FOR EACH ROW creates an audit record for each affected row.

DROP TRIGGER IF EXISTS trg_expenses_audit ON org.expenses;

CREATE TRIGGER trg_expenses_audit
AFTER INSERT OR UPDATE OR DELETE
ON org.expenses
FOR EACH ROW
EXECUTE FUNCTION org.write_expense_audit();


-- Q42, Step 13 verification: Confirm the trigger is attached.
SELECT
    trigger_name,
    event_manipulation,
    action_timing,
    action_orientation
FROM information_schema.triggers
WHERE event_object_schema = 'org'
  AND event_object_table = 'expenses'
  AND trigger_name = 'trg_expenses_audit'
ORDER BY event_manipulation;


-- Q42, Step 14: Update the function to capture the active invoking role.
-- current_setting('role') captures a role selected with SET ROLE.
-- session_user is the fallback when no role has been selected.
-- current_user records the SECURITY DEFINER function owner.

CREATE OR REPLACE FUNCTION org.write_expense_audit()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $$
DECLARE
    v_actor_role NAME;
BEGIN
    v_actor_role :=
        COALESCE(
            NULLIF(current_setting('role', true), 'none'),
            session_user::text
        )::name;

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



-- Q42, Step 15: Inspect expenses columns before testing the trigger.
-- This identifies required fields, defaults, and the expense ID type.

SELECT
    column_name,
    data_type,
    is_nullable,
    column_default,
    is_identity
FROM information_schema.columns
WHERE table_schema = 'org'
  AND table_name = 'expenses'
ORDER BY ordinal_position;

-- Q42, Step 15: Preview existing expenses.
-- Read-only query; it does not modify any data.

SELECT *
FROM org.expenses
LIMIT 5;



-- Q42, Step 16: Test all three audited operations.
-- Run as postgres in performance_database.
-- The transaction will be rolled back, so test data will not remain.

BEGIN;

-- Switch to the writer role for the expense operations.
SET LOCAL ROLE trainee_writer;

-- INSERT: create one temporary test expense.
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
    125.00,
    DATE '2026-10-18',
    'Q42 audit trigger test',
    'draft'
)
RETURNING expense_id;

-- UPDATE: change the temporary expense.
UPDATE org.expenses
SET amount = 175.00,
    description = 'Q42 audit trigger test updated'
WHERE description = 'Q42 audit trigger test';

-- DELETE: delete the temporary expense.
DELETE FROM org.expenses
WHERE description = 'Q42 audit trigger test updated';

-- Return to the postgres role so we can inspect the protected audit table.
RESET ROLE;

-- Verify that INSERT, UPDATE and DELETE were audited.
SELECT
    expense_id,
    operation_type,
    old_data,
    new_data,
    changed_at,
    actor_role,
    definer_role
FROM org.expense_audit
WHERE new_data ->> 'description' LIKE 'Q42 audit trigger test%'
   OR old_data ->> 'description' LIKE 'Q42 audit trigger test%'
ORDER BY audit_id;

-- Undo the expense operations and their audit rows.
ROLLBACK;



-- Q42, Step 17: Verify that trainee_writer cannot directly edit audit records.
-- The UPDATE should fail with "permission denied".
-- The savepoint lets us recover after that expected error.

BEGIN;

SET LOCAL ROLE trainee_writer;

SAVEPOINT before_direct_audit_edit;

UPDATE org.expense_audit
SET operation_type = 'DELETE';

-- After the expected permission error, run these statements separately:
ROLLBACK TO SAVEPOINT before_direct_audit_edit;

RESET ROLE;

ROLLBACK;


-- Q42, Step 18: Verify the audit function's owner and security settings.
SELECT
    p.proname AS function_name,
    pg_get_userbyid(p.proowner) AS function_owner,
    p.prosecdef AS security_definer,
    p.proconfig AS function_settings
FROM pg_proc AS p
JOIN pg_namespace AS n
    ON n.oid = p.pronamespace
WHERE n.nspname = 'org'
  AND p.proname = 'write_expense_audit';



-- Q42, Step 18: Verify trainee_writer cannot create schema objects
-- or directly mutate the audit table.

SELECT
    has_schema_privilege(
        'trainee_writer', 'org', 'USAGE'
    ) AS can_use_org_schema,
    has_schema_privilege(
        'trainee_writer', 'org', 'CREATE'
    ) AS can_create_in_org,
    has_table_privilege(
        'trainee_writer', 'org.expense_audit', 'INSERT'
    ) AS can_insert_audit_directly,
    has_table_privilege(
        'trainee_writer', 'org.expense_audit', 'UPDATE'
    ) AS can_update_audit_directly,
    has_table_privilege(
        'trainee_writer', 'org.expense_audit', 'DELETE'
    ) AS can_delete_audit_directly;



 -- Q43, Step 2: Inspect existing expense statuses.
-- This is a read-only query.
-- We need to know the available statuses before defining the policy.

SELECT
    status,
    COUNT(*) AS expense_count
FROM org.expenses
GROUP BY status
ORDER BY status;


-- Q43, Step 3: Protect approved expenses and refresh updated_at.
-- Approved expenses allow description edits only.
-- Their amount, category, employee, date, and status are protected.

CREATE OR REPLACE FUNCTION org.protect_approved_expense()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    -- Protect important fields when the old status is approved.
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

    -- Automatically refresh the modification timestamp.
    NEW.updated_at := clock_timestamp();

    RETURN NEW;
END;
$$;



-- Q43, Step 4: Attach the protection function to expenses.
-- BEFORE UPDATE lets the function validate changes before they are saved.
-- FOR EACH ROW applies the rules to each updated expense.

DROP TRIGGER IF EXISTS trg_protect_approved_expense
ON org.expenses;

CREATE TRIGGER trg_protect_approved_expense
BEFORE UPDATE
ON org.expenses
FOR EACH ROW
EXECUTE FUNCTION org.protect_approved_expense();

-- Q43, Step 4: Verify the trigger definition.
SELECT
    trigger_name,
    event_manipulation,
    action_timing,
    action_orientation
FROM information_schema.triggers
WHERE event_object_schema = 'org'
  AND event_object_table = 'expenses'
  AND trigger_name = 'trg_protect_approved_expense';


-- Q43, Step 5: Find one approved expense for testing.
-- We will use its ID for the accepted and rejected update tests.
-- No rows are modified by this query.

SELECT
    expense_id,
    employee_id,
    category_id,
    amount,
    occurred_on,
    description,
    status,
    updated_at
FROM org.expenses
WHERE status = 'approved'
ORDER BY expense_id
LIMIT 5;


-- Q43, Step 6: Test the approved-expense protection trigger.
-- The description update should succeed.
-- The amount update should fail.
-- ROLLBACK ensures no permanent changes are made.

BEGIN;

-- Capture the original row and timestamp.
SELECT
    expense_id,
    amount,
    description,
    status,
    updated_at AS timestamp_before
FROM org.expenses
WHERE status = 'approved'
ORDER BY expense_id
LIMIT 1;

-- Accepted update: description changes are allowed.
WITH chosen AS (
    SELECT expense_id
    FROM org.expenses
    WHERE status = 'approved'
    ORDER BY expense_id
    LIMIT 1
)
UPDATE org.expenses AS e
SET description = COALESCE(e.description, '') || ' [Q43 test]'
FROM chosen
WHERE e.expense_id = chosen.expense_id
RETURNING
    e.expense_id,
    e.description,
    e.updated_at AS timestamp_after;

-- Rejected update: changing the amount must raise an exception.
-- Run this statement separately after the accepted update succeeds.
UPDATE org.expenses
SET amount = amount + 1
WHERE expense_id = (
    SELECT expense_id
    FROM org.expenses
    WHERE status = 'approved'
    ORDER BY expense_id
    LIMIT 1
);

-- After observing the expected error, roll back the transaction.
ROLLBACK;


-- Q43: Verify that no test changes remain after rollback.
SELECT
    expense_id,
    amount,
    description,
    status,
    updated_at
FROM org.expenses
WHERE status = 'approved'
ORDER BY expense_id
LIMIT 5;


-- Q43: Verify that the approved-expense protection trigger exists.
SELECT
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement
FROM information_schema.triggers
WHERE event_object_schema = 'org'
  AND event_object_table = 'expenses'
  AND trigger_name = 'trg_protect_approved_expense';


-- Check the main assignment database before integration.
SELECT
    current_database() AS database_name,
    current_schema() AS current_schema,
    current_user AS connected_user;

-- Check whether the main expense table exists.
SELECT
    to_regclass('org.expenses') AS expenses_table,
    to_regclass('org.expense_audit') AS audit_table;

-- Check the current expense statuses.
SELECT
    status,
    COUNT(*) AS expense_count
FROM org.expenses
GROUP BY status
ORDER BY status;

