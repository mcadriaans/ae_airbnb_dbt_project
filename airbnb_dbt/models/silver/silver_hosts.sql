SELECT 
  host_id,
  INITCAP(TRIM(host_name)) AS host_name,
  host_since,
  is_superhost,
  response_rate,
  avg_host_rating,
  CAST(created_at AS timestamp_ntz) AS created_at,
  CURRENT_TIMESTAMP() AS ingested_at
FROM {{ source('airbnb', 'bronze_hosts') }}





