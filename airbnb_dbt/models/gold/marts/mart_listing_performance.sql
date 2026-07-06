-- models/gold/marts/mart_listing_performance.sql
-- Which properties perform best? Occupancy, price optimization

{{
    config(
        materialized='table',
        on_schema_change='sync_all_columns'
    )
}}

SELECT 
    l.listing_id,
    l.property_type,
    l.city,
    l.country,
    l.price_tier,
    l.listing_size_category,
    h.host_name,
    COUNT(DISTINCT b.booking_id) AS total_bookings,
    ROUND(COUNT(DISTINCT b.booking_id) / 365.0 * 100, 1) AS occupancy_rate_pct,
    CAST(AVG(l.price_per_night) AS DECIMAL(10,2)) AS avg_price_per_night,
    CAST(SUM(b.booking_revenue) AS DECIMAL(18,2)) AS total_revenue,
   {{ safe_divide('SUM(b.booking_revenue)', 'COUNT(DISTINCT b.booking_id)', decimals=2) }} AS avg_revenue_per_booking,
    {{ safe_divide('SUM(b.cancellation_flag)', 'COUNT(*)', decimals=2) }} AS cancellation_rate
FROM {{ ref('dim_listings') }} l
LEFT JOIN {{ ref('dim_hosts') }} h ON l.host_key = h.host_key
LEFT JOIN {{ ref('fact_bookings') }} b ON l.listing_key = b.listing_key
GROUP BY l.listing_id, l.property_type, l.city, l.country, l.price_tier, l.listing_size_category, h.host_name