# SCD-Type-2-Data-Engineering-project
# SCD Type 2 Data Engineering Pipeline

**A Python and SQL Server-based Data Engineering Project**

**GitHub Repository:** https://github.com/srinivas678-creatore

---

## 1. Project Overview

This project implements a Slowly Changing Dimension Type 2 (SCD Type 2) data pipeline using Python and Microsoft SQL Server.

The main objective is to maintain historical customer records whenever customer information changes. Instead of overwriting existing records, the pipeline preserves previous versions using effective dates and current-row indicators.

The project demonstrates real-world Data Engineering concepts, including data ingestion, change detection, historical data management, data validation, reconciliation, monitoring, and large-volume data processing.

## 2. Business Problem

In real-world business environments, customer information changes frequently. For example, a customer may change their city, country, or email address.

If existing records are directly updated, historical information is lost.

SCD Type 2 solves this problem by:

- Maintaining historical customer records.
- Creating new records whenever tracked attributes change.
- Maintaining effective start and end dates.
- Identifying active records using a current-row flag.
- Detecting changes using hash-based comparison.
- Handling duplicate and repeated updates.
- Supporting late-arriving and out-of-order records.

## 3. Project Objectives

- Implement an SCD Type 2 data warehouse solution.
- Generate and process 100,000+ customer records.
- Implement hash-based change detection.
- Maintain complete customer history.
- Handle duplicate and repeated events.
- Handle missing columns and invalid input data.
- Implement data validation and reconciliation.
- Monitor pipeline execution and performance.
- Ensure reliable and consistent database operations.

## 4. Technologies Used

| Technology | Purpose |
|---|---|
| Python | Pipeline development and data processing |
| Microsoft SQL Server | Database and historical data storage |
| SQL | Database operations and SCD Type 2 logic |
| PyODBC | Python and SQL Server connectivity |
| Pandas | Data manipulation and processing |
| SHA-256 | Hash-based change detection |
| Pytest | Automated testing |
| Git & GitHub | Version control and project management |
| ChatGPT (AI Assistant) | Learning, debugging, and technical guidance |

## 5. Project Architecture

The pipeline follows these steps:

1. Generate customer event data.
2. Read incoming data from CSV files.
3. Validate the source data.
4. Load records into SQL Server staging tables.
5. Generate hash values for customer attributes.
6. Compare incoming records with existing dimension records.
7. Identify new customers and changed records.
8. Expire previous customer versions.
9. Insert new historical records.
10. Handle duplicate and late-arriving events.
11. Perform data reconciliation and validation.
12. Monitor pipeline execution and performance.

## 6. SCD Type 2 Implementation

The project uses SCD Type 2 to maintain multiple versions of customer records.

### Example

| Customer ID | City | Start Date | End Date | Is Current |
|---|---|---|---|---|
| 101 | Hyderabad | 2024-01-01 | 2024-06-30 | 0 |
| 101 | Bangalore | 2024-07-01 | 9999-12-31 | 1 |

When the customer's city changes from Hyderabad to Bangalore:

- The previous record is expired.
- Its current flag is changed to 0.
- Its end date is updated.
- A new record is inserted.
- The new record is marked as current using flag 1.

This approach preserves the complete history of customer changes.

## 7. Change Detection

The pipeline uses SHA-256 hashing to identify changes in customer attributes.

A hash value is generated using selected customer attributes.

When an incoming record is compared with an existing record:

- Matching hash: No tracked attribute changes.
- Different hash: A change is detected and a new historical version is created.

This reduces the need to compare every tracked attribute individually.

## 8. Project Folder Structure

The project is organized into separate folders for datasets, SQL scripts, Python source code, testing, and documentation.

```text
SCD_Type2_Project/
│
├── data/
│   ├── customer_events_backup.csv
│   ├── customer_events.csv
│   ├── empty_test.csv
│   ├── large_customer_events.csv
│   └── misssing_column_test.csv
│
├── sql/
│   ├── 01_create_tables.sql
│   ├── 02_scd2_logic.sql
│   └── 03_validation_queries.sql
│
├── src/
│   ├── __init__.py
│   ├── config.py
│   ├── database.py
│   ├── generate_data.py
│   ├── ingestion.py
│   ├── monitoring.py
│   ├── reconciliation.py
│   ├── scd2.py
│   └── validation.py
│
├── test/
│   └── test_scd_type2.py
│
├── SQLQuery1.sql
├── SQLQuery2.sql
├── SQLQuery3.sql
├── ...
├── SQLQuery15.sql
│
├── venv/
│
└── README.md
```

### Folder Description

