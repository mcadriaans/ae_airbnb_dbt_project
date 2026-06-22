-- tests/generic/not_negative.sql: This test checks that the specified column in the model does not contain any negative values.

{% test not_negative(model, column_name) %}

SELECT *
FROM {{ model }}
WHERE {{ column_name }} < 0
    AND {{ column_name }} IS NOT NULL

{% endtest %}