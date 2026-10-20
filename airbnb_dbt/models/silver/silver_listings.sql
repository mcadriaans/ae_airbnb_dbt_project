-- models/silver/silver_listings.sql : Enriched listing dimensions with SCD2 history

-- Input: listings_snapshot (SCD2 tracking listing changes)
-- Output: Enriched listing dimensions, all versions preserved
--> 'merge': implies versioning

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
    {% if is_incremental() %}
        -- Only grab snapshot rows that are NEW to silver
        WHERE dbt_updated_at >= (
          SELECT COALESCE(MAX(dbt_updated_at), '1900-01-01'::timestamp_ltz)
          FROM {{ this }}
      )
   
    {% endif %}
),
silver_listings_enriched AS (
    SELECT
        -- Identifiers
        dbt_scd_id,   -- Primary Key: Identifies this specific version of the host record
        listing_id,
        host_id,

        -- Dimensions
        property_type,
        city,
        country,
        --- Listing size category based on number of bedrooms
        CASE
            WHEN bedrooms = 0 THEN 'Studio'
            WHEN bedrooms = 1 THEN '1 Bedroom'
            WHEN bedrooms BETWEEN 2 AND 3 THEN 'Medium (2-3 Bedrooms)'
            ELSE 'Large (4+ Bedrooms)'
        END AS listing_size_category,
        --- Capacity type classification
        CASE
            WHEN accommodates >= 6 THEN 'Large Group (6+)'
            WHEN accommodates >= 3 THEN 'Small Group (3-5)'
            ELSE 'Solo/Pair'
        END AS capacity_type,
        --- Price tier categorization based on price per night
        CASE
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
        dbt_updated_at,
        CAST(current_timestamp() AS timestamp_ltz) AS  silver_loaded_at  -- Timestamp when this record was loaded into the silver layer
    FROM listings_snapshot_data
)

SELECT * FROM silver_listings_enriched