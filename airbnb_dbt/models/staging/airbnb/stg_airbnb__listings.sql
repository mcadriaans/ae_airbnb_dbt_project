--stg_airbnb__listings.sql 
-- -- Standardizes property inventory data and prepares Star Schema join anchors.


WITH source AS (
    SELECT 
        listing_id,
        host_id,
        property_type,
        city,
        country,
        accommodates,
        bedrooms,
        bathrooms,
        price_per_night,
        created_at,
        updated_at 
    FROM {{ source('airbnb', 'bronze_listings') }}
),

standardized AS (
    SELECT
        -- Natural Keys
        CAST(listing_id AS INT) AS listing_id,
        CAST(host_id AS INT) AS host_id,

        -- Dimensions
        CAST(INITCAP(TRIM(property_type)) AS VARCHAR) AS property_type,
        CAST(INITCAP(TRIM(city)) AS VARCHAR) AS city,
        CAST(
                CASE UPPER(TRIM(country))
                    -- United States
                    WHEN 'USA'                      THEN 'United States'
                    WHEN 'US'                       THEN 'United States'
                    WHEN 'UNITED STATES'            THEN 'United States'
                    WHEN 'UNITED STATES OF AMERICA' THEN 'United States'

                    -- United Kingdom
                    WHEN 'UK'              THEN 'United Kingdom'
                    WHEN 'UNITED KINGDOM'  THEN 'United Kingdom'
                ELSE INITCAP(TRIM(country)) 
            END AS VARCHAR
        ) AS country,

        -- Metrics
        CAST(accommodates AS INT) AS accommodates,
        CAST(bedrooms AS INT) AS bedrooms,
        CAST(bathrooms AS DECIMAL(18,2)) AS bathrooms,
        CAST(price_per_night AS DECIMAL(18,2)) AS price_per_night,

        -- Metadata tracking
        CAST(created_at AS timestamp_ltz) AS source_created_at,
        CAST(updated_at AS timestamp_ltz) AS source_updated_at

    FROM source
)

SELECT * FROM standardized