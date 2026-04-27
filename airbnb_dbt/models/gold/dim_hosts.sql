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
            WHEN COUNT(listing_id) >  1 THEN 'Multi-listing Host'
            ELSE 'Single-listing Host'
        END AS host_portfolio_type
    FROM listings
    GROUP BY host_id
)

SELECT
    h.host_id,
    h.host_name,
    h.host_since,
    h.is_superhost,
    h.response_rate,
    h.avg_host_rating,
    COALESCE(hl.total_listings, 0) AS total_listings,
    COALESCE(hl.host_portfolio_type, 'No Active Listings') AS host_portfolio_type,
    CASE
        WHEN h.avg_host_rating >= 4.8 THEN 'Premier '
        WHEN h.avg_host_rating >= 4.0 THEN 'Moderately Rated'
        ELSE 'Low Rated'
    END AS host_rating_category,
    h.updated_at AS host_profile_last_updated
FROM hosts h
LEFT JOIN host_listings_counts hl 
ON h.host_id = hl.host_id


