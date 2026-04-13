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
    SUM(cancellation_fee) AS total_cancellation_fees,
    AVG(lead_time_days) AS avg_lead_time
FROM {{ ref('fct_bookings')}}
GROUP BY 
    country,
    city,
    property_type

