-- silver_hosts.sql : This model transforms raw host data from the bronze layer into a cleaned and enriched format in the silver layer. 
-- It includes data type conversions, calculated fields for host tenure and rating categories, and metadata for tracking data freshness. 
-- The incremental loading strategy ensures efficient updates while maintaining historical data integrity.

{{
    config(
        materialized='incremental',
        unique_key='host_id',
        incremental_strategy='merge',
        on_schema_change='sync_all_columns'
    )
}}

WITH current_snapshot_data AS (
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
    FROM {{ ref('hosts_snapshot') }}
 

    {% if is_incremental() %}
      -- Only grab records updated since the last run  
      AND updated_at >= (
          SELECT DATEADD(day, -7, COALESCE(MAX(updated_at), '1900-01-01'::timestamp_ntz))
          FROM {{ this }}
      )
    {% endif %}
),

silver_hosts_enriched AS (
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

        --SCD Type 2 tracking
        dbt_valid_from,
        dbt_valid_to,
        CASE WHEN dbt_valid_to IS NULL THEN 1 ELSE 0 END AS is_current_record, 

        created_at,
        updated_at,
        -- Metadata for tracking
         CAST(current_timestamp() AS timestamp_ntz) AS loaded_at
    FROM current_snapshot_data
)

SELECT * FROM silver_hosts_enriched



