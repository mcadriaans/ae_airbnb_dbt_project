WITH bookings AS (
    SELECT *
    FROM {{ ref('silver_bookings') }}
),
hosts AS (
    SELECT *
    FROM {{ ref('silver_hosts') }}
),
listings AS (
    SELECT *
    FROM {{ ref('silver_listings') }}
)


SELECT 
    -- Keys
    b.booking_id,

    {{ dbt_utils.generate_surrogate_key(['b.listing_id']) }} AS listing_key,  -- Surrogate key for Star schema Joins
    {{ dbt_utils.generate_surrogate_key(['h.host_id']) }} AS host_key,  -- Surrogate key for Star schema Joins


    b.listing_id,
    l.host_id,

    -- Booking Details & Status
    b.booking_date,
    EXTRACT(year FROM b.booking_date) AS booking_year,
    EXTRACT(month FROM b.booking_date) AS booking_month,
    b.lead_time_days,
    b.stay_start_date,
    b.stay_end_date,
    b.booking_status,

    -- Geographic Dimensions
    l.country,
    l.city,

    -- Property & Host Dimensions
    l.property_type,
    l.room_type,
    l.listing_size_category,
    l.price_tier,
    h.is_superhost,
    h.host_rating_category,

    -- Revenue Metrics (Measures)
    b.nights_booked,
    b.booking_amount,
    b.cleaning_fee,
    b.service_fee,
    b.expected_revenue,    -- Potential revenue if not cancelled
    b.cancellation_fee,

    -- Derived Business Logic
    {{ calc_actual_revenue('b.booking_status', 'b.expected_revenue', 'b.cancellation_fee') }} AS actual_revenue,
    {{ calc_revenue_loss('b.booking_status', 'b.expected_revenue', 'b.cancellation_fee') }} AS revenue_loss,

    -- Boolean Flags for easier compuation
    CASE WHEN b.booking_status = 'cancelled' THEN 1 ELSE 0 END AS cancellation_flag,
    CASE WHEN b.booking_status = 'confirmed' THEN 1 ELSE 0 END AS confirmation_flag
        
FROM bookings AS b
LEFT JOIN listings AS l
    ON b.listing_id = l.listing_id
LEFT JOIN hosts AS h
    ON l.host_id = h.host_id
