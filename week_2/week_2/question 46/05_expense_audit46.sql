
-- ============================================================
-- Q46: Rebuild Q42 expense audit system
-- Database: org_expenses_q46
-- Schema: org
-- ============================================================

-- 1. Create roles only if they do not already exist.
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_roles
        WHERE rolname = 'trainee_writer'
    ) THEN
        CREATE ROLE trainee_writer LOGIN;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_roles
        WHERE rolname = 'expense_audit_owner'
    ) THEN
        CREATE ROLE expense_audit_owner NOLOGIN;
    END IF;
END
$$;

-- 2. Create the audit table.
-- No FK on expense_id: history survives expense deletion.
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

-- 3. Grant minimum permissions to the function owner.
GRANT USAGE ON SCHEMA org TO expense_audit_owner;

GRANT INSERT ON TABLE org.expense_audit
TO expense_audit_owner;

GRANT USAGE, SELECT
ON SEQUENCE org.expense_audit_audit_id_seq
TO expense_audit_owner;

-- 4. Allow trainee_writer to work with expenses.
GRANT USAGE ON SCHEMA org TO trainee_writer;

GRANT SELECT, INSERT, UPDATE, DELETE
ON TABLE org.expenses
TO trainee_writer;

REVOKE CREATE ON SCHEMA org FROM trainee_writer;

-- Remove direct audit-table permissions.
REVOKE ALL PRIVILEGES
ON TABLE org.expense_audit
FROM trainee_writer;

REVOKE ALL PRIVILEGES
ON SEQUENCE org.expense_audit_audit_id_seq
FROM trainee_writer;

-- 5. Create the SECURITY DEFINER trigger function.
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

-- 6. Assign the function to its dedicated owner.
ALTER FUNCTION org.write_expense_audit()
OWNER TO expense_audit_owner;

REVOKE ALL ON FUNCTION org.write_expense_audit() FROM PUBLIC;
REVOKE ALL ON FUNCTION org.write_expense_audit()
FROM trainee_writer;

-- 7. Install the AFTER trigger.
DROP TRIGGER IF EXISTS trg_expenses_audit ON org.expenses;

CREATE TRIGGER trg_expenses_audit
AFTER INSERT OR UPDATE OR DELETE
ON org.expenses
FOR EACH ROW
EXECUTE FUNCTION org.write_expense_audit();

-- 8. Verify the function configuration.
SELECT
    p.proname AS function_name,
    pg_get_userbyid(p.proowner) AS function_owner,
    p.prosecdef AS is_security_definer,
    p.proconfig AS function_settings
FROM pg_proc AS p
JOIN pg_namespace AS n ON n.oid = p.pronamespace
WHERE n.nspname = 'org'
  AND p.proname = 'write_expense_audit';

-- 9. Verify the audit trigger.
SELECT
    trigger_name,
    event_manipulation,
    action_timing
FROM information_schema.triggers
WHERE event_object_schema = 'org'
  AND event_object_table = 'expenses'
  AND trigger_name = 'trg_expenses_audit'
ORDER BY event_manipulation;

-- 10. Verify direct audit-table privileges.
SELECT
    has_table_privilege('trainee_writer', 'org.expense_audit', 'INSERT') AS can_insert_audit,
    has_table_privilege('trainee_writer', 'org.expense_audit', 'UPDATE') AS can_update_audit,
    has_table_privilege('trainee_writer', 'org.expense_audit', 'DELETE') AS can_delete_audit;
