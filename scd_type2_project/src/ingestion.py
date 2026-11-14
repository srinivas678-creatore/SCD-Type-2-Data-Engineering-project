
import json
import uuid
from pathlib import Path
from datetime import datetime
from decimal import Decimal, InvalidOperation

import pandas as pd

from src.database import get_connection


CSV_FILE = Path("data/customer_events.csv")

REQUIRED_COLUMNS = [
    "source_event_id",
    "customer_id",
    "customer_name",
    "city",
    "salary",
    "effective_at",
    "source_sequence"
]


def validate_record(row):

    if not row["source_event_id"].strip():
        raise ValueError("Missing source_event_id")

    if not row["customer_name"].strip():
        raise ValueError("Missing customer_name")

    if not row["city"].strip():
        raise ValueError("Missing city")

    customer_id = int(row["customer_id"])

    if customer_id <= 0:
        raise ValueError("Invalid customer_id")

    salary = Decimal(row["salary"])

    if not salary.is_finite() or salary < 0:
        raise ValueError("Invalid salary")

    effective_at = datetime.fromisoformat(row["effective_at"])

    source_sequence = int(row["source_sequence"])

    if source_sequence <= 0:
        raise ValueError("Invalid source_sequence")

    return (
        row["source_event_id"],
        customer_id,
        row["customer_name"],
        row["city"],
        salary,
        effective_at,
        source_sequence
    )


def main():

    run_id = str(uuid.uuid4())
    source_file = CSV_FILE.name

    connection = get_connection()
    cursor = connection.cursor()

    input_count = 0
    accepted_count = 0
    rejected_count = 0
    inserted_count = 0
    
    try:

        # Start pipeline execution
        cursor.execute(
            """
            INSERT INTO dbo.pipeline_runs
            (run_id, start_time, status)
            VALUES (?, SYSUTCDATETIME(), 'RUNNING')
            """,
            run_id
        )

        connection.commit()

        # Read CSV file
        df = pd.read_csv(
            CSV_FILE,
            dtype=str,
            keep_default_na=False
        )

        # Validate CSV structure
        if set(df.columns) != set(REQUIRED_COLUMNS):
            raise ValueError(
                f"CSV columns do not match expected schema. "
                f"Found: {df.columns.tolist()}"
            )

        input_count = len(df)

        if input_count == 0:
            raise ValueError("CSV file is empty")

        seen_events = {}

        for _, pandas_row in df.iterrows():

            row = pandas_row.to_dict()

            try:
                event = validate_record(row)

            except (ValueError, TypeError, InvalidOperation) as error:

                cursor.execute(
                    """
                    INSERT INTO dbo.rejected_records
                    (
                        source_event_id,
                        source_file,
                        run_id,
                        raw_payload,
                        rejection_reason
                    )
                    VALUES (?, ?, ?, ?, ?)
                    """,
                    (
                        row.get("source_event_id", ""),
                        source_file,
                        run_id,
                        json.dumps(row),
                        str(error)
                    )
                )

                rejected_count += 1
                continue

            event_id = event[0]

            # Detect duplicates within the CSV
            if event_id in seen_events:

                if seen_events[event_id] == event:
                    accepted_count += 1
                    continue

                cursor.execute(
                    """
                    INSERT INTO dbo.rejected_records
                    (source_event_id, source_file, run_id,
                     raw_payload, rejection_reason)
                    VALUES (?, ?, ?, ?, ?)
                    """,
                    (
                        event_id,
                        source_file,
                        run_id,
                        json.dumps(row),
                        "Conflicting duplicate event ID"
                    )
                )

                rejected_count += 1
                continue

            seen_events[event_id] = event

            # Check previously loaded events
            cursor.execute(
                """
                SELECT customer_id, customer_name, city,
                       salary, effective_at, source_sequence
                FROM dbo.raw_customer_events
                WHERE source_event_id = ?
                """,
                event_id
            )

            existing = cursor.fetchone()

            if existing:

                existing_event = (
                    event_id,
                    int(existing[0]),
                    existing[1],
                    existing[2],
                    Decimal(str(existing[3])),
                    existing[4],
                    int(existing[5])
                )

                if existing_event == event:
                    accepted_count += 1
                    continue

                cursor.execute(
                    """
                    INSERT INTO dbo.rejected_records
                    (source_event_id, source_file, run_id,
                     raw_payload, rejection_reason)
                    VALUES (?, ?, ?, ?, ?)
                    """,
                    (
                        event_id,
                        source_file,
                        run_id,
                        json.dumps(row),
                        "Conflicting event already exists"
                    )
                )

                rejected_count += 1
                continue

            # Insert valid event into SQL Server
            cursor.execute(
                """
                INSERT INTO dbo.raw_customer_events
                (
                    source_event_id,
                    customer_id,
                    customer_name,
                    city,
                    salary,
                    effective_at,
                    source_sequence,
                    source_file,
                    run_id
                )
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                """,
                (*event, source_file, run_id)
            )

            accepted_count += 1
            inserted_count += 1

        # Update pipeline status
        cursor.execute(
            """
            UPDATE dbo.pipeline_runs
            SET end_time = SYSUTCDATETIME(),
                status = 'SUCCESS',
                input_count = ?,
                accepted_count = ?,
                rejected_count = ?,
                inserted_count = ?,
                updated_count = 0
            WHERE run_id = ?
            """,
         (
                input_count,
                accepted_count,
                rejected_count,
                inserted_count,
                run_id
            )
        )

        connection.commit()

        print("\nINGESTION COMPLETED SUCCESSFULLY")
        print("--------------------------------")
        print("Run ID:", run_id)
        print("Input records:", input_count)
        print("Accepted records:", accepted_count)
        print("Rejected records:", rejected_count)
        print("Inserted records:", inserted_count)


    except Exception as error:

        # Roll back uncommitted database changes
        connection.rollback()

        print("\nINGESTION FAILED")
        print("Error:", error)

        # Update pipeline execution status to FAILED
        try:
            cursor.execute(
                """
                UPDATE dbo.pipeline_runs
                SET end_time = SYSUTCDATETIME(),
                    status = 'FAILED',
                    input_count = ?,
                    accepted_count = ?,
                    rejected_count = ?,
                    inserted_count = ?,
                    updated_count = 0,
                    failure_reason = ?
                WHERE run_id = ?
                """,
                (
                    input_count,
                    accepted_count,
                    rejected_count,
                    inserted_count,
                    str(error)[:2000],
                    run_id
                )
            )

            connection.commit()

            print("Pipeline status updated to FAILED.")

        except Exception as status_error:
            connection.rollback()
            print("Could not update failure status:", status_error)

        raise

    finally:
        cursor.close()
        connection.close()


if __name__ == "__main__":
    main()
