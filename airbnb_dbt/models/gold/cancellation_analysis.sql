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
    CAST(SUM(net_revenue) AS DECIMAL(10, 2)) AS actual_revenue,
    CAST(SUM(cancellation_fee) AS DECIMAL(10, 2)) AS cancellations_revenue,
    CAST(SUM(revenue_loss) AS DECIMAL(10, 2)) AS revenue_losses,
    ROUND(
        SUM(CASE WHEN booking_status = 'cancelled' THEN 1 ELSE 0 END) * 1.0 
        / NULLIF(COUNT(*), 0),   -- NULLIF prevents division by zero errors
    2)AS cancellation_rate,

FROM {{ ref('fct_bookings')}}
GROUP BY 
    country,
    city,
    property_type

