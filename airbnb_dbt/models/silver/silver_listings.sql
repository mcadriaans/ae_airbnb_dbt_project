-- models/silver/silver_listings.sql : Enriched listing dimensions with SCD2 history

-- Input: listings_snapshot (SCD2 tracking listing changes)
-- Output: Enriched listing dimensions, all versions preserved

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

WITH listings_snapshot_data AS (
    SELECT 
        -- Keys
        listing_id,
        host_id,
        -- Dimensions
        property_type,
        city,
        country,

        -- Metrics
        accommodates,
        bedrooms,
        bathrooms,
        price_per_night,

        -- Metadata for tracking
        source_created_at,
        source_updated_at,

        -- Snapshot Metadata (SCD2)
        dbt_scd_id,
        dbt_updated_at,
        dbt_valid_from,
        dbt_valid_to
    FROM {{ ref('listings_snapshot') }}
),
silver_listings_enriched AS (
    SELECT
        -- Identifiers
        dbt_scd_id,   -- Primary Key: Identifies this specific version of the listing record
        listing_id,
        host_id,

        -- Dimensions
        property_type,
        city,
        country,
        --- Listing size category based on number of bedrooms
        CASE
            WHEN bedrooms IS NULL THEN 'Unknown'
            WHEN bedrooms = 0 THEN 'Studio'
            WHEN bedrooms = 1 THEN '1 Bedroom'
            WHEN bedrooms BETWEEN 2 AND 3 THEN 'Medium (2-3 Bedrooms)'
            ELSE 'Large (4+ Bedrooms)'
        END AS listing_size_category,
        --- Capacity type classification
        CASE
            WHEN accommodates IS NULL THEN 'Unknown'
            WHEN accommodates = 1 THEN 'Solo'
            WHEN accommodates = 2 THEN 'Pair'
            WHEN accommodates BETWEEN 3 AND 5 THEN 'Small Group (3-5)'
            WHEN accommodates BETWEEN 6 AND 10 THEN 'Medium Group (6-10)'
            ELSE 'Large Group (11+)'
        END AS capacity_type,
        --- Price tier categorization based on price per night
        CASE
            WHEN price_per_night IS NULL THEN 'Unknown'
            WHEN price_per_night < 100 THEN 'Budget'
            WHEN price_per_night BETWEEN 100 AND 300 THEN 'Mid-Range'
            ELSE 'Luxury'
        END AS price_tier,
  
        -- Metrics
        accommodates,
        bedrooms,
        bathrooms,
        price_per_night,
        --- Efficiency metric: Price per possible guest
        {{ safe_divide('price_per_night', 'accommodates', decimals=2) }} AS price_per_guest,

        -- SCD2 Logic
        dbt_valid_from, 
        dbt_valid_to,
        CASE WHEN dbt_valid_to IS NULL THEN 1 ELSE 0 END AS is_current_record,

        -- Fully Traceability Audit  
        source_created_at,
        source_updated_at,
        dbt_updated_at
    FROM listings_snapshot_data
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
    silver_listings_enriched.*,
    COALESCE(
        existing_silver.silver_loaded_at,
        CAST(current_timestamp() AS timestamp_ltz)
    ) AS silver_loaded_at
FROM silver_listings_enriched
LEFT JOIN existing_silver
    ON silver_listings_enriched.dbt_scd_id = existing_silver.dbt_scd_id