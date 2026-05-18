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
)


SELECT 
    -- Surrogate keys for Star Schema Joins
    {{ dbt_utils.generate_surrogate_key(['b.booking_id']) }} AS booking_key, 
    l.listing_key, 
    h.host_key,

    --  Natural keys for traceability   
    b.booking_id,
    b.listing_id,
    h.host_id,

    -- Dates and Time Dimensions
    b.booking_date,
    EXTRACT(year FROM b.booking_date) AS booking_year,
    EXTRACT(month FROM b.booking_date) AS booking_month,
    b.stay_start_date,
    b.stay_end_date,
    b.lead_time_days,

   -- Dimensional Attributes (For Dashboard Filtering and Segmentation)
    b.booking_status,
    l.country,
    l.city,
    l.property_type,
    l.listing_size_category,
    l.price_tier,
    h.is_superhost,
    h.host_rating_category,

    -- Measures
    h.avg_host_rating,
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
    CASE WHEN LOWER(b.booking_status) = 'confirmed' THEN 1 ELSE 0 END AS confirmation_flag
        
FROM bookings AS b
LEFT JOIN listings AS l
    ON b.listing_id = l.listing_id
LEFT JOIN hosts AS h
    ON l.host_id = h.host_id