**data/**

Contains customer datasets used for normal pipeline execution, backup, large-volume processing, and testing scenarios such as empty files and missing columns.

**sql/**

Contains the main SQL scripts:

- `01_create_tables.sql` – Creates the required database tables.
- `02_scd2_logic.sql` – Implements the SCD Type 2 database logic.
- `03_validation_queries.sql` – Contains SQL queries for validating historical records and data consistency.

**src/**

Contains the main Python application.

- `config.py` – Stores database and project configuration.
- `database.py` – Manages database connectivity.
- `generate_data.py` – Generates customer event datasets.
- `ingestion.py` – Handles incoming data ingestion.
- `monitoring.py` – Tracks pipeline execution and performance.
- `reconciliation.py` – Checks consistency between source and target data.
- `scd2.py` – Implements the main SCD Type 2 processing workflow.
- `validation.py` – Performs data validation checks.
- `__init__.py` – Initializes the Python package.

**test/**

Contains automated test cases for validating SCD Type 2 functionality and handling different data scenarios.

**SQLQuery1.sql to SQLQuery15.sql**

Contains additional SQL queries developed and used during database development, testing, and validation.

**venv/**

Contains the Python virtual environment and installed dependencies required to execute the project.

## 9. Data Testing Scenarios

The project includes multiple datasets to test different pipeline scenarios.

| Dataset | Purpose |
|---|---|
| customer_events.csv | Main customer event dataset |
| customer_events_backup.csv | Backup dataset |
| empty_test.csv | Tests empty input handling |
| large_customer_events.csv | Tests large-volume data processing |
| misssing_column_test.csv | Tests missing-column validation |

These datasets help verify that the pipeline handles different input conditions reliably.

## 10. Installation and Execution

### Step 1: Clone the repository

```bash
git clone https://github.com/srinivas678-creatore
```

### Step 2: Navigate to the project directory

```bash
cd SCD_Type2_Project
```

### Step 3: Create a virtual environment

```bash
python -m venv venv
```

### Step 4: Activate the virtual environment

Windows PowerShell:

```powershell
.\venv\Scripts\Activate.ps1
```

### Step 5: Install dependencies

```bash
pip install -r requirements.txt
```

### Step 6: Configure database connection

Update the database configuration in `src/config.py` according to your SQL Server environment.

### Step 7: Create database tables

Execute the SQL scripts in the `sql/` folder in the appropriate order.

### Step 8: Execute the pipeline

```bash
python -m src.scd2
```

### Step 9: Run automated tests

```bash
python -m pytest test/ -v
```

## 11. AI Tools and Assistance

### Why I Used AI Assistance

During the development of this project, I used ChatGPT as an AI learning and development assistant.

The objective was not simply to generate code, but to understand complex Data Engineering concepts, solve technical challenges, and improve my problem-solving skills while implementing the project.

### How AI Helped Me

**1. Understanding Technical Concepts**

Used AI assistance to understand SCD Type 2, historical data management, hash-based change detection, idempotency, late-arriving data, and data reconciliation.

**2. Python and SQL Development**

Received guidance on Python implementation, SQL queries, database connectivity, data ingestion, and historical record management.

**3. Debugging and Troubleshooting**

Used AI assistance to understand error messages, identify potential issues, troubleshoot SQL and Python code, and improve implementation.

**4. Testing and Validation**

Received guidance on designing test scenarios for duplicate records, empty files, missing columns, repeated updates, and large datasets.

**5. Code Understanding and Documentation**

Used AI explanations to understand the purpose of different functions, SQL statements, and Python modules and to document the project clearly.

### My Learning Approach

I used AI as a supporting tool rather than relying on it blindly. I reviewed the suggested solutions, implemented the changes, tested the functionality, and worked on understanding the underlying logic.

This approach helped me improve my technical knowledge, debugging skills, and confidence in developing a practical Data Engineering project.

## 12. Key Learning Outcomes

Through this project, I gained practical experience in:

- Building Python-based data pipelines.
- Working with Microsoft SQL Server.
- Implementing SCD Type 2.
- Performing hash-based change detection.
- Managing historical customer data.
- Handling duplicate and late-arriving records.
- Implementing data validation and reconciliation.
- Monitoring pipeline execution.
- Testing large datasets.
- Using Git and GitHub for project management.
- Using AI tools effectively for technical learning and problem-solving.

## 13. Conclusion

This project demonstrates the implementation of a practical SCD Type 2 Data Engineering pipeline using Python and Microsoft SQL Server.

It covers data generation, ingestion, change detection, historical data management, validation, reconciliation, monitoring, and automated testing.

The project helped me gain practical knowledge of Data Engineering concepts and understand how reliable data pipelines can be developed to manage historical data in real-world business environments.

---

**GitHub Repository:** https://github.com/srinivas678-creatore
