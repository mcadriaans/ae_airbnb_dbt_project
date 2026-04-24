{{ config(
    materialized='incremental',
    unique_key='booking_id',
    incremental_strategy='merge',
    transient=true
) }}

WITH source_data AS (

    SELECT *
    FROM {{ source('airbnb', 'bronze_bookings') }}

    {% if is_incremental() %}
      WHERE created_at >= (
          SELECT DATEADD(
              day, -3,
              COALESCE(MAX(created_at), '1900-01-01'::timestamp_ntz)
          )
          FROM {{ this }}
      )
    {% endif %}

),
silver_cleaned AS (

    SELECT
        booking_id,
        CAST(booking_date AS TIMESTAMP_NTZ) AS booking_date,
        LOWER(TRIM(booking_status)) AS booking_status,
        listing_id,
        nights_booked,
        CAST(booking_amount AS DECIMAL(10,2)) AS booking_amount,
        CAST(cleaning_fee AS DECIMAL(10, 2)) AS cleaning_fee,
        CAST(service_fee AS DECIMAL(10,2)) AS service_fee,
        CAST(cancellation_fee AS DECIMAL(10,2)) AS cancellation_fee,
        CAST(created_at AS TIMESTAMP_NTZ) AS created_at,
        CAST(stay_start_date AS TIMESTAMP_NTZ) AS stay_start_date
    FROM source_data

),

silver_enriched AS (
    SELECT
        *,
        CAST(
            {{ calc_total_revenue(
                'booking_amount',
                'cleaning_fee',
                'service_fee'
            ) }}
        AS DECIMAL(10,2)) AS total_revenue,
        DATEADD(day, nights_booked, stay_start_date) AS stay_end_date,
        DATEDIFF(day, booking_date, stay_start_date) AS lead_time_days
    FROM silver_cleaned

)

SELECT * FROM silver_enriched 
