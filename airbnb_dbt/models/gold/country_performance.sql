SELECT 
    country,
    COUNT(booking_id) AS total_bookings,
    CAST(SUM(net_revenue) AS DECIMAL(10, 2)) AS net_revenue,
    CAST(AVG(net_revenue)  AS DECIMAL(10, 2)) AS avg_booking_value,
    ROUND(AVG(avg_host_rating), 0) AS avg_rating
FROM {{ ref('fct_bookings')}}
GROUP BY country
ORDER BY net_revenue DESC