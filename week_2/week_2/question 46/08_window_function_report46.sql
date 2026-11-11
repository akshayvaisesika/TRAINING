
-- ============================================================
-- Q46: Rebuild Q45 monthly spending report
-- Database: org_expenses_q46
-- ============================================================

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


-- Rank expenses from highest to lowest.
-- Replace the table or column names only if your schema differs.

SELECT
    ex.expense_id,
    ex.employee_id,
    emp.full_name,
    ex.amount,
    RANK() OVER ( PARTITION BY emp.employee_id ORDER BY amount DESC ) AS expense_rank
FROM org.expenses as ex
JOIN org.employees as emp
on ex.employee_id=emp.employee_id;

-- Restart the ranking for every employee.

SELECT
    expense_id,
    employee_id,
    amount,
    RANK() OVER (
        PARTITION BY employee_id
        ORDER BY amount DESC
    ) AS employee_expense_rank
FROM org.expenses;