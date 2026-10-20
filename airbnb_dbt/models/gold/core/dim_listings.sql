-- models/gold/core/dim_listings.sql:

-- Grain: One row per unique Airbnb listing (property).
-- SCD: Type 1 (current state only) with SCD2 history preserved in silver layer.
-- Description: Dimension table for properties. Links to dim_hosts and dim_location.


WITH listings AS (
    SELECT 
        listing_id,
        host_id,
        property_type,
        city,
        country,
        accommodates,
        bedrooms,   
        bathrooms,
        listing_size_category,
        capacity_type,  
        price_per_night,
        price_per_guest,
        price_tier
    FROM {{ ref('silver_listings') }}
    -- Filter out historical versions of listings, keeping only the most recent version for each listing_id
    WHERE is_current_record = 1
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
   

    -- Foreign Keys (References to other dimension tables)
    h.host_key,
    {{ dbt_utils.generate_surrogate_key(['l.city', 'l.country']) }} AS location_key,

    -- Natural keys 
    l.listing_id,
    l.host_id,
    
    -- Property Attributes
    l.property_type,
    l.city,
    l.country,
    l.accommodates,
    l.bedrooms,
    l.bathrooms,
    l.listing_size_category,
    l.capacity_type,

    -- Financial Attributes
    l.price_per_night,
    l.price_per_guest,
    l.price_tier,

    -- Metadata 
    CAST(CURRENT_TIMESTAMP() AS timestamp_ltz) AS core_loaded_at
FROM listings AS l
LEFT JOIN hosts AS h
    ON l.host_id = h.host_id
LEFT JOIN location AS loc
    ON l.city = loc.city 
        AND l.country = loc.country
