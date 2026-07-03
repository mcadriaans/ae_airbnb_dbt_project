-- models/gold/marts/mart_host_performance.sql
-- Which hosts are most valuable? Revenue, ratings, growth
{{
    config(
        materialized='table',
        on_schema_change='sync_all_columns'
    )
}}

SELECT 
    h.host_id,
    h.host_name,
    h.is_superhost,
    h.host_rating_category,
    h.avg_host_rating,
    h.response_rate,
    h.host_tenure_years,
    COUNT(DISTINCT l.listing_id) AS total_listings,
    COUNT(DISTINCT b.booking_id) AS total_bookings,
    ROUND(AVG(b.nights_booked), 1) AS avg_nights_per_booking,
    CAST(SUM(b.booking_revenue) AS DECIMAL(18,2)) AS total_revenue,
    CAST(SUM(b.actual_revenue) AS DECIMAL(18,2)) AS actual_revenue,
    ROUND(SUM(b.actual_revenue) / NULLIF(COUNT(DISTINCT l.listing_id), 0), 2) AS revenue_per_listing,
    ROUND(SUM(b.cancellation_flag) / NULLIF(COUNT(*), 0), 2) AS cancellation_rate
FROM {{ ref('dim_hosts') }} h
LEFT JOIN {{ ref('fact_bookings') }} b ON h.host_id = b.host_id
LEFT JOIN {{ ref('dim_listings') }} l ON b.listing_id = l.listing_id
GROUP BY h.host_id, h.host_name, h.is_superhost, h.host_rating_category, h.avg_host_rating, h.response_rate, h.host_tenure_years