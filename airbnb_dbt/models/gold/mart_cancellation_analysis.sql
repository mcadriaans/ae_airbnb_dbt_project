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
        AVG(CASE WHEN booking_status = 'Cancelled' THEN lead_time_days END), 
    1) AS avg_lead_time_cancelled,

    ROUND(
        AVG(CASE WHEN booking_status = 'Confirmed' THEN lead_time_days END), 
    1) AS avg_lead_time_confirmed,

    -- Financial Metrics
    CAST(SUM(booking_revenue) AS DECIMAL(18, 2)) AS potential_revenue,
    CAST(SUM(actual_revenue) AS DECIMAL(18, 2)) AS actual_revenue,
    CAST(SUM(gross_revenue_loss) AS DECIMAL(18, 2)) AS gross_revenue_loss,
    CAST(SUM(cancellation_fee) AS DECIMAL(18, 2)) AS cancellations_revenue,
    CAST(SUM(net_revenue_loss) AS DECIMAL(18, 2)) AS net_revenue_loss
FROM {{ ref('fact_bookings')}}
GROUP BY 
    country,
    city,
    property_type,
    price_tier
ORDER BY actual_revenue DESC
