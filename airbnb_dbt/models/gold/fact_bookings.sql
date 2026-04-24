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
    b.listing_id,
    l.host_id,

    -- Booking Metrics
    b.booking_date,
    b.booking_status,
    b.stay_start_date,
    b.stay_end_date,
    b.lead_time_days,

    -- Geographic Dimensions
    l.country,
    l.city,

    -- Property & Host Dimensions
    l.property_type,
    l.room_type,
    h.is_superhost,

    -- Revenue Metrics (Measures)
    b.nights_booked,
    b.booking_amount,
    b.cleaning_fee,
    b.service_fee,
    b.total_revenue,    -- Potential revenue if not cancelled
    b.cancellation_fee,

    -- Derived Business Logic
    {{ calc_actual_revenue('booking_status', 'total_revenue', 'cancellation_fee') }} AS actual_revenue,
    CASE
        WHEN b.booking_status = 'cancelled'
            THEN b.total_revenue - b.cancellation_fee
        ELSE 0
    END AS revenue_loss,

    -- Boolean Flags for easier compuation
    CASE WHEN b.booking_status = 'cancelled' THEN 1 ELSE 0 END AS is_cancelled,
    CASE WHEN b.booking_status = 'confirmed' THEN 1 ELSE 0 END AS is_confirmed
        
FROM bookings AS b
LEFT JOIN listings AS l
    ON b.listing_id = l.listing_id
LEFT JOIN hosts AS h
    ON l.host_id = h.host_id
