{{ config(
    materialized='incremental',
    unique_key='booking_id',
    incremental_strategy='merge',
    transient=true
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
  current_timestamp() AS ingested_at
FROM {{ source('airbnb', 'bronze_bookings') }}

{% if is_incremental() %}
  -- Only pull new or updated rows
  WHERE created_at > (
    SELECT COALESCE(MAX(created_at), '1900-01-01') 
    FROM {{ this }}
    )
{% endif %}
