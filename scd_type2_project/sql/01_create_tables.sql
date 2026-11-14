
-- ============================================================
-- FILE: 01_create_tables.sql
-- PROJECT: SCD Type 2 Data Engineering Pipeline
--
-- PURPOSE:
-- Create the database and required tables for storing
-- customer events, historical customer versions and
-- pipeline execution details.
-- ============================================================


-- STEP 1: CREATE DATABASE

IF DB_ID('scd_type2_db') IS NULL
BEGIN
    CREATE DATABASE scd_type2_db;
END;
GO

USE scd_type2_db;
GO


-- STEP 2: CREATE RAW CUSTOMER EVENTS TABLE

IF OBJECT_ID('dbo.raw_customer_events', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.raw_customer_events
    (
        event_id VARCHAR(30) NOT NULL PRIMARY KEY,

        customer_id VARCHAR(30) NOT NULL,

        customer_name VARCHAR(100) NOT NULL,

        city VARCHAR(100) NOT NULL,

        country VARCHAR(100) NOT NULL,

        email VARCHAR(150) NOT NULL,

        event_date DATETIME2(0) NOT NULL,

        source_file VARCHAR(255) NOT NULL,

        run_id VARCHAR(36) NOT NULL,

        loaded_at DATETIME2(0) NOT NULL
            DEFAULT SYSUTCDATETIME()
    );
END;
GO


-- STEP 3: CREATE SCD TYPE 2 DIMENSION TABLE

IF OBJECT_ID('dbo.dim_customer', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.dim_customer
    (
        customer_sk BIGINT IDENTITY(1,1) PRIMARY KEY,

        customer_id VARCHAR(30) NOT NULL,

        customer_name VARCHAR(100) NOT NULL,

        city VARCHAR(100) NOT NULL,

        country VARCHAR(100) NOT NULL,

        email VARCHAR(150) NOT NULL,

        effective_start_date DATETIME2(0) NOT NULL,

        effective_end_date DATETIME2(0) NOT NULL,

        is_current BIT NOT NULL,

        hash_diff CHAR(64) NOT NULL,

        created_run_id VARCHAR(36) NOT NULL,

        CONSTRAINT CK_dim_customer_dates
        CHECK (effective_end_date > effective_start_date)
    );
END;
GO


-- STEP 4: ENSURE ONLY ONE CURRENT ROW PER CUSTOMER

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE name = 'UX_dim_customer_current'
      AND object_id = OBJECT_ID('dbo.dim_customer')
)
BEGIN
    CREATE UNIQUE INDEX UX_dim_customer_current
    ON dbo.dim_customer(customer_id)
    WHERE is_current = 1;
END;
GO


-- STEP 5: CREATE PIPELINE RUN LOG TABLE

IF OBJECT_ID('dbo.pipeline_run_log', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.pipeline_run_log
    (
        run_id VARCHAR(36) PRIMARY KEY,

        pipeline_name VARCHAR(100) NOT NULL,

        start_time DATETIME2(0) NOT NULL,

        end_time DATETIME2(0) NULL,

        run_status VARCHAR(20) NOT NULL,

        input_count INT DEFAULT 0,

        valid_count INT DEFAULT 0,

        rejected_count INT DEFAULT 0,

        inserted_count INT DEFAULT 0,

        updated_count INT DEFAULT 0,

        error_message VARCHAR(MAX) NULL
    );
END;
GO


-- STEP 6: VERIFY TABLE CREATION

SELECT TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE';

PRINT 'SCD Type 2 database and tables created successfully!';
GO
