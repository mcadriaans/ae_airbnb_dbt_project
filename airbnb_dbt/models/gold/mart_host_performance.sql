SELECT 
    host_id,
    COUNT(booking_id) AS total_bookings,
    CAST(SUM(actual_revenue) AS DECIMAL(10, 2)) AS total_revenue,
    CAST(AVG(actual_revenue)  AS DECIMAL(10, 2)) AS avg_booking_value,
    AVG(avg_host_rating) AS avg_rating
FROM {{ ref('fact_bookings')}}
GROUP BY host_id
ORDER BY host_id