-- macros/revenue/calc_booking_revenue.sql
-- This macro calculates the total booking revenue by summing the booking amount, cleaning fee, and service fee. 
-- It uses COALESCE to handle any NULL values in the inputs.

{% macro calc_booking_revenue(booking_amount, cleaning_fee, service_fee) %}
    COALESCE({{ booking_amount }}, 0)
    + COALESCE({{ cleaning_fee}}, 0)
    + COALESCE({{ service_fee}}, 0)
{% endmacro %}