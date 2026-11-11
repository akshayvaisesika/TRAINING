
-- Q44: Stored procedure to submit an expense.
-- Only expenses currently in draft status may be submitted.
-- Missing IDs and non-draft expenses raise clear exceptions.
-- The caller controls transaction commit or rollback.

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

    -- Reject any expense that is not in draft status.
    IF v_status IS DISTINCT FROM 'draft' THEN
        RAISE EXCEPTION
            'Cannot submit expense ID % because its status is "%". Only draft expenses can be submitted.',
            p_expense_id, v_status;
    END IF;

    -- Submit the expense.
    -- Existing audit and updated_at triggers should run automatically.
    UPDATE org.expenses
    SET status = 'submitted'
    WHERE expense_id = p_expense_id;
END;
$$;
