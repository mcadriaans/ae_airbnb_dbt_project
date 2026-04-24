
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
  CAST(price_per_night AS DECIMAL(10,2)) AS price_per_night,
  CAST(created_at AS timestamp_ntz) AS created_at,
  CAST(current_timestamp() AS timestamp_ntz) AS ingested_at
FROM {{ source('airbnb', 'bronze_listings') }}










