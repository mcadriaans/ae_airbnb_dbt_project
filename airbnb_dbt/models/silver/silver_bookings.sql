
-- models/silver/silver_bookings.sql : Enriched booking facts with SCD2 history

-- Input: bookings_snapshot (SCD2 tracking booking changes)
-- Output: Facts enriched with calculations, all versions preserved

--> 'merge' updates existing versions and inserts new versions.
-- SCD Type 2 history is managed by the upstream snapshot.
{{
    config(
        materialized='incremental',
        unique_key= 'dbt_scd_id',
        incremental_strategy='merge',
        on_schema_change='sync_all_columns'
    )
}}

WITH booking_snapshot_data AS (
    SELECT 
        -- Natural Keys & Status
        booking_id,
        listing_id,
        booking_status,

        -- Dates
        booking_date,
        stay_start_date,
        nights_booked,

        -- Financials
        booking_amount,
        cleaning_fee,
        service_fee,
        cancellation_fee,

        -- Source Metadata 
        source_created_at,
        source_updated_at,

        -- Snapshot Metadata (SCD2)
        dbt_scd_id,
        dbt_updated_at,
        dbt_valid_from,
        dbt_valid_to

    FROM {{ ref('bookings_snapshot') }}
),
silver_bookings_enriched AS (
    SELECT
        -- Identifiers
        dbt_scd_id,   -- Primary Key: Identifies this specific version of the booking record
        booking_id,  -- Original ID from source system (UUID)
        listing_id,  -- Original ID from source system (INT)

        -- Dimensions
        booking_status,

        -- Temporal Dimensions
        booking_date,
        stay_start_date,
        DATEADD(day, nights_booked, stay_start_date) AS stay_end_date,  -- Checkout date   
        DATEDIFF(day, booking_date, stay_start_date) AS lead_time_days,  -- Measure booking urgency (Lead Time)
        nights_booked,

        -- Financial Metrics
        booking_amount,
        cleaning_fee,
        service_fee,
        cancellation_fee,
        CAST(
            {{ calc_booking_revenue(
                'booking_amount',
                'cleaning_fee',
                'service_fee'
            ) }} AS DECIMAL(18,2)) AS booking_revenue,



        -- SCD2 Logic 
        dbt_valid_from,
        dbt_valid_to,
        CASE WHEN dbt_valid_to IS NULL THEN 1 ELSE 0 END AS is_current_record,

         -- Fully Traceability Audit  
        source_created_at,
        source_updated_at,
        dbt_updated_at
    FROM booking_snapshot_data 
),
existing_silver AS (
    {% if is_incremental() %}
        SELECT 
            dbt_scd_id,
            silver_loaded_at
        FROM {{ this }}
    {% else %}
        SELECT 
            NULL AS dbt_scd_id,
            NULL::TIMESTAMP_LTZ AS silver_loaded_at
        WHERE 1 = 0
    {% endif %}
)
SELECT 
    silver_bookings_enriched.*,

    COALESCE(
        existing_silver.silver_loaded_at,
        CAST(current_timestamp() AS timestamp_ltz)
    ) AS silver_loaded_at
FROM silver_bookings_enriched
LEFT JOIN existing_silver
    ON silver_bookings_enriched.dbt_scd_id = existing_silver.dbt_scd_id