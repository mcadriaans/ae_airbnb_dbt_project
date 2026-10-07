-- macros/utils/safe_divide.sql
-- This macro  divides numerator / denominator only when both values are valid and the denominator is not zero. 
--Otherwise it returns a default value which is set to NULL.

{% macro safe_divide(numerator, denominator, decimals=2, default_value='NULL') %}
    CASE
        WHEN {{ denominator }} IS NOT NULL 
            AND {{ denominator }} != 0
            AND {{ numerator }} IS NOT NULL
        THEN ROUND({{ numerator }} / {{ denominator }}, {{ decimals }})
        ELSE {{ default_value }}
    END
{% endmacro %}