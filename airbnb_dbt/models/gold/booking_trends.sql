SELECT
    EXTRACT(YEAR FROM booking_date) AS year,
    EXTRACT(MONTH FROM booking_date) AS month_number,
    COUNT(*) AS bookings,
    SUM(net_revenue) AS net_revenue
FROM {{ ref('fact_bookings') }}
GROUP BY year,month_number
ORDER BY net_revenue DESC
