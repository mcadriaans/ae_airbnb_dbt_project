-- macros/revenue/calc_actual_revenue.sql
-- This macro calculates the actual revenue based on the booking status, total booking amount, and cancellation fee.

{% macro calc_actual_revenue(booking_status, booking_total, cancellation_fee) %}
    CASE
        WHEN booking_status = 'cancelled' THEN {{ cancellation_fee }}
        ELSE {{ booking_total }}
    END
{% endmacro %}