{{ config(
    materialized='incremental',
    unique_key='booking_id',
    incremental_strategy='merge',
    transient=true
) }}
/*
SELECT
  booking_id,
  listing_id,
  CAST(booking_date AS timestamp_ntz) AS booking_date,
  nights_booked,
  CAST(cleaning_fee AS decimal(10,2)) AS cleaning_fee,
  CAST(service_fee AS decimal(10,2)) AS service_fee,
  LOWER(TRIM(booking_status)) AS booking_status,
  CAST(created_at AS timestamp_ntz) AS created_at,
  current_timestamp() AS ingested_at
FROM {{ source('airbnb', 'bronze_bookings') }}
*/

SELECT
    booking_id,
    listing_id,
    CAST(booking_date AS TIMESTAMP_NTZ) AS booking_date,
    CAST(created_at AS TIMESTAMP_NTZ) AS created_at,
    CAST(stay_start_date AS TIMESTAMP_NTZ) AS stay_start_date,
    nights_booked,
    booking_amount,
    cleaning_fee,
    service_fee,
    LOWER(TRIM(booking_status)) AS booking_status,

    -- Business logic
    (booking_amount + cleaning_fee + service_fee) AS total_revenue,
    DATEADD(day, nights_booked, stay_start_date) AS stay_end_date,
    DATEDIFF(day, booking_date, stay_start_date) AS lead_time_days

FROM {{ source('airbnb', 'bronze_bookings') }}
{% if is_incremental() %}
  -- Only pull new or updated rows
  WHERE created_at > (
    SELECT COALESCE(MAX(created_at), CAST('1900-01-01' AS timestamp_ntz)) 
    FROM {{ this }}
    )
{% endif %}
