
-- ============================================================
-- Q42: Expense audit system
-- Database: org_expenses
-- Schema: org
--
-- Requirements:
--   1. Record INSERT, UPDATE, and DELETE operations.
--   2. Store old and new row values as JSONB.
--   3. Record actor role, definer role, and timestamp.
--   4. Preserve audit history after an expense is deleted.
--   5. Prevent direct audit-table modifications by trainee_writer.
-- ============================================================

-- Create the writer role if it does not exist.
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_roles
        WHERE rolname = 'trainee_writer'
    ) THEN
        CREATE ROLE trainee_writer LOGIN;
    END IF;
END
$$;

-- Create the dedicated non-login function owner if necessary.
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_roles
        WHERE rolname = 'expense_audit_owner'
    ) THEN
        CREATE ROLE expense_audit_owner NOLOGIN;
    END IF;
END
$$;

-- Create the audit table.
-- No foreign key is used for expense_id so history survives deletion.
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

-- Give the dedicated owner the minimum privileges needed.
GRANT USAGE ON SCHEMA org TO expense_audit_owner;

GRANT INSERT ON TABLE org.expense_audit
TO expense_audit_owner;

GRANT USAGE, SELECT
ON SEQUENCE org.expense_audit_audit_id_seq
TO expense_audit_owner;

-- Allow trainee_writer to use and modify expenses.
GRANT USAGE ON SCHEMA org TO trainee_writer;

GRANT SELECT, INSERT, UPDATE, DELETE
ON TABLE org.expenses
TO trainee_writer;

-- Do not allow trainee_writer to create objects in org.
REVOKE CREATE ON SCHEMA org FROM trainee_writer;

-- Remove direct audit-table privileges from trainee_writer.
REVOKE ALL PRIVILEGES
ON TABLE org.expense_audit
FROM trainee_writer;

REVOKE ALL PRIVILEGES
ON SEQUENCE org.expense_audit_audit_id_seq
FROM trainee_writer;

-- Create the trigger function.
CREATE OR REPLACE FUNCTION org.write_expense_audit()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $$
DECLARE
    v_actor_role NAME;
BEGIN
    -- Record the active role; otherwise use the session login.
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

-- Assign the function to the dedicated non-login owner.
ALTER FUNCTION org.write_expense_audit()
OWNER TO expense_audit_owner;

-- Prevent direct calls by PUBLIC and trainee_writer.
REVOKE ALL ON FUNCTION org.write_expense_audit() FROM PUBLIC;
REVOKE ALL ON FUNCTION org.write_expense_audit()
FROM trainee_writer;

-- Install the AFTER trigger.
DROP TRIGGER IF EXISTS trg_expenses_audit ON org.expenses;

CREATE TRIGGER trg_expenses_audit
AFTER INSERT OR UPDATE OR DELETE
ON org.expenses
FOR EACH ROW
EXECUTE FUNCTION org.write_expense_audit();

-- Verify the function owner and security configuration.
SELECT
    p.proname AS function_name,
    pg_get_userbyid(p.proowner) AS function_owner,
    p.prosecdef AS is_security_definer,
    p.proconfig AS function_settings
FROM pg_proc AS p
JOIN pg_namespace AS n ON n.oid = p.pronamespace
WHERE n.nspname = 'org'
  AND p.proname = 'write_expense_audit';

-- Verify the audit trigger.
SELECT
    trigger_name,
    event_manipulation,
    action_timing
FROM information_schema.triggers
WHERE event_object_schema = 'org'
  AND event_object_table = 'expenses'
  AND trigger_name = 'trg_expenses_audit'
ORDER BY event_manipulation;

-- Verify that trainee_writer cannot directly edit audit records.
SELECT
    has_table_privilege(
        'trainee_writer', 'org.expense_audit', 'INSERT'
    ) AS can_insert_audit,
    has_table_privilege(
        'trainee_writer', 'org.expense_audit', 'UPDATE'
    ) AS can_update_audit,
    has_table_privilege(
        'trainee_writer', 'org.expense_audit', 'DELETE'
    ) AS can_delete_audit;
