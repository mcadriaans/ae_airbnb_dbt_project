-- models/silver/silver_hosts.sql : Enriched host dimensions with SCD2 history

-- Input: hosts_snapshot (SCD2 tracking host changes)
-- Output: Enriched host dimensions, all versions preserved

--> 'merge' updates existing versions and inserts new versions.
-- SCD Type 2 history is managed by the upstream snapshot.
{{
    config(
        materialized='incremental',
        unique_key='dbt_scd_id',
        incremental_strategy='merge', 
        on_schema_change='sync_all_columns'
    )
}}
WITH hosts_snapshot_data AS (
    SELECT 
        -- Keys
        host_id,

        -- Dimensions
        host_name,
        host_location,
        is_superhost,

        -- Dates & Metrics
        host_since,
        response_rate,
        avg_host_rating,
        
        -- Source Metadata for tracking
        source_created_at,
        source_updated_at,
        
        -- Snapshot Metadata (SCD2)
        dbt_scd_id,
        dbt_updated_at,
        dbt_valid_from, 
        dbt_valid_to
    FROM {{ ref('hosts_snapshot') }}
),
silver_hosts_enriched AS (
    SELECT
        -- Identifiers
        dbt_scd_id,   -- Primary Key: Identifies this specific version of the host record
        host_id,      -- Original ID from source system (UUID)

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
        --- Calculate host tenure in years : the number of years a host has been on Airbnb as of today
        CAST((DATEDIFF('day', host_since, CURRENT_DATE) / 365.25) AS DECIMAL(18,2)) AS host_tenure_years,
        response_rate,
        avg_host_rating,

        -- SCD2 Logic
        dbt_valid_from, 
        dbt_valid_to,
        CASE WHEN dbt_valid_to IS NULL THEN 1 ELSE 0 END AS is_current_record,

        -- Full traceability audit
        source_created_at,
        source_updated_at,
        dbt_updated_at
    FROM hosts_snapshot_data
),
existing_silver AS (
    {% if is_incremental() %}
        SELECT 
            dbt_scd_id,
            silver_loaded_at
        FROM {{ this }}
    {% else %}
        SELECT 
            NULL AS dbt_scd_id,
            NULL::TIMESTAMP_LTZ AS silver_loaded_at
        WHERE 1 = 0
    {% endif %}
)
SELECT 
    silver_hosts_enriched.*,

    COALESCE(
        existing_silver.silver_loaded_at,
        CAST(current_timestamp() AS timestamp_ltz)
    ) AS silver_loaded_at
FROM silver_hosts_enriched
LEFT JOIN existing_silver
    ON silver_hosts_enriched.dbt_scd_id = existing_silver.dbt_scd_id



