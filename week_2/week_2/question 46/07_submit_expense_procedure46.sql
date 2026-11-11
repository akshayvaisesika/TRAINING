
-- ============================================================
-- Q46: Rebuild Q44 expense submission procedure
-- Database: org_expenses_q46
-- Schema: org
-- ============================================================

CREATE OR REPLACE PROCEDURE org.submit_expense(
    p_expense_id BIGINT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_status TEXT;
BEGIN
    -- Find and lock the requested expense row.
    SELECT status
    INTO v_status
    FROM org.expenses
    WHERE expense_id = p_expense_id
    FOR UPDATE;

    -- Reject an expense ID that does not exist.
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

    -- Update the status.
    -- Audit and protection triggers run automatically.
    UPDATE org.expenses
    SET status = 'submitted'
    WHERE expense_id = p_expense_id;
END;
$$;

-- Verify the procedure exists.
SELECT
    p.proname AS procedure_name,
    pg_get_userbyid(p.proowner) AS procedure_owner
FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'org'
  AND p.proname = 'submit_expense'
  AND p.prokind = 'p';


select * from org.expenses;
CALL org.submit_expense(18);

select * from org.expenses
where expense_id=18;