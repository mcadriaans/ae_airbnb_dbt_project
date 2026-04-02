{#
  Macro: normalize_name
  Purpose: Clean and standardize host names for consistent analytics use.
           Applies trimming, whitespace normalization, and title casing.
  Example: {{ normalize_name('host_name') }}
#}

{% macro normalize_name(column_name) %}
    INITCAP(
        REGEXP_REPLACE(
            TRIM({{ column_name }}),
            '\\s+',
            ' '
        )
    )
{% endmacro %}
