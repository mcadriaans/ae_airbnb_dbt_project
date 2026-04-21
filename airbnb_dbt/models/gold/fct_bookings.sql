WITH cancellation_fee_allocated AS(
    SELECT 
        *,
        CAST(
            CASE 
                WHEN booking_status='cancelled' AND lead_time_days < 2 THEN booking_amount
                WHEN booking_status='cancelled' AND lead_time_days BETWEEN 2 AND 4 THEN (booking_amount * 0.75)
                WHEN booking_status='cancelled' AND lead_time_days BETWEEN 5 AND 9 THEN (booking_amount * 0.25)
                WHEN booking_status='cancelled' AND lead_time_days >= 10 THEN 0
                ELSE 0
            END
        AS DECIMAL(10,2)) AS cancellation_fee
    FROM {{ ref('silver_bookings')}}
),

fact_bookings AS (
    SELECT 
        f.booking_id,
        f.booking_date,
        f.nights_booked,
        f.total_revenue,
        f.booking_status,
        f.lead_time_days,
        f.cancellation_fee,
        {{ calc_net_revenue('booking_status', 'total_revenue', 'cancellation_fee') }} AS net_revenue,
        CASE
            WHEN booking_status = 'cancelled'
                THEN total_revenue - cancellation_fee
            ELSE 0
        END AS revenue_loss,

        l.city,
        l.country,
        l.property_type,

        h.host_id,
        h.is_superhost,
        h.avg_host_rating
    FROM cancellation_fee_allocated AS f
    LEFT JOIN {{ ref('silver_listings') }} AS l
        ON f.listing_id = l.listing_id
    LEFT JOIN {{ ref('silver_hosts') }} AS h
        ON l.host_id = h.host_id
)

SELECT * FROM fact_bookings






