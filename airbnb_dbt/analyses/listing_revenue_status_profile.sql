-- Jinja variable assignment and for loop

-- Calculate revenue per listing by booking status and total revenue,
-- ordered by cancelled_revenue in descending order.

{% set booking_statuses = ["confirmed", "cancelled"] %}

SELECT
    listing_id,
    {% for booking_status in booking_statuses %}
        SUM(CASE WHEN booking_status = '{{ booking_status }}' THEN booking_amount END)
            AS {{ booking_status }}_revenue,
    {% endfor %}
    SUM(booking_amount) AS total_revenue
FROM {{ ref('silver_bookings') }}
GROUP BY 1
ORDER BY cancelled_revenue DESC;
