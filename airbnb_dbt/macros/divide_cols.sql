{#
  Macro: divide_cols
  Purpose: Divide one SQL column by another and round to 2 decimals.
  Usage: {{ divide_cols('booking_amount', 'nights_booked') }}
#}

{% macro divide_cols(numerator, denominator) %}
    round(
        {{ numerator }} / nullif({{ denominator }}, 0),
        2
    )
{% endmacro %}
