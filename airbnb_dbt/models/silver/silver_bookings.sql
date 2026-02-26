{{ config(
    materialized='incremental',
    unique_key='booking_id'
) }}

WITH base AS (
    SELECT *
    FROM {{ ref('bronze_bookings') }}
)

SELECT
    booking_id,
    listing_id,
    booking_date,
    nights_booked,
    CAST(booking_amount AS NUMBER(38,2)) AS booking_amount,
    CAST(cleaning_fee AS NUMBER(38,2)) AS cleaning_fee,
    CAST(service_fee AS NUMBER(38,2)) AS service_fee,
    {{ normalize_text('booking_status') }} AS booking_status,
    created_at,
    CAST({{ add_columns(['booking_amount', 'cleaning_fee', 'service_fee']) }} as NUMBER(38,2)) as total_amount,
    CAST({{ divide_cols('booking_amount', 'nights_booked') }}  as NUMBER(38,2)) AS booking_amount_per_night
FROM BASE
