
-- models/gold/core/dim_dates.sql:

-- This model creates a date dimension table for use in the gold layer of the Airbnb data warehouse.

-- 1. CONFIG SECTION
{% set date_query %}
SELECT 
    -- Use your airbnb_launch_date variable for the start!
    '{{ var("airbnb_launch_date") }}' AS min_date,
    -- Go 2 years into the future based on the latest booking
    DATEADD(year, 2, MAX(booking_date))::string AS max_date
FROM {{ ref('silver_bookings') }}
{% endset %}

{% if execute %}
    {% set results = run_query(date_query) %}
    {% set start_date = results.columns[0][0] | string %}
    {% set end_date = results.columns[1][0] | string %}
{% else %}
    -- Fallbacks for compilation phase
    {% set start_date = '2008-08-01' %}
    {% set end_date = '2030-12-31' %}
{% endif %}


-- 2. SQL SECTION
{{ config(materialized='table') }}

WITH date_dimension AS (
    -- This macro expands into a full SELECT statement
    {{ dbt_date.get_date_dimension(
        start_date=start_date,
        end_date=end_date
    ) }}
)



SELECT 
     -- Primary Surrogate key
    {{ dbt_utils.generate_surrogate_key(['date_day']) }} AS date_key,

     -- The Natural Key 
    date_day,

    -- Descriptive Attributes
    year_number,
    quarter_of_year,
    month_name,
    month_of_year,
    day_of_week_name,
    day_of_week,

    -- Derived Attributes
    CASE
        WHEN day_of_week_name IN ('Saturday', 'Sunday') THEN true
        ELSE false
    END AS is_weekend,

    -- Audit Metadata
    CAST(CURRENT_TIMESTAMP() AS TIMESTAMP_LTZ) AS core_loaded_at
FROM date_dimension 



