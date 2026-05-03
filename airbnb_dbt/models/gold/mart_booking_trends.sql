-- This Mart tells us when and where the cancellations happen
SELECT
    booking_year,
    booking_month,
    country,
    COUNT(*) AS total_bookings,
    SUM(actual_revenue) AS actual_revenue,
    SUM(cancellation_flag) AS total_cancellations,
    ROUND(SUM(cancellation_flag) * 1.0 / NULLIF(COUNT(*), 0), 4) AS monthly_cancellation_rate
FROM {{ ref('fact_bookings') }}
GROUP BY booking_year, booking_month, country
ORDER BY 
    booking_year ASC,
    booking_month ASC,
    country ASC
    
