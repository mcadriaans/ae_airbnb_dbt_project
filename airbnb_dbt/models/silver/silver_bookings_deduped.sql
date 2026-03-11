{{ config(
    materialized='incremental',
    unique_key='booking_id'
) }}

SELECT *
FROM {{ ref('silver_bookings_cleaned') }}
