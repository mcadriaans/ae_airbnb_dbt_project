
-- silver_bookings.sql : Enriched booking facts with SCD2 history
-- Input: bookings_snapshot (SCD2 tracking booking changes)
-- Output: Facts enriched with calculations, all versions preserved
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
        booking_id,
        booking_date,
        booking_status,
        listing_id,
        stay_start_date,
        nights_booked,
        booking_amount,
        cleaning_fee,
        service_fee,
        cancellation_fee,
        created_at,
        updated_at,
        dbt_scd_id,
        dbt_updated_at,
        dbt_valid_from,
        dbt_valid_to
    FROM {{ ref('bookings_snapshot') }}
  

    {% if is_incremental() %}
      -- Only grab snapshot rows that are NEW to silver  
      WHERE dbt_valid_from >= (
          SELECT COALESCE(MAX(dbt_valid_from), '1900-01-01'::timestamp_ntz)
          FROM {{ this }}
      )
    {% endif %}
),

silver_bookings_enriched AS (
    SELECT
          -- Keys
        booking_id,
        listing_id,

        -- Dimensions
        booking_status,

        -- Dates
        booking_date,
        stay_start_date,
        DATEADD(day, nights_booked, stay_start_date) AS stay_end_date,  -- Calculate stay end date based on start date and nights booked

        -- Durations
        DATEDIFF(day, booking_date, stay_start_date) AS lead_time_days,   -- Calculate lead time in days between booking date and stay start date
        nights_booked,

        -- Amounts
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



        -- SCD2 / History Tracking
        dbt_scd_id,
        dbt_valid_from,
        dbt_valid_to,
        CASE WHEN dbt_valid_to IS NULL THEN 1 ELSE 0 END AS is_current_record,

         -- Metadata
        created_at,
        updated_at,
        dbt_updated_at,
        CAST(current_timestamp() AS timestamp_ntz) AS loaded_at   -- tracking when this record hits the silver layer
    FROM booking_snapshot_data 
)
SELECT * FROM silver_bookings_enriched