
# PURPOSE:
# Test customer record validation before loading data into SQL Server.
# These tests verify valid records and common data-quality errors.

import pytest
from decimal import Decimal, InvalidOperation
from datetime import datetime

from src.ingestion import validate_record


# PURPOSE: Create a standard valid customer record for testing.
# This avoids writing the same test data repeatedly.

def get_valid_record():

    return {
        "source_event_id": "EVT_TEST_001",
        "customer_id": "101",
        "customer_name": "Alice",
        "city": "Hyderabad",
        "salary": "50000",
        "effective_at": "2026-01-10 09:00:00",
        "source_sequence": "1"
    }


# TEST 1: Verify that a valid customer record is accepted.

def test_valid_customer():

    row = get_valid_record()

    result = validate_record(row)

    assert result[0] == "EVT_TEST_001"
    assert result[1] == 101
    assert result[4] == Decimal("50000")


# TEST 2: Verify that a missing event ID is rejected.

def test_missing_event_id():

    row = get_valid_record()
    row["source_event_id"] = ""

    with pytest.raises(ValueError):
        validate_record(row)


# TEST 3: Verify that a missing customer name is rejected.

def test_missing_customer_name():

    row = get_valid_record()
    row["customer_name"] = ""

    with pytest.raises(ValueError):
        validate_record(row)


# TEST 4: Verify that a missing city is rejected.

def test_missing_city():

    row = get_valid_record()
    row["city"] = ""

    with pytest.raises(ValueError):
        validate_record(row)


# TEST 5: Verify that an invalid customer ID is rejected.

def test_invalid_customer_id():

    row = get_valid_record()
    row["customer_id"] = "0"

    with pytest.raises(ValueError):
        validate_record(row)


# TEST 6: Verify that a negative salary is rejected.

def test_negative_salary():

    row = get_valid_record()
    row["salary"] = "-5000"

    with pytest.raises(ValueError):
        validate_record(row)


# TEST 7: Verify that an invalid salary format is rejected.

def test_invalid_salary():

    row = get_valid_record()
    row["salary"] = "abc"

    with pytest.raises(InvalidOperation):
        validate_record(row)


# TEST 8: Verify that an invalid date format is rejected.

def test_invalid_effective_date():

    row = get_valid_record()
    row["effective_at"] = "invalid-date"

    with pytest.raises(ValueError):
        validate_record(row)


# TEST 9: Verify that an invalid source sequence is rejected.

def test_invalid_source_sequence():

    row = get_valid_record()
    row["source_sequence"] = "0"

    with pytest.raises(ValueError):
        validate_record(row)
