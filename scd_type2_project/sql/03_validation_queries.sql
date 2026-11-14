

USE scd_type2_db;
GO

-- ============================================
-- CHECK 1: VIEW ALL CUSTOMER HISTORY
-- ============================================

SELECT
    customer_sk,
    customer_id,
    customer_name,
    city,
    salary,
    effective_from,
    effective_to,
    is_current,
    record_hash
FROM dbo.dim_customer
ORDER BY customer_id, effective_from;
GO


-- ============================================
-- CHECK 2: CHECK DUPLICATE CUSTOMER VERSIONS
-- ============================================

SELECT
    customer_id,
    effective_from,
    COUNT(*) AS duplicate_count
FROM dbo.dim_customer
GROUP BY customer_id, effective_from
HAVING COUNT(*) > 1;
GO


-- ============================================
-- CHECK 3: CHECK MULTIPLE CURRENT RECORDS
-- ============================================

SELECT
    customer_id,
    COUNT(*) AS current_count
FROM dbo.dim_customer
WHERE is_current = 1
GROUP BY customer_id
HAVING COUNT(*) > 1;
GO


-- ============================================
-- CHECK 4: CHECK CURRENT RECORD END DATES
-- ============================================

SELECT *
FROM dbo.dim_customer
WHERE
    (is_current = 1 AND effective_to IS NOT NULL)
    OR
    (is_current = 0 AND effective_to IS NULL);
GO


-- ============================================
-- CHECK 5: CHECK INVALID DATE RANGES
-- ============================================

SELECT *
FROM dbo.dim_customer
WHERE effective_to IS NOT NULL
  AND effective_to <= effective_from;
GO


-- ============================================
-- CHECK 6: CHECK OVERLAPPING DATE RANGES
-- ============================================

WITH CustomerTimeline AS
(
    SELECT
        customer_id,
        effective_from,
        effective_to,

        LEAD(effective_from) OVER
        (
            PARTITION BY customer_id
            ORDER BY effective_from
        ) AS next_effective_from

    FROM dbo.dim_customer
)

SELECT *
FROM CustomerTimeline
WHERE effective_to IS NOT NULL
  AND next_effective_from IS NOT NULL
  AND effective_to > next_effective_from;
GO


-- ============================================
-- CHECK 7: CHECK DUPLICATE SOURCE EVENTS
-- ============================================

SELECT
    source_event_id,
    COUNT(*) AS event_count
FROM dbo.raw_customer_events
GROUP BY source_event_id
HAVING COUNT(*) > 1;
GO


-- ============================================
-- CHECK 8: PIPELINE EXECUTION REPORT
-- ============================================

SELECT
    run_id,
    start_time,
    end_time,
    status,
    input_count,
    accepted_count,
    rejected_count,
    inserted_count,
    updated_count,
    failure_reason
FROM dbo.pipeline_runs
ORDER BY start_time DESC;
GO


-- ============================================
-- CHECK 9: REJECTED RECORD REPORT
-- ============================================

SELECT
    reject_id,
    source_event_id,
    source_file,
    rejection_reason,
    rejected_at
FROM dbo.rejected_records
ORDER BY rejected_at DESC;
GO


-- ============================================
-- CHECK 10: CURRENT CUSTOMER REPORT
-- ============================================

SELECT
    customer_id,
    customer_name,
    city,
    salary,
    effective_from
FROM dbo.dim_customer
WHERE is_current = 1
ORDER BY customer_id;
GO

PRINT 'SCD TYPE 2 VALIDATION COMPLETED';
GO

select @@SERVERNAME as servername



USE scd_type2_db;
GO

SELECT COUNT(*) AS Total_Raw_Records
FROM dbo.raw_customer_events;

SELECT *
FROM dbo.raw_customer_events
ORDER BY customer_id, effective_at;





    FETCH NEXT FROM customer_cursor INTO @customer_id;
END

CLOSE customer_cursor;
DEALLOCATE customer_cursor;

PRINT 'SCD TYPE 2 TRANSFORMATION COMPLETED';
GO  


USE scd_type2_db;
GO

