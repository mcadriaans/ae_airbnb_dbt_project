{{
    config(
        materialized='incremental',
        unique_key='host_id',
        incremental_strategy='merge',
        transient=true
    )
}}

WITH source_data AS (
    SELECT 
        host_id,
        host_name,
        host_since,
        host_location,
        is_superhost,
        response_rate,
        avg_host_rating,
        created_at,
        updated_at
    FROM {{ source('airbnb', 'bronze_hosts') }}

    {% if is_incremental() %}
      -- This only runs on incremental runs, not on the first run or --full-refresh
      WHERE updated_at >= (
          SELECT DATEADD(day, -3, COALESCE(MAX(updated_at), '1900-01-01'::timestamp_ntz))
          FROM {{ this }}
      )
    {% endif %}
),

silver_hosts_cleaned AS (
    SELECT 
        CAST(host_id AS NUMERIC(38,0)) AS host_id,
        INITCAP(TRIM(host_name)) AS host_name,
        CAST(host_since AS DATE) AS host_since,
        INITCAP(TRIM(host_location)) AS host_location,
        COALESCE(is_superhost, false) AS is_superhost,
        (CAST(response_rate AS DECIMAL(10,2))/100.0) AS response_rate,
        CAST(avg_host_rating AS DECIMAL(10,2)) AS avg_host_rating,
        CAST(created_at AS timestamp_ntz) AS created_at,
        CAST(updated_at AS timestamp_ntz) AS updated_at
    FROM source_data
),

silver_hosts_enriched AS (
    SELECT 
        *,
        -- Calculate host tenure in years
        ROUND(DATEDIFF('day', host_since, CURRENT_DATE) / 365.25, 1) AS host_tenure_years,
        -- Categorize hosts based on average rating
        CASE 
            WHEN avg_host_rating >= 4.5 THEN 'Excellent'
            WHEN avg_host_rating >= 4.0 THEN 'Good'
            WHEN avg_host_rating >= 3.0 THEN 'Average'
            WHEN avg_host_rating IS NULL THEN 'No Reviews'
            ELSE 'Below Average'
        END AS host_rating_category,
        -- Metadata for tracking
         CAST(current_timestamp() AS timestamp_ntz) AS loaded_at
    FROM silver_hosts_cleaned
)


SELECT * FROM silver_hosts_enriched}}