--stg_airbnb__listings.sql : This staging model extracts raw listing data from the bronze layer, performs initial data cleaning and standardization,
-- and prepares it for further transformation in the silver layer. It includes data type conversions, trimming of string fields, and basic formatting
-- to ensure consistency and readiness for downstream processing.

{% set mandatory_columns = ['listing_id', 'host_id', 'price_per_night'] %}
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
        CAST(listing_id AS INT) AS listing_id,
        CAST(host_id AS INT) AS host_id,
        INITCAP(TRIM(property_type)) AS property_type,
        INITCAP(TRIM(city)) AS city,
        INITCAP(TRIM(country)) AS country,
        CAST(accommodates AS INT) AS accommodates,
        CAST(bedrooms AS INT) AS bedrooms,
        CAST(bathrooms AS DECIMAL(4,2)) AS bathrooms,
        CAST(price_per_night AS DECIMAL(10,2)) AS price_per_night,
        CAST(created_at AS timestamp_ntz) AS created_at,
        CAST(updated_at AS timestamp_ntz) AS updated_at
    FROM source
    WHERE 
        {% for col in mandatory_columns -%}
            {{ col }} IS NOT NULL {% if not loop.last %} AND {% endif %}
        {%- endfor %}
)

SELECT * FROM standardized