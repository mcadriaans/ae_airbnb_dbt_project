{% macro safe_divide(numerator, denominator, decimals=2, default_value='NULL') %}
    CASE
        WHEN {{ denominator }} IS NOT NULL 
            AND {{ denominator }} != 0
            AND {{ numerator }} IS NOT NULL
        THEN ROUND({{ numerator }} / {{ denominator }}, {{ decimals }})
        ELSE {{ default_value }}
    END
{% endmacro %}