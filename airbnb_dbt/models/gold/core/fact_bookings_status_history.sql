-- models/gold/core/fact_bookings_status_history.sql
-- Grain : One row per booking status change (SCD2).
-- Description: This table exposes the SCD2 history of booking status changes. 
--               It is a child table of fact_bookings, and can be used to 
--               analyze the lifecycle of bookings over time.


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
    -- Generate Primary Surrogate key : one key per version
    {{ dbt_utils.generate_surrogate_key(['booking_id', 'dbt_scd_id'])}} AS status_history_id,

    -- Generate a key to join to fact_bookings.sql
    {{ dbt_utils.generate_surrogate_key(['booking_id']) }} AS booking_key, 

    -- Natural keys for traceability 
    booking_id,
    dbt_scd_id AS booking_version_id,

    -- Status lifecycle 
    version_number,
    previous_status,
    booking_status,
    dbt_valid_from AS status_start_at,
    dbt_valid_to AS status_end_at,

    -- Derived fields
    CASE
        WHEN previous_status IS NULL THEN 'Initial Status'
        WHEN previous_status <> booking_status THEN 'Status Changed'
        ELSE 'No Change'
    END AS status_change_type,

    CASE
        WHEN dbt_valid_to IS NULL THEN NULL
        ELSE DATEDIFF('day', dbt_valid_from, COALESCE(dbt_valid_to, CURRENT_DATE))
    END AS days_in_status,

    CASE
        WHEN version_number = 1 THEN 1 
        ELSE 0
    END AS is_first_version,
    
    is_current_record,
    -- Metadata for auditing
    CAST(CURRENT_TIMESTAMP() AS TIMESTAMP_LTZ) AS core_loaded_at
FROM sequenced