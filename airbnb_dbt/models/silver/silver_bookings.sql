{{
    config(
        materialized='incremental',
        unique_key='host_id',
        incremental_strategy='merge',
        transient= true
    )
}}


WITH source_data AS (

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
        CAST(created_at AS timestamp_ntz) AS created_at,
        CAST(updated_at AS timestamp_ntz) AS updated_at
    FROM {{ source('airbnb', 'bronze_bookings') }}

    
    {% if is_incremental() %}
      -- This only runs on incremental runs, not on the first run or --full-refresh
      WHERE updated_at >= (
          SELECT DATEADD(day, -3, COALESCE(MAX(updated_at), '1900-01-01'::timestamp_ntz))
          FROM {{ this }}
      )
    {% endif %}
),
silver_bookings_cleaned AS (
    SELECT
        LOWER(TRIM(booking_id)) AS booking_id,
        booking_date,
        LOWER(TRIM(booking_status)) AS booking_status,
        listing_id,
        stay_start_date,
        nights_booked,
        booking_amount,
        cleaning_fee,
        service_fee,
        cancellation_fee,
        created_at,
        updated_at  
    FROM source_data
),

silver_bookings_enriched AS (
    SELECT
        booking_id,
        listing_id,
        booking_status,
        booking_date,
        stay_start_date,
        DATEDIFF(day, booking_date, stay_start_date) AS lead_time_days,
        nights_booked,
        DATEADD(day, nights_booked, stay_start_date) AS stay_end_date,
        booking_amount,
        cleaning_fee,
        service_fee,
        cancellation_fee,
        CAST(
            {{ calc_expected_revenue(
                'booking_amount',
                'cleaning_fee',
                'service_fee'
            ) }} AS DECIMAL(18,2)) AS expected_revenue,
        created_at,
        updated_at,
        CAST(current_timestamp() AS timestamp_ntz) AS loaded_at
    FROM silver_bookings_cleaned
)

SELECT * FROM silver_bookings_enriched