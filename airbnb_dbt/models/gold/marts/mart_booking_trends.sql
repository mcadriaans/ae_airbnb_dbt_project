-- This Mart tells us when and where the cancellations happen

{{
    config(
        on_schema_change='sync_all_columns'
    )
}}

WITH bookings AS (
    SELECT *
    FROM {{ ref('fact_bookings') }}
),
aggregated AS (
    SELECT
        booking_year,
        booking_month,
        country,
        COUNT(*) AS total_bookings,
        SUM(actual_revenue) AS actual_revenue,
        SUM(cancellation_flag) AS total_cancellations,

        -- Business Logic: 
        --- Calculate cancellation rate as a percentage of total bookings
        ROUND(
            SUM(cancellation_flag) * 1.0 / NULLIF(COUNT(*), 0), 4) AS monthly_cancellation_rate,

        --- Percentage of revenue contributed by country
        ROUND(
            SUM(actual_revenue) / SUM(SUM(actual_revenue)) OVER (PARTITION BY booking_year, booking_month), 
            4
        ) AS revenue_share

    FROM {{ ref('fact_bookings') }}
    GROUP BY booking_year, booking_month, country
)

SELECT * FROM aggregated



