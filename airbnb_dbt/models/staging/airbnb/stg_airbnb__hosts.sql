--stg_airbnb__hosts.sql : This staging model extracts raw host data from the bronze layer, performs initial data cleaning and standardization,
-- and prepares it for further transformation in the silver layer. It includes data type conversions, trimming of string fields, 
-- and basic formatting to ensure consistency and readiness for downstream processing.
WITH source AS (
    SELECT *
    FROM {{ source('airbnb', 'bronze_hosts') }}

),
standardized AS (
    SELECT
        CAST(host_id AS NUMERIC(38,0)) AS host_id,
        INITCAP(TRIM(host_name)) AS host_name,
        CAST(host_since AS DATE) AS host_since,
        INITCAP(TRIM(host_location)) AS host_location,
        COALESCE(is_superhost, false) AS is_superhost,
        (CAST(response_rate AS DECIMAL(10,2))/100.0) AS response_rate,
        CAST(avg_host_rating AS DECIMAL(10,2)) AS avg_host_rating,
        CAST(created_at AS timestamp_ntz) AS created_at,
        CAST(updated_at AS timestamp_ntz) AS updated_at
    FROM source
)

SELECT * FROM standardized
