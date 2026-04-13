SELECT 
    host_id,
    COUNT(booking_id) AS total_bookings,
    CAST(SUM(total_revenue) AS DECIMAL(10, 2)) AS total_revenue,
    CAST(AVG(total_revenue)  AS DECIMAL(10, 2)) AS avg_booking_value,
    AVG(avg_host_rating) AS avg_rating
FROM {{ ref('fct_bookings')}}
GROUP BY host_id
ORDER BY host_id