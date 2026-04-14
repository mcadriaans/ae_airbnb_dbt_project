SELECT 
    country,
    city,
    property_type,

    COUNT(*) AS total_bookings,

    SUM(
        CASE
            WHEN booking_status = 'cancelled' THEN 1 
            ELSE 0 
        END 
    ) AS cancelled_bookings,
    ROUND(
        AVG(CASE WHEN booking_status = 'cancelled' THEN lead_time_days END), 
    1) AS avg_lead_time_cancelled,

    ROUND(
        AVG(CASE WHEN booking_status != 'cancelled' THEN lead_time_days END), 
    1) AS avg_lead_time_completed,

    SUM(cancellation_fee) AS cancellation_fee_revenue,

    ROUND(
        SUM(CASE WHEN booking_status = 'cancelled' THEN 1 ELSE 0 END) * 1.0 
        / NULLIF(COUNT(*), 0),   -- NULLIF prevents division by zero errors
    2)AS cancellation_rate,

FROM {{ ref('fct_bookings')}}
GROUP BY 
    country,
    city,
    property_type

