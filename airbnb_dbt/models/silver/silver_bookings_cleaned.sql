{{ config(
    materialized='view',
) }}

WITH BASE AS (
    SELECT * FROM {{ ref('bronze_bookings') }}
)

SELECT
    booking_id,
    listing_id,
    TO_DATE(booking_date) AS booking_date,
    nights_booked,
    CAST(booking_amount as number(38,2)) as booking_amount,
    CAST(cleaning_fee as number(38,2)) as cleaning_fee,
    CAST(service_fee as number(38,2)) as service_fee,
    {{ normalize_text('booking_status') }} as booking_status,
    created_at
FROM BASE
