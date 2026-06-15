{% macro calc_booking_revenue(booking_amount, cleaning_fee, service_fee) %}
    COALESCE({{ booking_amount }}, 0)
    + COALESCE({{ cleaning_fee}}, 0)
    + COALESCE({{ service_fee}}, 0)
{% endmacro %}