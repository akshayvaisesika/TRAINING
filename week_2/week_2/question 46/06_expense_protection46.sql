
-- ============================================================
-- Q46: Rebuild Q43 approved-expense protection
-- Database: org_expenses_q46
-- Schema: org
-- ============================================================

CREATE OR REPLACE FUNCTION org.protect_approved_expense()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    -- Protect important fields on already-approved expenses.
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

    -- Refresh the timestamp on every accepted update.
    NEW.updated_at := clock_timestamp();

    RETURN NEW;
END;
$$;

-- Install the BEFORE UPDATE trigger.
DROP TRIGGER IF EXISTS trg_protect_approved_expense
ON org.expenses;

CREATE TRIGGER trg_protect_approved_expense
BEFORE UPDATE
ON org.expenses
FOR EACH ROW
EXECUTE FUNCTION org.protect_approved_expense();

-- Verify the trigger.
SELECT
    trigger_name,
    event_manipulation,
    action_timing
FROM information_schema.triggers
WHERE event_object_schema = 'org'
  AND event_object_table = 'expenses'
  AND trigger_name = 'trg_protect_approved_expense';

-- Verify the function definition.
SELECT pg_get_functiondef(
    'org.protect_approved_expense()'::regprocedure
);
