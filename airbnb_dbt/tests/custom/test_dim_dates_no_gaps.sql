-- tests/custom/test_dim_dates_no_gaps.sql
 
-- This test checks for gaps in the dim_dates table by ensuring that the difference between consecutive dates is always 1 day.
-- If there are any gaps, the test will fail.

WITH dates AS (
    SELECT 
        date_day,
        LEAD(date_day) OVER (ORDER BY date_day) AS next_date
    FROM {{ ref('dim_dates') }}
)
SELECT 
    date_day,
    next_date,
    DATEDIFF(day, date_day, next_date) AS day_difference
FROM dates 
WHERE next_date IS NOT NULL 
    AND DATEDIFF(day, date_day, next_date) <> 1