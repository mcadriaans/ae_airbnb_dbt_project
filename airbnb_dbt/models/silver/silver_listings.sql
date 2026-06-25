-- models/silver/silver_listings.sql

-- SCD1: One row per listing (just latest state)
-- When listing data changes: OVERWRITE old row, don't track history
-- Input: stg_airbnb__listings
-- Output: Enriched listing dimensions with price tiers and capacity metrics


{{
    config(
        materialized='incremental',
        unique_key='listing_id',
        incremental_strategy='delete+insert',
        on_schema_change='sync_all_columns'
    )
}}

WITH silver_listings_enriched AS (
    SELECT 
        -- Keys
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


        -- Metadata for tracking
        created_at,
        updated_at,
        CAST(current_timestamp() AS timestamp_ntz) AS loaded_at
    FROM {{ ref('stg_airbnb__listings') }}

    {% if is_incremental() %}
      -- Only grab records updated since the last run  
      -- 7-day lookback handles late arrivals in source data
      WHERE updated_at >= (
          SELECT DATEADD(day, -7, COALESCE(MAX(updated_at), '1900-01-01'::timestamp_ntz))
          FROM {{ this }}
      )
    {% endif %}
)

SELECT * FROM silver_listings_enriched