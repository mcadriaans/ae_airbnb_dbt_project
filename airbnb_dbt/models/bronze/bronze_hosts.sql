SELECT 
  host_id,
  INITCAP(TRIM(host_name)) AS host_name
  host_since,
  LOWER(TRIM(is_superhost)) AS is_superhost,
  response_rate,
  CAST(created_at AS timestamp_ntz) AS created_at,
  CAST(current_timestamp() as timestamp_ntz) as ingested_at
FROM {{ source('staging', 'hosts')}}







