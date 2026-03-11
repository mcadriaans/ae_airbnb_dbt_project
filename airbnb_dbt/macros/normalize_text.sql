{#
  Macro: normalize_text
  Purpose: Clean and standardize free‑text fields for consistent analytics use.
           Applies trimming, collapses multiple whitespace characters into a single space,
           and converts the entire string to lowercase for uniform comparison.
  Example: {{ normalize_text('booking_status') }}
#}

{% macro normalize_text(column_name) %}
    LOWER(
        REGEXP_REPLACE(
            TRIM({{ column_name }}),
            '\\s+',
            ' '
        )
    )
{% endmacro %}
