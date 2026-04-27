{{ config(
    materialized='incremental',
    unique_key='booking_id',
    incremental_strategy='merge'
) }}

{% set relation = adapter.get_relation(
    database=this.database,
    schema=this.schema,
    identifier=this.identifier
) %}

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

    {% if relation is not none and not flags.FULL_REFRESH %}
      WHERE updated_at >= (
          SELECT DATEADD(
              day, -3,
              COALESCE(MAX(t.updated_at), '1900-01-01'::timestamp_ntz))
          FROM {{ this }}
          )
    {% endif %}
),

silver_cleaned AS (
    SELECT
        LOWER(TRIM(booking_id)) AS booking_id,
        booking_date,
        COALESCE(LOWER(TRIM(booking_status)), 'unknown') AS booking_status,
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

silver_enriched AS (
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
        CURRENT_TIMESTAMP() AS loaded_at
    FROM silver_cleaned
)

SELECT * FROM silver_enriched;