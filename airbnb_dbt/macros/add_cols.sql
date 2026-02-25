{# 
  Macro: add_columns
  Purpose: Add any number of numeric SQL columns together and round to 2 decimals.
  Example Usage: {{ add_columns(['booking_amount', 'cleaning_fee', 'service_fee']) }}
#}

{% macro add_columns(col_list) %}
    round(
        (
            {%- for col in col_list -%}
                {{ col }}{{ " + " if not loop.last else "" }}
            {%- endfor -%}
        ),
        2
    )
{% endmacro %}

