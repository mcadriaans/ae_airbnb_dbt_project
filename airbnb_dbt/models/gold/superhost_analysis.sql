SELECT
    is_superhost,
    COUNT(*) AS bookings,
    CAST(AVG(total_revenue) AS DECIMAL(10,2)) AS avg_revenue
FROM {{ ref('fct_bookings') }}
GROUP BY is_superhost