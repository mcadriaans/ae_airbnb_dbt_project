{% macro normalize_text(column_name) %}
    UPPER(TRIM({{ column_name }}))
{% endmacro %}
