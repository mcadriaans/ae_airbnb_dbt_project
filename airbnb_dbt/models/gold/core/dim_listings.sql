-- Property attributes and capacity logic  

WITH listings AS (
    SELECT *
    FROM {{ ref('silver_listings') }}
),

hosts AS (
    SELECT 
        host_key,
        host_id
    FROM {{ ref('dim_hosts') }}
),
location AS (
    SELECT 
        location_key,
        city,
        country
    FROM {{ ref('dim_location') }}
)

SELECT 
    -- Unique surrogate key for Star schema Joins
    {{ dbt_utils.generate_surrogate_key(['l.listing_id']) }} AS listing_key,

    -- Foreign Keys (links to other dimensions)
    h.host_key,
    loc.location_key,

    -- Natural keys and identifiers
    l.listing_id,
    l.host_id,
    
    -- Attributes
    l.property_type,
    l.city,
    l.country,
    l.accommodates,
    l.bedrooms,
    l.bathrooms,
    l.listing_size_category,
    l.capacity_type,
    l.price_per_night,
    l.price_per_guest,
    l.price_tier,

    -- Metadata for tracking
    CAST(current_date AS timestamp_ntz) AS loaded_at
FROM listings AS l
LEFT JOIN hosts AS h
    ON l.host_id = h.host_id
LEFT JOIN location AS loc
    ON l.city = loc.city 
        AND l.country = loc.country
