-- gold/core/dim_hosts.sql:
-- Host profile and pre-aggregated performance metrics

WITH hosts AS (
    SELECT *
    FROM {{ ref('silver_hosts') }}
),

listings AS (
    SELECT *
    FROM {{ ref('silver_listings') }}
),

location AS (
    SELECT
        location_key,
        city,
        country
    FROM {{ ref('dim_location') }}
),

host_listings_metrics AS (
    SELECT
        host_id,
        COUNT(DISTINCT listing_id) AS total_listings,

        CASE
            WHEN COUNT(DISTINCT listing_id) >= 5
                THEN 'Professional (5+ Listings)'
            WHEN COUNT(DISTINCT listing_id) BETWEEN 2 AND 4
                THEN 'Multi-listing Host (2-4 Listings)'
            WHEN COUNT(DISTINCT listing_id) = 1
                THEN 'Single-listing Host'
            ELSE 'No Active Listings'
        END AS host_portfolio_type

    FROM listings
    GROUP BY host_id
),

host_primary_location AS (

    SELECT
        host_id,
        location_key,

        ROW_NUMBER() OVER (
            PARTITION BY host_id
            ORDER BY listing_count DESC, location_key
        ) AS rn

    FROM (

        SELECT
            l.host_id,
            loc.location_key,
            COUNT(*) AS listing_count

        FROM listings l

        LEFT JOIN location loc
            ON l.city = loc.city
           AND l.country = loc.country

        GROUP BY
            l.host_id,
            loc.location_key

    ) ranked_locations
)

SELECT

    -- Unique surrogate key for Star Schema joins
    {{ dbt_utils.generate_surrogate_key(['h.host_id']) }} AS host_key,

    -- Natural key
    h.host_id,

    -- Host attributes
    h.host_name,
    h.host_since,
    h.is_superhost,

    -- Location
    hpl.location_key,
    h.host_location,

    -- Performance metrics
    h.response_rate,
    h.avg_host_rating,
    h.host_rating_category,
    h.host_tenure_years,

    -- Aggregated listing metrics
    COALESCE(m.total_listings, 0) AS total_listings,
    COALESCE(m.host_portfolio_type,'No Active Listings') AS host_portfolio_type,

    -- Metadata tracking
    h.created_at AS host_profile_created_at,
    h.loaded_at AS data_last_refreshed_at

FROM hosts h
LEFT JOIN host_listings_metrics m
    ON h.host_id = m.host_id
LEFT JOIN host_primary_location hpl
    ON h.host_id = hpl.host_id
   AND hpl.rn = 1



