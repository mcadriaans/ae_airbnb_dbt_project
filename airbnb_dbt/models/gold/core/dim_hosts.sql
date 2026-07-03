-- gold/core/dim_hosts.sql
-- Grain: One row per unique host.
-- Description: Dimension table containing host profile attributes and aggregated portfolio metrics.

WITH hosts AS (
    SELECT *
    FROM {{ ref('silver_hosts') }}
),

listings AS (
    SELECT host_id
    FROM {{ ref('silver_listings') }}
),

host_listings_metrics AS (
    SELECT
        host_id,
        COUNT(*) AS total_listings,
        CASE
            WHEN COUNT(*) >= 5 THEN 'Professional (5+ Listings)'
            WHEN COUNT(*) BETWEEN 2 AND 4 THEN 'Multi-listing Host (2-4 Listings)'
            ELSE 'Single-listing Host'
        END AS host_portfolio_type
    FROM listings
    GROUP BY host_id
)


SELECT
    -- Unique surrogate key for Star Schema joins
    {{ dbt_utils.generate_surrogate_key(['h.host_id']) }} AS host_key,

    -- Natural key
    h.host_id,

    -- Host attributes
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
    COALESCE(m.host_portfolio_type,'No Active Listings') AS host_portfolio_type,

    -- Metadata 
   CAST(CURRENT_TIMESTAMP() AS TIMESTAMP_LTZ) AS loaded_at

FROM hosts h
LEFT JOIN host_listings_metrics m
    ON h.host_id = m.host_id




