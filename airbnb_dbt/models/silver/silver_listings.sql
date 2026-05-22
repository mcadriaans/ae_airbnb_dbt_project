{{
    config(
        materialized='incremental',
        unique_key='listing_id',
        incremental_strategy='merge',
        transient=true
    )
}}

WITH source_data AS (
    SELECT 
        listing_id,
        host_id,
        property_type,
        city,
        country,
        accommodates,
        bedrooms,
        bathrooms,
        price_per_night,
        created_at,
        updated_at
    FROM {{ source('airbnb', 'bronze_listings') }}

    {% if is_incremental() %}
      -- This only runs on incremental runs, not on the first run or --full-refresh
      WHERE updated_at >= (
          SELECT DATEADD(day, -3, COALESCE(MAX(updated_at), '1900-01-01'::timestamp_ntz))
          FROM {{ this }}
      )
    {% endif %}
),

silver_listings_cleaned AS (
    SELECT 
        CAST(listing_id AS NUMERIC(38,0)) AS listing_id,
        CAST(host_id AS NUMERIC(38,0)) AS host_id,
        INITCAP(TRIM(property_type)) AS property_type,
        INITCAP(TRIM(city)) AS city,
        INITCAP(TRIM(country)) AS country,
        CAST(accommodates AS INTEGER) AS accommodates,
        CAST(bedrooms AS INTEGER) AS bedrooms,
        CAST(bathrooms AS DECIMAL(4,2)) AS bathrooms,
        CAST(price_per_night AS DECIMAL(10,2)) AS price_per_night,
        CAST(created_at AS timestamp_ntz) AS created_at,
        CAST(updated_at AS timestamp_ntz) AS updated_at
    FROM source_data
),

silver_listings_enriched AS (
    SELECT 
        *,
        -- Listing size category based on number of bedrooms
        CASE
            WHEN bedrooms = 0 THEN 'Studio'
            WHEN bedrooms = 1 THEN '1 Bedroom'
            WHEN bedrooms BETWEEN 2 AND 3 THEN 'Medium (2-3 Bedrooms)'
            ELSE 'Large (4+ Bedrooms)'
        END AS listing_size_category,
        -- Capacity type
        CASE
            WHEN accommodates >= 6 THEN 'Large Group (6+)'
            WHEN accommodates >= 3 THEN 'Small Group (3-5)'
            ELSE 'Solo/Pair'
        END AS capacity_type,

        -- Efficiency metric
          ROUND(price_per_night / NULLIF(accommodates, 0), 2) AS price_per_guest,

        -- Price tier based on price per night
        CASE
            WHEN price_per_night < 100 THEN 'Budget'
            WHEN price_per_night BETWEEN 100 AND 300 THEN 'Mid-Range'
            ELSE 'Luxury'
        END AS price_tier,
        
        -- Metadata for tracking
        CAST(current_timestamp() AS timestamp_ntz) AS loaded_at
    FROM silver_listings_cleaned
)

SELECT * FROM silver_listings_enriched