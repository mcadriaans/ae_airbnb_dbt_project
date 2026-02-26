{{ 
  config(
    materialized='incremental',
    unique_key='host_id'
  ) 
}}

WITH base AS (
  SELECT *
  FROM {{ ref('bronze_hosts')}}
)

SELECT 
    host_id,
    {{ normalize_name('host_name') }} AS host_name,
    host_since,
    is_superhost,
    response_rate,
    created_at,
    {{ date_diff("'year'", 'host_since', 'current_date') }} AS host_tenure_years,
    CASE 
      WHEN response_rate >= 90 THEN 'high' 
      WHEN response_rate >= 70 THEN 'medium' 
      ELSE 'low' 
    END AS response_rate_bucket, 
    CASE 
      WHEN is_superhost THEN 'superhost' 
      ELSE 'standard' 
    END AS host_type
FROM base