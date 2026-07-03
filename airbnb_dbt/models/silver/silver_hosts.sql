-- models/silver/silver_hosts.sql
-- SCD1: One row per host (just latest state)
-- When host data changes: OVERWRITE old row, don't track history

--> 'delete+insert' :   One row per host. Old state completely replaced.
{{
    config(
        materialized='incremental',
        unique_key='host_id',
        incremental_strategy='delete+insert', 
        on_schema_change='sync_all_columns'
    )
}}

WITH last_run AS (
    SELECT 
        COALESCE(MAX(loaded_at), '1900-01-01'::timestamp_ltz) AS last_loaded_at
    FROM {{ this }}
),

silver_hosts_enriched AS (
    SELECT 
        -- Keys
        host_id,

        -- Dimensions
        host_name,
        host_location,
        is_superhost,
        --- Categorize hosts based on average rating
        CAST(CASE 
            WHEN avg_host_rating >= 4.5 THEN 'Excellent'
            WHEN avg_host_rating >= 4.0 THEN 'Good'
            WHEN avg_host_rating >= 3.0 THEN 'Average'
            WHEN avg_host_rating IS NULL THEN 'No Reviews'
            ELSE 'Below Average'
        END AS VARCHAR) AS host_rating_category,

        -- Dates & Metrics
         host_since,
        --- Calculate host tenure in years
        CAST((DATEDIFF('day', host_since, CURRENT_DATE) / 365.25) AS DECIMAL(18,2)) AS host_tenure_years,
        response_rate,
        avg_host_rating,
        
        
        -- Metadata for tracking
        source_created_at,
        source_updated_at,
        CAST(current_timestamp() AS timestamp_ltz) AS loaded_at
    FROM {{ ref('stg_airbnb__hosts') }}

    {% if is_incremental() %}
        WHERE source_updated_at >= (
          SELECT DATEADD(day, -7, last_loaded_at)  -- Buffer of 7 days to catch late-arriving updates
          FROM last_run
      )
    {% endif %}
)

SELECT * FROM silver_hosts_enriched



