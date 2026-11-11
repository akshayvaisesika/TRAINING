
-- Q45: Monthly employee spending report using window functions.
-- Approved expenses only; one row per employee per month.
-- Includes department/month spending rank and employee running total.

WITH monthly_spending AS (
    SELECT
        e.employee_id,
        e.full_name,
        d.name AS department_name,
        DATE_TRUNC('month', x.occurred_on)::date AS expense_month,
        SUM(x.amount) AS monthly_spending
    FROM org.expenses AS x
    JOIN org.employees AS e
        ON e.employee_id = x.employee_id
    JOIN org.departments AS d
        ON d.department_id = e.department_id
    WHERE x.status = 'approved'
    GROUP BY
        e.employee_id,
        e.full_name,
        d.name,
        DATE_TRUNC('month', x.occurred_on)::date
)
SELECT
    employee_id,
    full_name,
    department_name,
    expense_month,
    monthly_spending,
    DENSE_RANK() OVER (
        PARTITION BY department_name, expense_month
        ORDER BY monthly_spending DESC
    ) AS spending_rank,
    SUM(monthly_spending) OVER (
        PARTITION BY employee_id
        ORDER BY expense_month
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_total
FROM monthly_spending
ORDER BY
    department_name,
    expense_month,
    spending_rank,
    employee_id;
