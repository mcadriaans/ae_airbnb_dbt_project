SELECT DISTINCT
    host_id,
    host_name,
    is_superhost,
    avg_host_rating
FROM {{ ref('silver_hosts') }}