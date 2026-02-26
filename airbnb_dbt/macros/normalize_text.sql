{% macro normalize_text(column_name) %} 
    LOWER( 
        REGEXP_REPLACE( 
            TRIM({{ column_name }}), 
            '\\s+',
             ' ' 
            ) 
        ) 
{% endmacro %}