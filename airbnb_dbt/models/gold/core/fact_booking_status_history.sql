-- models/gold/core/fact_booking_status_history.sql
-- Grain : One row per booking snapshot version (SCD2).
-- Description: This fact table tracks the historical evolution of each booking's status,
--              preserving the sequence of recorded booking statuses over time.
--            
--              Each row represents a version of a booking captured in the silver layer.
--              By comparing the status of each version with the preceding version, the model
--              identifies whether the booking's status was initially recorded, changed, or
--              remained unchanged between consecutive versions.
--              
--              The validity timestamps (dbt_valid_from, dbt_valid_to) define the period
--              during which each booking version was active. Together with the version sequence
--              and current-record indicator, they support the analysis of booking status transitions
--              and historical booking states.
--
--              Analytical purpose:
--              Supports analysis of booking status transitions, cancellation patterns,
--              booking lifecycles, and the duration of recorded booking versions.
--
--              Relationship:
--              booking_key links historical booking versions to the corresponding booking
--              in fact_bookings, allowing historical status information to be analysed alongside
--              current booking measures.            



{{ config(materialized='table') }}

WITH versions AS (
    SELECT 
        booking_id,
        dbt_scd_id,
        booking_status,
        dbt_valid_from,
        dbt_valid_to,
        is_current_record
    FROM {{ ref('silver_bookings') }}
    
),

sequenced AS (
    SELECT 
        *,
        ROW_NUMBER()OVER(
            PARTITION BY booking_id
            ORDER BY dbt_valid_from, dbt_scd_id
        ) AS version_number,
        LAG(booking_status) OVER(
                PARTITION BY booking_id
                ORDER BY dbt_valid_from, dbt_scd_id
            ) AS previous_status
    FROM versions
)
SELECT 
    -- Primary Surrogate Key : uniquely identifies each booking history version
    {{ dbt_utils.generate_surrogate_key(['booking_id', 'dbt_scd_id']) }} AS booking_status_history_key,
    {{ dbt_utils.generate_surrogate_key(['booking_id', 'dbt_scd_id'])}} AS status_history_id,

    -- Foreign Key: links each historical version to its booking in fact_bookings
    {{ dbt_utils.generate_surrogate_key(['booking_id']) }} AS booking_key, 

    -- Natural keys for traceability 
    booking_id,
    dbt_scd_id AS booking_version_id,

    -- Status lifecycle 
    version_number,
    previous_status,
    booking_status,
    dbt_valid_from AS version_valid_from,
    dbt_valid_to AS version_valid_to,

    -- Derived fields
    CASE
        WHEN version_number = 1 THEN 'Initial Status'
        WHEN previous_status IS DISTINCT FROM booking_status THEN 'Status Changed'
        ELSE 'No Change'
    END AS status_change_type,

    CASE
        WHEN dbt_valid_to IS NULL THEN NULL
        ELSE DATEDIFF('day', dbt_valid_from, dbt_valid_to)
    END AS days_in_version,

    CASE
        WHEN version_number = 1 THEN 1 
        ELSE 0
    END AS is_first_version,
    
    is_current_record,
    -- Metadata for auditing
    CAST(CURRENT_TIMESTAMP() AS TIMESTAMP_LTZ) AS core_loaded_at
FROM sequenced