-- Check whether the stored procedure exists
IF OBJECT_ID('dbo.usp_rebuild_customer_scd2', 'P') IS NULL
BEGIN
    THROW 50001, 'SCD Type 2 stored procedure not found.', 1;
END;
GO

-- Execute the procedure for every customer
DECLARE @customer_id INT;

DECLARE customer_cursor CURSOR LOCAL FAST_FORWARD
FOR
    SELECT DISTINCT customer_id
    FROM dbo.raw_customer_events
    WHERE customer_id IS NOT NULL
    ORDER BY customer_id;

OPEN customer_cursor;

FETCH NEXT FROM customer_cursor INTO @customer_id;

WHILE @@FETCH_STATUS = 0
BEGIN
    PRINT 'Processing Customer ID: ' + CAST(@customer_id AS VARCHAR(20));

    EXEC dbo.usp_rebuild_customer_scd2
        @customer_id = @customer_id;

    FETCH NEXT FROM customer_cursor INTO @customer_id;
END;

CLOSE customer_cursor;
DEALLOCATE customer_cursor;

PRINT 'SCD TYPE 2 TRANSFORMATION COMPLETED';
GO


SELECT
    customer_sk,
    customer_id,
    customer_name,
    city,
    salary,
    effective_from,
    effective_to,
    is_current
FROM dbo.dim_customer
ORDER BY customer_id, effective_from;


SELECT *
FROM dbo.dim_customer
WHERE is_current = 1;


USE scd_type2_db;
GO

SELECT
    customer_id,
    COUNT(*) AS Total_Versions,
    SUM(CASE WHEN effective_to IS NULL THEN 1 ELSE 0 END)
        AS Null_End_Dates,
    SUM(CASE WHEN is_current = 1 THEN 1 ELSE 0 END)
        AS Current_Records
FROM dbo.dim_customer
GROUP BY customer_id
ORDER BY customer_id;



SELECT
    customer_id,
    customer_name,
    effective_from,
    effective_to,
    is_current
FROM dbo.dim_customer
ORDER BY customer_id, effective_from;


USE scd_type2_db;
GO

-- 1. Check duplicate customer versions
SELECT customer_id, effective_from, COUNT(*) AS duplicate_count
FROM dbo.dim_customer
GROUP BY customer_id, effective_from
HAVING COUNT(*) > 1;

-- 2. Check customers with multiple current records
SELECT customer_id, COUNT(*) AS current_count
FROM dbo.dim_customer
WHERE is_current = 1
GROUP BY customer_id
HAVING COUNT(*) > 1;

-- 3. Check current records have NULL effective_to
SELECT *
FROM dbo.dim_customer
WHERE is_current = 1
  AND effective_to IS NOT NULL;

-- 4. Check historical records have an end date
SELECT *
FROM dbo.dim_customer
WHERE is_current = 0
  AND effective_to IS NULL;

-- 5. Check invalid date ranges
SELECT *
FROM dbo.dim_customer
WHERE effective_to IS NOT NULL
  AND effective_to <= effective_from;
GO
 


 
USE scd_type2_db;
GO

SELECT COUNT(*) AS Total_Raw_Events
FROM dbo.raw_customer_events;

SELECT COUNT(*) AS Total_Dimension_Records
FROM dbo.dim_customer;

SELECT *
FROM dbo.pipeline_runs
ORDER BY start_time DESC;
====================
-- check rejected records in SSMS

USE scd_type2_db;
GO

SELECT
    source_event_id,
    rejection_reason,
    source_file,
    rejected_at
FROM dbo.rejected_records
ORDER BY rejected_at DESC;


-- verify ssms


USE scd_type2_db;
GO

-- Total records
SELECT COUNT(*) AS Total_Raw_Events
FROM dbo.raw_customer_events;

-- Check duplicate event IDs
SELECT
    source_event_id,
    COUNT(*) AS Duplicate_Count
FROM dbo.raw_customer_events
GROUP BY source_event_id
HAVING COUNT(*) > 1;

-- Check the duplicate event
SELECT *
FROM dbo.raw_customer_events
WHERE source_event_id = 'EVT001';
