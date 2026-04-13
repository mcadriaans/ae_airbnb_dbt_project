SELECT
    DATE_TRUNC('month', booking_date) AS month,
    COUNT(*) AS bookings,
    SUM(total_revenue) AS revenue
FROM {{ ref('fct_bookings') }}
GROUP BY month