{# 
  Macro: add_columns
  Purpose: Add any number of numeric SQL columns together .
  Example Usage: {{ add_columns(['booking_amount', 'cleaning_fee', 'service_fee']) }}
#}

{% macro add_columns(col_list) %}
   
    {%- for col in col_list -%}
            {{ col }}{{ " + " if not loop.last else "" }}
    {%- endfor -%}
  
    
{% endmacro %}

