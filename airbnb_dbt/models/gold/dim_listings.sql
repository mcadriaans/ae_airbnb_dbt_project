-- Property attributes and capacity logic  

WITH listings AS (
    SELECT *
    FROM {{ ref('silver_listings') }}
)

SELECT 
    -- Unique surrogate key for Star schema Joins
    {{ dbt_utils.generate_surrogate_key(['listing_id']) }} AS listing_key,
    -- Natural keys and identifiers
    listing_id,
    host_id,
   

    -- Descriptive attributes
    property_type,
    room_type,
    city,
    country,

    -- Physical attributes
    accommodates,
    bedrooms,
    bathrooms,
    listing_size_category,

    -- Financial attributes
    price_per_night,
    price_tier,

    -- Efficiency metric: price per guest
    ROUND(price_per_night / NULLIF(accommodates, 0), 2) AS price_per_guest,

    -- Business Logic: Categorize listings by capacity
    CASE
        WHEN accommodates >= 6 THEN 'Large Group (6+)'
        WHEN accommodates >= 3 THEN 'Small Group (3-5)'
        ELSE 'Solo/Pair'
    END AS capacity_type,
    created_at AS listing_created_at,
    updated_at AS listing_last_updated,

    -- Metadata for tracking
    CAST(current_date AS timestamp_ntz) AS loaded_at
FROM listings 
