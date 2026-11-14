
USE scd_type2_db;
GO

CREATE OR ALTER PROCEDURE dbo.usp_rebuild_customer_scd2
    @customer_id INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- =====================================
        -- STEP 1: VALIDATE SOURCE EVENTS
        -- =====================================

        IF NOT EXISTS
        (
            SELECT 1
            FROM dbo.raw_customer_events
            WHERE customer_id = @customer_id
        )
        BEGIN
            COMMIT TRANSACTION;
            RETURN;
        END;

        -- Same customer and effective timestamp
        -- must have a single authoritative event.

        IF EXISTS
        (
            SELECT effective_at
            FROM dbo.raw_customer_events
            WHERE customer_id = @customer_id
            GROUP BY effective_at
            HAVING COUNT(*) > 1
        )
        BEGIN
            THROW 50001,
                'Conflicting events have the same effective timestamp.',
                1;
        END;


        -- =====================================
        -- STEP 2: READ COMPLETE EVENT HISTORY
        -- =====================================

        ;WITH OrderedEvents AS
        (
            SELECT
                source_event_id,
                customer_id,
                customer_name,
                city,
                salary,
                effective_at,

                LAG(customer_name) OVER (
                    PARTITION BY customer_id
                    ORDER BY effective_at, source_sequence,
                             source_event_id
                ) AS previous_name,

                LAG(city) OVER (
                    PARTITION BY customer_id
                    ORDER BY effective_at, source_sequence,
                             source_event_id
                ) AS previous_city,

                LAG(salary) OVER (
                    PARTITION BY customer_id
                    ORDER BY effective_at, source_sequence,
                             source_event_id
                ) AS previous_salary

            FROM dbo.raw_customer_events
            WHERE customer_id = @customer_id
        ),

        ChangedEvents AS
        (
            SELECT *
            FROM OrderedEvents
            WHERE
                previous_name IS NULL
                OR customer_name <> previous_name
                OR city <> previous_city
                OR salary <> previous_salary
        ),

        Timeline AS
        (
            SELECT
                customer_id,
                customer_name,
                city,
                salary,
                effective_at AS effective_from,

                LEAD(effective_at) OVER (
                    PARTITION BY customer_id
                    ORDER BY effective_at
                ) AS effective_to

            FROM ChangedEvents
        )

        SELECT
            customer_id,
            customer_name,
            city,
            salary,
            effective_from,
            effective_to,

            CAST(
                CASE
                    WHEN effective_to IS NULL THEN 1
                    ELSE 0
                END AS BIT
            ) AS is_current,

            CONVERT(
                CHAR(64),
                HASHBYTES(
                    'SHA2_256',
                    CONCAT(
                        customer_name, '|',
                        city, '|',
                        CONVERT(VARCHAR(30), salary)
                    )
                ),
                2
            ) AS record_hash

        INTO #desired_customer_history

        FROM Timeline;


        -- =====================================
        -- STEP 3: REMOVE OBSOLETE VERSIONS
        -- Preserve matching surrogate keys.
        -- =====================================

        DELETE existing
        FROM dbo.dim_customer AS existing
        WHERE existing.customer_id = @customer_id
          AND NOT EXISTS
          (
              SELECT 1
              FROM #desired_customer_history AS desired
              WHERE desired.customer_id =
                    existing.customer_id
                AND desired.effective_from =
                    existing.effective_from
          );


        -- =====================================
        -- STEP 4: UPDATE EXISTING VERSIONS
        -- =====================================

        UPDATE existing
        SET
            existing.customer_name = desired.customer_name,
            existing.city = desired.city,
            existing.salary = desired.salary,
            existing.effective_to = desired.effective_to,
            existing.is_current = desired.is_current,
            existing.record_hash = desired.record_hash

        FROM dbo.dim_customer AS existing

        INNER JOIN #desired_customer_history AS desired
            ON existing.customer_id = desired.customer_id
           AND existing.effective_from = desired.effective_from;


        -- =====================================
        -- STEP 5: INSERT NEW VERSIONS
        -- =====================================

        INSERT INTO dbo.dim_customer
        (
            customer_id,
            customer_name,
            city,
            salary,
            effective_from,
            effective_to,
            is_current,
            record_hash
        )

        SELECT
            desired.customer_id,
            desired.customer_name,
            desired.city,
            desired.salary,
            desired.effective_from,
            desired.effective_to,
            desired.is_current,
            desired.record_hash

        FROM #desired_customer_history AS desired

        WHERE NOT EXISTS
        (
            SELECT 1
            FROM dbo.dim_customer AS existing
            WHERE existing.customer_id =
                  desired.customer_id
              AND existing.effective_from =
                  desired.effective_from
        );


        DROP TABLE #desired_customer_history;

        COMMIT TRANSACTION;

    END TRY

    BEGIN CATCH

        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;

    END CATCH;
END;
GO
   

   USE scd_type2_db;
GO

SELECT name
FROM sys.procedures
WHERE name = 'usp_rebuild_customer_scd2';
GO