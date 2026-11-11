# Question 36 — Least Privilege Permission Matrix

## 1. Role Permissions

| Permission                   | trainee_reader | trainee_writer |
| :--------------------------- | :------------: | :------------: |
| CONNECT to database          |      YES       |     YES        |
| USAGE on schema `org`        |      YES       |     YES        |
| SELECT business tables       |      YES       |     YES        |
| INSERT business tables       |      NO        |     YES        |
| UPDATE business tables       |      NO        |     YES        |
| DELETE business tables       |      NO        |     YES        |
| USAGE on identity sequences  |      NO        |     YES        |
| CREATE tables in schema      |      NO        |     NO         |
| Ownership privileges         |      NO        |     NO         |
| Superuser privileges         |      NO        |     NO         |

## 2. Business Tables

The following business tables are included in the permissions:

1. `org.categories`
2. `org.departments`
3. `org.employee_profiles`
4. `org.employee_projects`
5. `org.employees`
6. `org.expenses`
7. `org.projects`

The view `org.v_department_spend` is excluded from the explicit business-table grants.

## 3. Verification Results

|            Test                  |         Expected Result       |
| :-------------------------------:| :----------------------------:|
| Reader executes SELECT           |            Allowed            |
| Reader executes INSERT           |            Denied             |
| Writer executes UPDATE           |            Allowed            |
| Writer executes INSERT           |            Allowed            |
| Writer executes CREATE TABLE     |            Denied             |
| Test transaction rollback        |  Temporary changes cancelled  |
| Reset role                       |  Session returns to `postgres`|

## 4. Security Summary

The `trainee_reader` role has read-only access to the business tables.

The `trainee_writer` role can read, insert, update, and delete business-table records. It also has USAGE permission on the five listed identity sequences to support generated IDs.

Neither role is granted ownership or superuser privileges.

These roles follow the principle of least privilege by receiving only the permissions needed for their assigned tasks.



```sql
SELECT r.rolname AS role,
       t.table_name,
       has_table_privilege(r.rolname, 'org.' || t.table_name, 'SELECT')   AS can_select,
       has_table_privilege(r.rolname, 'org.' || t.table_name, 'INSERT')   AS can_insert,
       has_table_privilege(r.rolname, 'org.' || t.table_name, 'UPDATE')   AS can_update,
       has_table_privilege(r.rolname, 'org.' || t.table_name, 'DELETE')   AS can_delete,
       has_table_privilege(r.rolname, 'org.' || t.table_name, 'TRUNCATE') AS can_truncate
FROM (VALUES ('trainee_reader'), ('trainee_writer')) AS r(rolname)
CROSS JOIN (SELECT table_name FROM information_schema.tables
             WHERE table_schema = 'org' AND table_type = 'BASE TABLE') t
ORDER BY r.rolname, t.table_name;
```