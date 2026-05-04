-- Host Profile and Performance Dimension

WITH hosts AS(
    SELECT *
    FROM {{ ref('silver_hosts') }}
),

listings AS(
    SELECT *
    FROM {{ ref('silver_listings') }}
),

host_listings_counts AS(
    SELECT 
        host_id,
        COUNT(listing_id) AS total_listings,
        CASE
            WHEN COUNT(listing_id) >=  5 THEN 'Professional (5+ Listings)'
            WHEN COUNT(listing_id) BETWEEN 2 AND 4 THEN 'Multi-listing Host (2-4 Listings)'
            WHEN COUNT(listing_id) = 1 THEN 'Single-listing Host'
            ELSE 'No Active Listings'
        END AS host_portfolio_type
    FROM listings
    GROUP BY host_id
)

SELECT
    -- Unique surrogat ekey for Star schema Joins
    {{ dbt_utils.generate_surrogate_key(['h.host_id']) }} AS host_key,
    h.host_id,
    h.host_name,
    h.host_since,
    h.host_location,
    h.is_superhost,
    h.response_rate,
    h.avg_host_rating,
    h.host_rating_category,
    h.host_tenure_years,
    COALESCE(hl.total_listings, 0) AS total_listings,
    COALESCE(hl.host_portfolio_type, 'No Active Listings') AS host_portfolio_type,
    -- Metadata for tracking  
    h.updated_at AS host_profile_last_updated
FROM hosts h
LEFT JOIN host_listings_counts hl 
ON h.host_id = hl.host_id


