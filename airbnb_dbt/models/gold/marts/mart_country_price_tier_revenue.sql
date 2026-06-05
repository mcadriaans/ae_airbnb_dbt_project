{{
    config(
        on_schema_change='sync_all_columns'
    )
}}



WITH revenue_summary AS (
        SELECT 
            country,
            price_tier,
            SUM(booking_revenue) AS potential_revenue,
            SUM(actual_revenue) AS actual_revenue,
            SUM(net_revenue_loss) AS net_revenue_lost,
            SUM(cancellation_fee) AS cancellation_revenue,
            SUM(gross_revenue_loss) AS gross_revenue_lost
        FROM {{ ref('fact_bookings') }}
        GROUP BY country, price_tier
        ORDER BY actual_revenue DESC
)

SELECT 
    country,
    price_tier,
    'Potential Revenue' AS revenue_type,
    potential_revenue AS revenue_amount,
    1 as sort_order
FROM revenue_summary
UNION ALL
SELECT 
    country,
    price_tier,
    'Revenue Lost(Cancellations)' AS revenue_type,
    (gross_revenue_lost) * -1 AS revenue_amount,
    2 as sort_order
FROM revenue_summary
UNION ALL
SELECT 
    country,
    price_tier,
    'Cancellation Revenue' AS revenue_type,
    cancellation_revenue AS revenue_amount,
    3 as sort_order
FROM revenue_summary




