{% macro define_tier(value, low_threshold, high_threshold, low_label, mid_label, high_label) %}
    CASE
        WHEN {{ value }} <= {{ low_threshold }} THEN '{{ low_label }}'
        WHEN {{ value }} <= {{ high_threshold }} THEN '{{ mid_label }}'
        ELSE '{{ high_label }}'
    END
{% endmacro %}

