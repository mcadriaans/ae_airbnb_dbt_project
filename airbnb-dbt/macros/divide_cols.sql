{#
  Macro: divide_cols
  Purpose: Safely divide two SQL columns while preventing divide-by-zero.
  Parameters:
    numerator: column representing the numerator
    denominator: column representing the denominator
    precision: rounding precision (default = 2)
#}


{% macro divide_cols(numerator, denominator, precision=2) %}
    ROUND(
        ({{ numerator }}::NUMBER) / NULLIF({{ denominator }}::NUMBER, 0),
        {{ precision }}
    )
{% endmacro %}
