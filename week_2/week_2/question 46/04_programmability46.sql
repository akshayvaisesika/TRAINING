-- ============================================================
-- Q46: Rebuild Q41 expense-band function
-- Database: org_expenses_q46
-- Schema: org
-- ============================================================

CREATE OR REPLACE FUNCTION org.expense_band(p_amount NUMERIC)
RETURNS TEXT
LANGUAGE plpgsql
IMMUTABLE
AS $$
BEGIN
    -- Return NULL when the input is NULL.
    IF p_amount IS NULL THEN
        RETURN NULL;
    END IF;

    -- Reject zero and negative amounts.
    IF p_amount <= 0 THEN
        RAISE EXCEPTION
            'Expense amount must be positive. Received: %',
            p_amount;
    END IF;

    -- Return the appropriate expense band.
    IF p_amount < 500 THEN
        RETURN 'Small';
    ELSIF p_amount < 2000 THEN
        RETURN 'Medium';
    ELSE
        RETURN 'Large';
    END IF;
END;
$$;

-- Test expense bands and boundary values.
SELECT amount, org.expense_band(amount) AS expense_band
FROM (
    VALUES
        (100::NUMERIC),
        (499.99::NUMERIC),
        (500::NUMERIC),
        (1999.99::NUMERIC),
        (2000::NUMERIC),
        (NULL::NUMERIC)
) AS test_values(amount);

-- Test a built-in numeric function.
SELECT ROUND(123.456::NUMERIC, 2) AS rounded_value;