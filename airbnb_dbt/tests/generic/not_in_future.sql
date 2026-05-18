-- The test fails rows where column_name is greater than the current timestamp, which indicates a future date that should not exist in the data.

{% test not_in_future(model, column_name) %}

SELECT *
FROM {{ model }}
WHERE {{ column_name }} > {{ dbt.current_timestamp() }}

{% endtest %}