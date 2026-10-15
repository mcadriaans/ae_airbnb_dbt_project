-- models/gold/core/fact_bookings.sql

-- Layer: Gold Core (Conformed Enterprise Star Schema)
-- Grain: One row per booking version mutation (SCD2).
-- Description: This is the main booking table for your business reports. It saves the 
--              entire life story of every booking, tracking status updates over time. 
--              It plugs directly into your conformed date, host, and listing tables 
--              so you can easily build dashboard charts for sales and cancellations.

--                dim_dates
--                   |
--                   |
--                   |
--   dim_hosts --- fact_bookings --- dim_listings

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
    -- Primary Surrogate Key for Star Schema Joins 
    {{ dbt_utils.generate_surrogate_key(['b.booking_id', 'b.dbt_scd_id']) }} AS booking_key, 

    -- Star schema foreign keys for joining to dimension tables
    l.listing_key, 
    h.host_key,

    -- Conformed Date Dimension Key for joining to dim_dates
    d_book.date_key AS booking_date_key,
    d_start.date_key AS stay_start_date_key,
    d_end.date_key AS stay_end_date_key,

    --  Natural keys for traceability   
    b.booking_id,
    b.listing_id,
    l.host_id,
    b.dbt_scd_id AS booking_version_id,
    b.is_current_record,

    -- Temporal Attributes
    b.booking_date,
    d_book.year_number AS booking_year,
    d_book.month_name AS booking_month,
    b.stay_start_date,
    b.stay_end_date,
    b.lead_time_days,

   -- Denormalized filtering attributes from listings and hosts
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

    -- Derived Business Logic Enrichment
    {{ calc_actual_revenue('b.booking_status', 'b.booking_revenue', 'b.cancellation_fee') }} AS actual_revenue,
    {{ calc_gross_revenue_loss('b.booking_status', 'b.booking_revenue') }} AS gross_revenue_loss,
    {{ calc_net_revenue_loss('b.booking_status', 'b.booking_revenue', 'b.cancellation_fee') }} AS net_revenue_loss,

    -- Boolean Flags for easier compuation
    CASE WHEN LOWER(b.booking_status) = 'cancelled' THEN 1 ELSE 0 END AS cancellation_flag,
    CASE WHEN LOWER(b.booking_status) = 'confirmed' THEN 1 ELSE 0 END AS confirmation_flag,

    -- Metadata for auditing
    CAST(CURRENT_TIMESTAMP() AS TIMESTAMP_LTZ) AS core_loaded_at
        
FROM bookings AS b
LEFT JOIN listings AS l
    ON b.listing_id = l.listing_id
LEFT JOIN hosts AS h
    ON l.host_id = h.host_id
LEFT JOIN dates AS d_book
    ON b.booking_date = d_book.date_day
LEFT JOIN dates AS d_start
    ON b.stay_start_date = d_start.date_day
LEFT JOIN dates AS d_end
    ON b.stay_end_date = d_end.date_day