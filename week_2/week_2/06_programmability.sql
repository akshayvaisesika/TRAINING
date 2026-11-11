
-- ============================================================
-- Q41: User-defined function for expense bands
-- Database: org_expenses
-- Schema: org
--
-- Rules:
--   amount < 500  : Small
--   amount < 2000 : Medium
--   amount >= 2000: Large
--   NULL          : NULL
--   amount <= 0   : Raise an exception
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

-- Test the boundaries and NULL handling.
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

-- Test invalid values separately; each should raise an exception.
-- SELECT org.expense_band(0::NUMERIC);
-- SELECT org.expense_band(-100::NUMERIC);

-- Test a built-in numeric function for comparison.
SELECT ROUND(123.456::NUMERIC, 2) AS rounded_value;


SELECT 
expense_id,
amount,
category_id,
status,
org.expense_band(amount) as expense_band
from org.expenses
ORDER BY expense_id;


select expense_id,amount,category_id,status, org.expense_band(amount) as expense_band from org.expenses where status='approved'
and org.expense_band(amount) = 'Medium';