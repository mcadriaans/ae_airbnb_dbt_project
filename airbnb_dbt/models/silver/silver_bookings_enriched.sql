{{ config(materialized='view') }}

WITH base AS (
    SELECT * FROM {{ ref('silver_bookings_deduped') }}
),

enriched AS (
    SELECT *,
        CAST({{ add_columns(['cleaning_fee', 'service_fee']) }} as number(38,2)) as total_fees,
        CAST({{ add_columns(['booking_amount', 'total_fees']) }} as number(38,2)) as total_amount,
        CAST({{ divide_cols('booking_amount', 'nights_booked') }}as number(38,2)) as price_per_night,
        booking_date + nights_booked AS stay_end_date,
        -- status flags
        CASE WHEN booking_status = 'cancelled' then true else false end as is_cancelled,
        CASE WHEN booking_status = 'completed' then true else false end as is_completed
    FROM base
),

thresholds AS (
    SELECT 
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY price_per_night) AS price_p25,
        MEDIAN(price_per_night) AS price_median,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY price_per_night) AS price_p75
    FROM enriched
)

SELECT 
    e.*,
    --price outlier flag
    (
    e.price_per_night > t.price_p75 * 3
    OR e.price_per_night < t.price_p25
    ) AS is_price_outlier
FROM enriched AS e
CROSS JOIN thresholds AS t

