-- macros/revenue/calc_net_revenue_loss.sql
-- This macro calculates the net revenue loss, if a booking is cancelled, the net revenue loss is the booking revenue minus the cancellation fee.
-- If the booking is not cancelled, the net revenue loss is 0.

{% macro calc_net_revenue_loss(booking_status, booking_revenue, cancellation_fee) %}
        CASE
        WHEN booking_status = 'cancelled' 
            THEN {{ booking_revenue }} - {{ cancellation_fee }}
        ELSE 0
    END
{% endmacro %}