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
        WHERE updated_at >= (
            SELECT DATEADD(day, -3, MAX(updated_at))
            FROM {{ this }} 
        )
    {% endif %}
),
silver_cleaned AS (

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
            {{ calc_total_revenue(
                'booking_amount',
                'cleaning_fee',
                'service_fee'
            ) }}
        AS DECIMAL(10,2)) AS expected_revenue,
        CAST(
            {{ calc_actual_revenue(
                'booking_status', 
                'expected_revenue', 
                'cancellation_fee'
            ) }} AS DECIMAL(10,2)) AS actual_revenue,
        expected_revenue - actual_revenue AS revenue_loss,
        created_at,
        updated_at,  
    FROM silver_cleaned

)

SELECT * FROM silver_enriched 
SELECT * FROM {{ this }}
