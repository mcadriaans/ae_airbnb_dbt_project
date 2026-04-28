SELECT 
    -- Geographic & Property Dimensions
    country,
    city,
    property_type,
    price_tier,
    -- Cancellation Analysis Metrics
    COUNT(*) AS total_bookings,
    SUM(cancellation_flag) AS cancelled_bookings,
    ROUND(SUM(cancellation_flag) * 1.0 / NULLIF(COUNT(*), 0), 2) AS cancellation_rate,
    -- Lead Time Analysis
    ROUND(
        AVG(CASE WHEN booking_status = 'cancelled' THEN lead_time_days END), 
    1) AS avg_lead_time_cancelled,

    ROUND(
        AVG(CASE WHEN booking_status != 'cancelled' THEN lead_time_days END), 
    1) AS avg_lead_time_completed,

    -- Financial Metrics
    CAST(SUM(actual_revenue) AS DECIMAL(18, 2)) AS actual_revenue,
    CAST(SUM(cancellation_fee) AS DECIMAL(18, 2)) AS cancellation_fee_revenue,
    CAST(SUM(revenue_loss) AS DECIMAL(18, 2)) AS revenue_lost,


FROM {{ ref('fact_bookings')}}
GROUP BY 
    country,
    city,
    property_type,
    price_tier
ORDER BY    
    cancellation_rate DESC,
    total_bookings DESC

