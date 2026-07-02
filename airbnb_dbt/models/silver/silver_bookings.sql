
-- silver/silver_bookings.sql : Enriched booking facts with SCD2 history
-- Input: bookings_snapshot (SCD2 tracking booking changes)
-- Output: Facts enriched with calculations, all versions preserved

--> 'merge': implies versioning
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

        --Bi-temporal Tracking
        source_created_at,
        source_updated_at,
        dbt_scd_id,
        dbt_updated_at,
        dbt_valid_from,
        dbt_valid_to

    FROM {{ ref('bookings_snapshot') }}
    {% if is_incremental() %}
      -- Only grab snapshot rows that are NEW to silver  
      WHERE dbt_updated_at >= (
          SELECT COALESCE(MAX(dbt_updated_at), '1900-01-01'::timestamp_ntz)
          FROM {{ this }}
      )
    {% endif %}
),

silver_bookings_enriched AS (
    SELECT
        -- Surrogate Keys (Internal Warehouse Joins)
        dbt_scd_id,   -- Primary Key: Identifies this specific version of the booking record
        booking_key,  -- Entity Key: Identifies the booking itself (across versions)
        listing_key,  -- Foreign Key: Identifies the property listing associated with this booking

        -- Natural Keys (Business Traceability & Debugging)
        booking_id,  -- Original ID from source system (UUID)
        listing_id,  -- Original ID from source system (INT)

        -- Dimensions
        booking_status,

        -- Temporal Dimensions
        booking_date,
        stay_start_date,
        DATEADD(day, nights_booked, stay_start_date) AS stay_end_date,  
        DATEDIFF(day, booking_date, stay_start_date) AS lead_time_days,  
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
        dbt_updated_at,
        CAST(current_timestamp() AS timestamp_ntz) AS silver_loaded_at   -- tracking when this record hits the silver layer
    FROM booking_snapshot_data 
)
SELECT * FROM silver_bookings_enriched