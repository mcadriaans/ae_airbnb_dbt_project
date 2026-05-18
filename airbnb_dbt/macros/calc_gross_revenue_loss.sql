{% macro calc_gross_revenue_loss(booking_status, booking_revenue, cancellation_fee) %}
        CASE
        WHEN booking_status = 'cancelled' 
            THEN {{ booking_revenue }} 
        ELSE 0
    END
{% endmacro %}