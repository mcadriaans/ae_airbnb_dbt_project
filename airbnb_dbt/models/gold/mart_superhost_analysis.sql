SELECT
    is_superhost,
    COUNT(*) AS bookings,
    CAST(AVG(net_revenue) AS DECIMAL(10,2)) AS avg_net_revenue,
    ROUND(CAST(SUM(net_revenue) AS DECIMAL(10,2)) / 1000000, 2) AS total_net_revenue_millions
FROM {{ ref('fact_bookings') }}
GROUP BY is_superhost