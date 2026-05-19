-- Host profile and pre-aggregated performance metrics

WITH hosts AS(
    SELECT *
    FROM {{ ref('silver_hosts') }}
),

listings AS(
    SELECT *
    FROM {{ ref('silver_listings') }}
),

host_listings_metrics AS(
    SELECT 
        host_id,
        COUNT(DISTINCT listing_id) AS total_listings,
        CASE
            WHEN COUNT(DISTINCT listing_id) >=  5 THEN 'Professional (5+ Listings)'
            WHEN COUNT(DISTINCT listing_id) BETWEEN 2 AND 4 THEN 'Multi-listing Host (2-4 Listings)'
            WHEN COUNT(DISTINCT listing_id) = 1 THEN 'Single-listing Host'
            ELSE 'No Active Listings'
        END AS host_portfolio_type
    FROM listings
    GROUP BY host_id
)

SELECT
    -- Unique surrogate key for Star schema Joins
    {{ dbt_utils.generate_surrogate_key(['h.host_id']) }} AS host_key,
    -- Natural key 
    h.host_id,

    --Profile attributes
    h.host_name,
    h.host_since,
    h.host_location,
    h.is_superhost,


    -- Performance metrics
    h.response_rate,
    h.avg_host_rating,
    h.host_rating_category,
    h.host_tenure_years,

    -- Aggregated listing metrics
    COALESCE(m.total_listings, 0) AS total_listings,
    COALESCE(m.host_portfolio_type, 'No Active Listings') AS host_portfolio_type,

    -- Metadata for tracking  
    h.created_at  AS host_profile_created_at,
    h.loaded_at AS data_last_refreshed_at
    
FROM hosts h
LEFT JOIN host_listings_metrics AS m
    ON h.host_id = m.host_id



