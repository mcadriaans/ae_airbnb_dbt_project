-- tests/generic/not_in_future.sql:
-- The test fails rows where column_name is greater than the current timestamp, which indicates a future date that should not exist in the data.

{% test not_in_future(model, column_name) %}

SELECT *
FROM {{ model }}
-- Compare to the actual real-world clock (with a 1-minute buffer)
WHERE {{ column_name }} > {{ dbt.dateadd('minute', 1, dbt.current_timestamp()) }}

{% endtest %}