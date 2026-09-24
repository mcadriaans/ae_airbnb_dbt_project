-- macros/revenue/calc_gross_revenue_loss.sql
-- This macro calculates the gross revenue loss, if a booking is cancelled, the entire booking revenue is considered lost. 
-- If the booking is not cancelled, the gross revenue loss is 0.


{% macro calc_gross_revenue_loss(booking_status, booking_revenue) %}
        CASE
        WHEN booking_status = 'cancelled' 
            THEN {{ booking_revenue }} 
        ELSE 0
    END
{% endmacro %}