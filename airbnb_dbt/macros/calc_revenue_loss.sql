    {% macro calc_revenue_loss(booking_status, booking_revenue, cancellation_fee) %}
        CASE
        WHEN LOWER({{ booking_status }}) = 'cancelled' 
            THEN {{ booking_revenue }} - {{ cancellation_fee }}
        ELSE 0
    END
{% endmacro %}