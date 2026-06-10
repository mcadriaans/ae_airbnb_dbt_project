
-- silver_bookings.sql : This model transforms raw booking data from the bronze layer into a cleaned and enriched format in the silver layer. 
--It includes data type conversions, calculated fields for lead time and stay end date, and a standardized booking revenue calculation. 
--The incremental loading strategy ensures efficient updates while maintaining historical data integrity.
{{
    config(
        materialized='incremental',
        unique_key='booking_id',
        incremental_strategy='merge',
        on_schema_change='sync_all_columns'
    )
}}

WITH current_snapshot_data AS (
    SELECT 
        booking_key,
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
        --SCD Type 2 tracking
        dbt_valid_from,
        dbt_valid_to,
        CASE WHEN dbt_valid_to IS NULL THEN 1 ELSE 0 END AS is_current_record, 
        created_at,
        updated_at
    FROM {{ ref('bookings_snapshot') }}
    WHERE dbt_valid_to IS NULL -- Only consider the current valid records from the snapshot

    {% if is_incremental() %}
      -- Only grab records updated since the last run  
      AND updated_at >= (
          SELECT DATEADD(day, -7, COALESCE(MAX(updated_at), '1900-01-01'::timestamp_ntz))
          FROM {{ this }}
      )
    {% endif %}
),

silver_bookings_enriched AS (
    SELECT
        booking_key,
        booking_id,
        listing_id,
        booking_status,
        booking_date,
        stay_start_date,

        -- Calculate lead time in days between booking date and stay start date
        DATEDIFF(day, booking_date, stay_start_date) AS lead_time_days,

        nights_booked,

        -- Calculate stay end date based on start date and nights booked
        DATEADD(day, nights_booked, stay_start_date) AS stay_end_date,

        booking_amount,
        cleaning_fee,
        service_fee,

        -- Booking revenue for each booking, handling nulls gracefully
        CAST(
            {{ calc_booking_revenue(
                'booking_amount',
                'cleaning_fee',
                'service_fee'
            ) }} AS DECIMAL(18,2)) AS booking_revenue,

        cancellation_fee,
        dbt_valid_from,
        dbt_valid_to,
        is_current_record,
        created_at,
        updated_at,

         -- Metadata for tracking when this record hits the silver layer
        CAST(current_timestamp() AS timestamp_ntz) AS loaded_at
    FROM current_snapshot_data 
)
SELECT * FROM silver_bookings_enriched