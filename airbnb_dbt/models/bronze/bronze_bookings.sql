{{ config(
    materialized='incremental',
    unique_key='booking_id'
) }}

SELECT
  booking_id,
  listing_id,
  CAST(booking_date AS timestamp_ntz) AS booking_date,
  nights_booked,
  cleaning_fee,
  service_fee,
  LOWER(TRIM(booking_status)) AS booking_status,
  CAST(created_at AS timestamp_ntz) AS created_at,
  CAST(current_timestamp() as timestamp_ntz) as ingested_at
FROM {{ source('staging', 'bookings') }}

{% if is_incremental() %}
  - Only pull new or updated rows
  WHERE created_at > (SELECT MAX(created_at) FROM {{ this }})
{% endif %}





