# API Data Collector

## 1. Project Overview

The **API Data Collector** is a Python application that retrieves user data from a REST API, validates the response, transforms the selected fields, and saves the processed data into JSON and CSV files.

The application also uses logging to record important events, successful operations, and errors during execution.

This project demonstrates the basic principles of an **ETL (Extract, Transform, Load) pipeline**.

## 2. Objectives

* Fetch data from a REST API using Python.
* Handle HTTP errors, connection failures, and request timeouts.
* Validate API responses and check for required fields.
* Transform and standardize the retrieved data.
* Export processed data into JSON and CSV formats.
* Maintain application logs for debugging and monitoring.

## 3. API Source

**API Provider:** JSONPlaceholder
**Endpoint:** https://jsonplaceholder.typicode.com/users
**HTTP Method:** GET
**Authentication:** Not required

JSONPlaceholder is a public, free testing API that provides sample user data for development and learning purposes.

## 4. Technologies Used

* **Python** — Application development
* **Requests** — Sending HTTP requests to the API
* **JSON** — Storing structured data
* **CSV** — Storing tabular data
* **Logging** — Recording application activity and errors
* **uv** — Managing the Python virtual environment and dependencies

## 5. Project Structure

```text
project_2_api_data_collector/
│
├── data/
├── output/
│   ├── users.json
│   └── users.csv
│
├── logs/
│   └── app.log
│
├── api_client.py
├── validator.py
├── transformer.py
├── storage.py
├── logger.py
├── main.py
├── requirements.txt
└── README.md
```

### File Descriptions

| File or Folder     | Purpose                                                    |
| ------------------ | ---------------------------------------------------------- |
| `api_client.py`    | Fetches data from the REST API and handles request errors. |
| `validator.py`     | Checks the API response structure and required fields.     |
| `transformer.py`   | Selects and standardizes the required data.                |
| `storage.py`       | Saves processed data into JSON and CSV files.              |
| `logger.py`        | Configures application logging.                            |
| `main.py`          | Coordinates the complete data collection workflow.         |
| `requirements.txt` | Lists Python package dependencies.                         |
| `output/`          | Stores the generated JSON and CSV files.                   |
| `logs/`            | Stores application logs.                                   |
| `data/`            | Reserved for input data or future extensions.              |

## 6. Installation and Setup

### Prerequisites

* Python installed on your system
* Visual Studio Code or another Python editor
* `uv` package manager

### Step 1: Open the Project Directory

Open the project folder in VS Code and launch the integrated terminal.

### Step 2: Create a Virtual Environment

```powershell
uv venv
```

### Step 3: Activate the Virtual Environment

For Windows PowerShell:

```powershell
.\.venv\Scripts\Activate.ps1
```

If PowerShell blocks script execution, use the following command for the current terminal session:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy RemoteSigned
```

Then activate the environment again.

### Step 4: Install Dependencies

```powershell
uv pip install -r requirements.txt
```

## 7. Running the Application

Execute the following command from the project root directory:

```powershell
uv run python main.py
```

When the API request and subsequent operations succeed, the terminal displays:

```text
Data collection completed successfully.
```

The application then generates the following files:

* `output/users.json`
* `output/users.csv`
* `logs/app.log`

## 8. Application Workflow

The application follows this sequence:

1. **Extract:** Send a GET request to the API with a timeout.
2. **Validate:** Check that the response is a non-empty list of dictionaries and that each record contains the required fields.
3. **Transform:** Select the `id`, `name`, and `email` fields. Convert names to uppercase and email addresses to lowercase.
4. **Load:** Save the transformed records into JSON and CSV files.
5. **Log:** Record progress, successful operations, and errors.

```text
REST API
   |
   v
Fetch Data
   |
   v
Validate Response
   |
   v
Transform Data
   |
   v
Save JSON and CSV
   |
   v
Record Application Logs
```

## 9. Data Transformation

The application extracts three fields from each user record:

| Field   | Transformation                    |
| ------- | --------------------------------- |
| `id`    | Retained as received from the API |
| `name`  | Converted to uppercase            |
| `email` | Converted to lowercase            |

### Example

**Before transformation:**

```json
{
    "id": 1,
    "name": "Leanne Graham",
    "email": "Sincere@April.biz"
}
```

**After transformation:**

```json
{
    "id": 1,
    "name": "LEANNE GRAHAM",
    "email": "sincere@april.biz"
}
```

## 10. Output Formats

### JSON Output

The `users.json` file stores the processed records as a JSON array of objects. This format is suitable for applications that consume structured data.

### CSV Output

The `users.csv` file stores the same records in tabular form with the following columns:

```csv
id,name,email
1,LEANNE GRAHAM,sincere@april.biz
```

The CSV file can be opened using Microsoft Excel or other spreadsheet applications.

## 11. Error Handling and Logging

The application includes handling for common failures, including:

* Request timeouts
* Connection failures
* HTTP errors
* Invalid JSON responses
* Empty or incorrectly structured API responses
* Missing required fields

Application activity is recorded in `logs/app.log`, including successful API requests, validation, transformation, file creation, and errors.

When an error occurs, the application displays an informative message in the terminal and records the failure in the log.

## 12. Testing

The following scenarios can be used to verify the application.

| Test Case              | Expected Result                                                |
| ---------------------- | -------------------------------------------------------------- |
| Valid API response     | Data is validated, transformed, and saved.                     |
| Invalid API endpoint   | An HTTP error is logged and displayed.                         |
| Missing required field | Validation fails with a message identifying the missing field. |
| Network unavailable    | A connection error is handled and logged.                      |
| Request timeout        | A timeout error is handled and logged.                         |

After temporary failure tests, restore the original API endpoint and validation configuration before running the application normally.

## 13. Limitations

* The application currently collects sample user data from JSONPlaceholder.
* Only the `id`, `name`, and `email` fields are retained.
* The application requires an internet connection to retrieve data from the API.
* The current implementation does not use a database.
* The application is designed as a simple command-line program rather than a web application.
* The API does not require authentication, so environment-based API credentials are not needed.

## 14. Future Improvements

* Support multiple API endpoints.
* Add command-line arguments to choose JSON or CSV output.
* Add automated unit tests using `pytest`.
* Add retry logic for temporary network failures.
* Add configurable output filenames and directories.
* Integrate a database such as PostgreSQL.
* Schedule automated data collection.
* Add stronger validation for field types and email formats.

## 15. Author

**Akshay M**

## 16. Conclusion

This project demonstrates how to build a modular Python application that retrieves information from a REST API, validates and transforms the data, exports it to JSON and CSV files, and records application activity using logging.

It provides a foundation for understanding API integration, data processing, file handling, exception handling, and basic ETL workflows in Python.
