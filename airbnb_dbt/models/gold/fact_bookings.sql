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
    -- Primary Key for fact table
    {{ dbt_utils.generate_surrogate_key(['b.booking_id']) }} AS booking_key,  

    -- Foreign Keys for Star Schema Joins  
 
    {{ dbt_utils.generate_surrogate_key(['b.listing_id']) }} AS listing_key, 
    {{ dbt_utils.generate_surrogate_key(['h.host_id']) }} AS host_key,

    -- Original IDs for traceability
    b.booking_id,
    l.listing_id,
    h.host_id,

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
    b.booking_revenue,    -- Potential revenue if not cancelled
    b.cancellation_fee,

    -- Derived Business Logic
    {{ calc_actual_revenue('b.booking_status', 'b.booking_revenue', 'b.cancellation_fee') }} AS actual_revenue,
    {{ calc_revenue_loss('b.booking_status', 'b.booking_revenue', 'b.cancellation_fee') }} AS revenue_loss,

    -- Boolean Flags for easier compuation
    CASE WHEN b.booking_status = 'Cancelled' THEN 1 ELSE 0 END AS cancellation_flag,
    CASE WHEN b.booking_status = 'Confirmed' THEN 1 ELSE 0 END AS confirmation_flag
        
FROM bookings AS b
LEFT JOIN listings AS l
    ON b.listing_id = l.listing_id
LEFT JOIN hosts AS h
    ON l.host_id = h.host_id
