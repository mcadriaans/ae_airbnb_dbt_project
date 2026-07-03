--gold/core/fact_bookings.sql
-- Grain: One row per booking version (SCD2).
-- Description: Central fact table for Airbnb bookings. Contains all financial measures, 
--              denormalized attributes for filtering, and surrogate keys for star schema joins.

{{ config(materialized='table') }}

WITH bookings AS (
    SELECT *
    FROM {{ ref('silver_bookings') }}
),
hosts AS (
    SELECT *
    FROM {{ ref('dim_hosts') }}
),
listings AS (
    SELECT *
    FROM {{ ref('dim_listings') }}
),
dates AS (
    SELECT *
    FROM {{ ref('dim_dates') }}
)



SELECT 
    -- Surrogate keys for Star Schema Joins
    {{ dbt_utils.generate_surrogate_key(['b.booking_id']) }} AS booking_key, 
    l.listing_key, 
    h.host_key,
    d.date_key AS booking_date_key,

    --  Natural keys for traceability   
    b.booking_id,
    b.listing_id,
    h.host_id,
    b.dbt_scd_id AS booking_version_id,

    -- Temporal Attributes 
    b.booking_date,
    d.year_number AS booking_year,
    d.month_name AS booking_month,
    b.stay_start_date,
    b.stay_end_date,
    b.lead_time_days,

   -- Denormalized Dimensions (For Dashboard Filtering and Segmentation)
    b.booking_status,
    l.property_type,
    l.city,
    l.country,
    l.listing_size_category,
    l.price_tier,
    h.is_superhost,
    h.host_rating_category,

    -- Measures
    b.nights_booked,
    b.booking_amount,
    b.cleaning_fee,
    b.service_fee,
    b.booking_revenue,    -- Potential revenue if not cancelled
    b.cancellation_fee,

       

    -- Derived Business Logic
    {{ calc_actual_revenue('b.booking_status', 'b.booking_revenue', 'b.cancellation_fee') }} AS actual_revenue,
    {{ calc_gross_revenue_loss('b.booking_status', 'b.booking_revenue', 'b.cancellation_fee') }} AS gross_revenue_loss,
    {{ calc_net_revenue_loss('b.booking_status', 'b.booking_revenue', 'b.cancellation_fee') }} AS net_revenue_loss,

    -- Boolean Flags for easier compuation
    CASE WHEN LOWER(b.booking_status) = 'cancelled' THEN 1 ELSE 0 END AS cancellation_flag,
    CASE WHEN LOWER(b.booking_status) = 'confirmed' THEN 1 ELSE 0 END AS confirmation_flag,

    CAST(CURRENT_TIMESTAMP() AS TIMESTAMP_LTZ) AS loaded_at
        
FROM bookings AS b
LEFT JOIN listings AS l
    ON b.listing_id = l.listing_id
LEFT JOIN hosts AS h
    ON l.host_id = h.host_id
LEFT JOIN dates AS d
    ON b.booking_date = d.date_day