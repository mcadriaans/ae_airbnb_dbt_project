{{
    config(
        on_schema_change='sync_all_columns'
    )
}}


SELECT 
    country,
    COUNT(booking_id) AS total_bookings,
    CAST(SUM(net_revenue_loss) AS DECIMAL(10, 2)) AS net_revenue_loss,
    CAST(AVG(net_revenue_loss)  AS DECIMAL(10, 2)) AS avg_net_revenue_loss,
    ROUND(AVG(avg_host_rating), 2) AS avg_rating
FROM {{ ref('fact_bookings')}}
GROUP BY country

