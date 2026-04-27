-- Property attributes

WITH listings AS (
    SELECT *
    FROM {{ ref('silver_listings') }}
),

hosts AS (
    SELECT *
    FROM {{ ref('silver_hosts') }}
)

SELECT 
    l.listing_id,
    l.host_id,
    h.host_name,
    h.is_superhost,

    -- Descriptive attributes
    l.property_type,
    l.room_type,
    l.city,
    l.country,

    -- Physical attributes
    l.accommodates,
    l.bedrooms,
    l.bathrooms,

    -- Financial attributes
    l.price_per_night,

    -- Business Logic : Categorize listings by price tier
    CASE
        WHEN l.price_per_night > 300  THEN 'Luxury'
        WHEN l.price_per_night >= 150 THEN 'Premium'
        WHEN l.price_per_night >= 75  THEN 'Standard'
        ELSE 'Budget'
    END AS price_tier,

    -- Business Logic: Categorize listings by capacity
    CASE
        WHEN l.accommodates >= 6 THEN 'Large Group'
        WHEN l.accommodates >= 3 THEN 'Small Group'
        ELSE 'Solo/Pair'
    END AS capacity_type,
    l.created_at AS listing_created_at,
    l.updated_at AS listing_last_updated
FROM listings AS l
LEFT JOIN hosts AS h
    ON l.host_id = h.host_id