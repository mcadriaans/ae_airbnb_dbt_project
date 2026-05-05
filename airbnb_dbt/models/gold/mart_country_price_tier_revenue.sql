WITH country_tier_revenue AS (
        SELECT 
            country,
            price_tier,
            SUM(actual_revenue) AS actual_revenue,
            SUM(expected_revenue) AS potential_revenue,
            SUM(revenue_loss) AS revenue_lost,
            SUM(cancellation_fee) AS cancellation_revenue
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
FROM country_tier_revenue
UNION ALL
SELECT 
    country,
    price_tier,
    'Revenue Lost(Cancellations)' AS revenue_type,
    revenue_lost AS revenue_amount,
    2 as sort_order
FROM country_tier_revenue
UNION ALL
SELECT 
    country,
    price_tier,
    'Revenue Salvaged (Recovered)' AS revenue_type,
    cancellation_revenue AS revenue_amount,
    3 as sort_order
FROM country_tier_revenue
UNION ALL   
SELECT 
    country,
    price_tier,
    'Actual Revenue' AS revenue_type,
    actual_revenue AS revenue_amount,
    4 as sort_order
FROM country_tier_revenue




