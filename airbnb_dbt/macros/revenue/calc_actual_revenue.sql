{% macro calc_actual_revenue(booking_status, booking_total, cancellation_fee) %}
    CASE
        WHEN booking_status = 'cancelled' THEN {{ cancellation_fee }}
        ELSE {{ booking_total }}
    END
{% endmacro %}