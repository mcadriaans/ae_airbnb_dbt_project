-- tests/generic/not_in_future.sql:
-- The test fails rows where column_name is greater than the current timestamp, which indicates a future date that should not exist in the data.

{% test not_in_future(model, column_name) %}

SELECT *
FROM {{ model }}
-- Compare to the actual real-world clock (with a 1-minute buffer)
-- Cast the current time (plus the buffer) to match the Snowflake data type
WHERE {{ column_name }} > CAST({{ dbt.dateadd('minute', 1, dbt.current_timestamp()) }} AS TIMESTAMP_NTZ)

{% endtest %}