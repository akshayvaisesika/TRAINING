"""Entry point for the Employee Management System."""

from employee_manager import (
    load_employees,
    add_employee,
    search_employee,
    update_employee,
    delete_employee,
    filter_employees,
    view_all_employees,
)

from exporters import (
    export_to_json,
    export_to_csv,
)

from logger import logger


def display_menu():
    """Display the main menu of the application."""
    print("\n" + "=" * 45)
    print("        EMPLOYEE MANAGEMENT SYSTEM")
    print("=" * 45)

    print("1. Add Employee")
    print("2. Update Employee")
    print("3. Delete Employee")
    print("4. Search Employee")
    print("5. Filter Employees")
    print("6. View All Employees")
    print("7. Export to JSON")
    print("8. Export to CSV")
    print("9. Exit")

    print("=" * 45)


def main():
    """Run the Employee Management System."""
    # Load employee data when the application starts
    employees = load_employees()

    logger.info("Employee Management System started.")

    while True:
        display_menu()

        choice = input("Enter your choice: ").strip()

        # Add Employee
        if choice == "1":
            add_employee(employees)

        # Update Employee
        elif choice == "2":
            update_employee(employees)

        # Delete Employee
        elif choice == "3":
            delete_employee(employees)

        # Search Employee
        elif choice == "4":
            search_employee(employees)

        # Filter Employees
        elif choice == "5":
            filter_employees(employees)

        # View All Employees
        elif choice == "6":
            view_all_employees(employees)

        # Export JSON
        elif choice == "7":
            export_to_json(employees)

        # Export CSV
        elif choice == "8":
            export_to_csv(employees)

        # Exit
        elif choice == "9":
            logger.info(
                "Employee Management System closed."
            )
            print(
                "\nThank you for using the "
                "Employee Management System."
            )
            break

        # Invalid choice
        else:
            print(
                "\nInvalid choice. "
                "Please select a number from 1 to 9."
            )
            logger.warning(
                "Invalid menu choice entered: %s",
                choice,
            )


if __name__ == "__main__":
    main()