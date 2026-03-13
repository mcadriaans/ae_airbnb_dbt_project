{{ config(
    materialized='incremental',
    unique_key='booking_id'
) }}

SELECT *
FROM {{ ref('silver_bookings_cleaned') }}

{% if is_incremental() %}
WHERE created_at > (
    SELECT MAX(created_at) FROM {{ this }}
)
{% endif %}
