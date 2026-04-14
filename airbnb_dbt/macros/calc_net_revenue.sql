{% macro calc_net_revenue(booking_status, total_revenue, cancellation_fee) %}
    CASE
        WHEN LOWER({{ booking_status }}) = 'cancelled' THEN {{ cancellation_fee }}
        ELSE {{ total_revenue }}
    END
{% endmacro %}