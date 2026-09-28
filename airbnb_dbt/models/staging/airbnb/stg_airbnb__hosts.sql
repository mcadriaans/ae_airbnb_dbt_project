--staging/airbnb/stg_airbnb__hosts.sql : This staging model extracts raw host data from the bronze layer, performs initial data cleaning and standardization,
-- and prepares it for further transformation in the silver layer. It includes data type conversions, trimming of string fields, 
-- and basic formatting to ensure consistency and readiness for downstream processing.



WITH source AS (
    SELECT 
        host_id,
        host_name,
        host_since,
        host_location,
        is_superhost,
        response_rate,
        avg_host_rating,
        created_at,
        updated_at
    FROM {{ source('airbnb', 'bronze_hosts') }}
),
standardized AS (
    SELECT
       -- Natural Keys
        CAST(host_id AS INT) AS host_id,

        -- Host Dimensions
        CAST(INITCAP(TRIM(host_name)) AS VARCHAR) AS host_name,
        CAST(host_since AS DATE) AS host_since,
        CAST(INITCAP(TRIM(host_location)) AS VARCHAR) AS host_location,
        COALESCE(is_superhost, false) AS is_superhost,
        
        -- Host Metrics
        CAST({{ safe_divide("response_rate" , "100.0", decimals=2) }} AS DECIMAL(18,2)) AS response_rate,
        CAST(avg_host_rating AS DECIMAL(18,2)) AS avg_host_rating,

        -- Metadata tracking
        CAST(created_at AS timestamp_ltz) AS source_created_at,
        CAST(updated_at AS timestamp_ltz) AS source_updated_at
    FROM source
)

SELECT * FROM standardized
