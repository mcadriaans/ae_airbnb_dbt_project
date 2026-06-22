-- models/silver/silver_hosts.sql
-- SCD1: One row per host (just latest state)
-- When host data changes: OVERWRITE old row, don't track history

{{
    config(
        materialized='incremental',
        unique_key='host_id',
        incremental_strategy='delete+insert',
        on_schema_change='sync_all_columns'
    )
}}

WITH silver_hosts_enriched AS (
    SELECT 
        host_id,
        host_name,
        host_since,
        host_location,

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

        is_superhost,
        response_rate,
        avg_host_rating,

        created_at,
        updated_at,
        -- Metadata for tracking
         CAST(current_timestamp() AS timestamp_ntz) AS loaded_at
    FROM {{ ref('stg_airbnb__hosts') }}

        {% if is_incremental() %}
      -- Only grab records updated since the last run  
      -- 7-day lookback handles late arrivals in source data
        WHERE updated_at >= (
          SELECT DATEADD(day, -7, COALESCE(MAX(updated_at), '1900-01-01'::timestamp_ntz))
          FROM {{ this }}
      )
    {% endif %}
)

SELECT * FROM silver_hosts_enriched



