
# ============================================================
# FILE: generate_data.py
# PROJECT: SCD Type 2 Data Engineering Pipeline
#
# PURPOSE:
# Generate 100,000 reproducible synthetic customer events.
#
# SCENARIOS:
# 1. Repeated customer updates
# 2. Duplicate event records
# 3. Missing required values
# 4. Invalid customer records
# 5. Late-arriving events
# 6. Out-of-order event delivery
#
# OUTPUT:
# data/large_customer_events.csv
# ============================================================

import pandas as pd
import random

from datetime import datetime, timedelta
from pathlib import Path


# ============================================================
# STEP 1: CONFIGURATION
# ============================================================

TOTAL_RECORDS = 100000
TOTAL_CUSTOMERS = 10000
RANDOM_SEED = 42

random.seed(RANDOM_SEED)


# ============================================================
# STEP 2: DEFINE CUSTOMER ATTRIBUTES
# ============================================================

customer_names = [
    "Rahul", "Priya", "Arjun", "Sneha", "Kiran",
    "Anjali", "Vijay", "Neha", "Ravi", "Divya",
    "Amit", "Pooja", "Suresh", "Meena", "Varun"
]

cities = [
    "Hyderabad", "Bangalore", "Chennai",
    "Mumbai", "Pune", "Delhi",
    "Kolkata", "Jaipur", "Ahmedabad"
]

countries = ["India", "USA", "UK", "Canada"]

start_date = datetime(2024, 1, 1)


# ============================================================
# STEP 3: GENERATE CUSTOMER EVENTS
# ============================================================

records = []

for i in range(TOTAL_RECORDS):

    # Select a customer ID.
    # Reusing IDs creates multiple events for the same customer.
    customer_number = random.randint(1, TOTAL_CUSTOMERS)

    customer_id = f"CUST{customer_number:05d}"

    # Generate an effective event date.
    event_date = start_date + timedelta(
        days=random.randint(0, 700)
    )

    # Generate customer details.
    record = {
        "event_id": f"EVT{i + 1:06d}",
        "customer_id": customer_id,
        "customer_name": random.choice(customer_names),
        "city": random.choice(cities),
        "country": random.choice(countries),
        "email": f"customer{customer_number}@example.com",
        "event_date": event_date,
        "source_file": "large_customer_events.csv"
    }

    records.append(record)


# ============================================================
# STEP 4: CONVERT RECORDS INTO DATAFRAME
# ============================================================

df = pd.DataFrame(records)

# Keep event IDs and event attributes together.


# ============================================================
# STEP 5: ADD DUPLICATE EVENTS
# ============================================================

# Select 100 existing records.
# Copying them preserves the original event IDs.

duplicate_records = df.sample(
    n=100,
    random_state=RANDOM_SEED
).copy()

# Append duplicate events.
df = pd.concat(
    [df, duplicate_records],
    ignore_index=True
)


# ============================================================
# STEP 6: ADD MISSING VALUES
# ============================================================

# Introduce 100 missing customer names.

missing_name_indices = df.sample(
    n=100,
    random_state=RANDOM_SEED + 1
).index

df.loc[
    missing_name_indices,
    "customer_name"
] = None


# ============================================================
# STEP 7: ADD INVALID RECORDS
# ============================================================

# Introduce 50 missing customer IDs.
# These records should be rejected during validation.

invalid_indices = df.sample(
    n=50,
    random_state=RANDOM_SEED + 2
).index

df.loc[
    invalid_indices,
    "customer_id"
] = None


# ============================================================
# STEP 8: SIMULATE LATE-ARRIVING EVENTS
# ============================================================

# Select 100 events and move their effective dates
# backwards by 365 days.

late_indices = df.sample(
    n=100,
    random_state=RANDOM_SEED + 3
).index

df.loc[late_indices, "event_date"] = (
    pd.to_datetime(df.loc[late_indices, "event_date"])
    - pd.to_timedelta(365, unit="D")
)


# ============================================================
# STEP 9: SHUFFLE EVENTS
# ============================================================

# Randomize the delivery order.
# The pipeline must not assume events arrive chronologically.

df = df.sample(
    frac=1,
    random_state=RANDOM_SEED
).reset_index(drop=True)


# ============================================================
# STEP 10: PREPARE OUTPUT DIRECTORY
# ============================================================

# Project root is the parent of the src directory.
project_root = Path(__file__).resolve().parent.parent

output_folder = project_root / "data"

output_folder.mkdir(
    parents=True,
    exist_ok=True
)


# ============================================================
# STEP 11: SAVE CSV FILE
# ============================================================

output_path = output_folder / "large_customer_events.csv"

# Store dates in ISO-8601 format.

df["event_date"] = pd.to_datetime(
    df["event_date"]
).dt.strftime("%Y-%m-%dT%H:%M:%S")

df.to_csv(
    output_path,
    index=False
)


# ============================================================
# STEP 12: GENERATE DATA QUALITY SUMMARY
# ============================================================

print("\n========================================")
print("SCD TYPE 2 DATA GENERATION COMPLETED")
print("========================================")

print("Original records generated:", TOTAL_RECORDS)

print("Total records after duplicates:", len(df))

print("Unique customers:", df["customer_id"].nunique())

print(
    "Duplicate event IDs:",
    df["event_id"].duplicated().sum()
)

print(
    "Missing customer names:",
    df["customer_name"].isnull().sum()
)

print(
    "Missing customer IDs:",
    df["customer_id"].isnull().sum()
)

print("Output location:", output_path)

print("\nFirst 5 records:")
print(df.head())

print("\n========================================")
print("CSV FILE SAVED SUCCESSFULLY")
print("========================================")
