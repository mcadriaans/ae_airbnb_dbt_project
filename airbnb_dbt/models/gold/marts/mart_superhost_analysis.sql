SELECT
    is_superhost,
    COUNT(*) AS bookings,
    CAST(AVG(actual_revenue) AS DECIMAL(10,2)) AS avg_revenue_per_booking,
    CAST(SUM(actual_revenue) AS DECIMAL(10,2)) AS total_revenue,
    CAST(AVG(net_revenue_loss) AS DECIMAL(10,2)) AS avg_net_revenue_loss,
    CAST(SUM(net_revenue_loss) AS DECIMAL(10,2)) AS total_net_revenue_loss
FROM {{ ref('fact_bookings') }}
GROUP BY is_superhost