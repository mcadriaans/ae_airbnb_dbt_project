{{ config(
    materialized='incremental',
    unique_key='listing_id',
    transient=true
) }}

SELECT 
  listing_id,
  host_id,
  LOWER(TRIM(property_type)) AS property_type,
  LOWER(TRIM(room_type)) AS room_type,
  INITCAP(TRIM(city)) AS city,
  INITCAP(TRIM(country)) AS country,
  accommodates,
  bedrooms,
  bathrooms,
  price_per_night,
  CAST(created_at AS timestamp_ntz) AS created_at,
  CAST(current_timestamp() AS timestamp_ntz) AS ingested_at
FROM {{ source('staging', 'listings') }}

{% if is_incremental() %}
  -- Only pull new or updated rows
  WHERE created_at >= (
    SELECT COALESCE(MAX(created_at), '1900-01-01') 
    FROM {{ this }}
    )
{% endif %}








