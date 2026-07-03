-- gold/core/dim_location.sql
-- Grain: One row per unique City and Country combination.
-- Description: Geographic dimension table that enriches Airbnb listing locations with
--              coordinates,population data, and administrative metadata 
--              (e.g., capital city status).
WITH unique_locations AS (
    SELECT DISTINCT
        city,
        country
    FROM {{ ref('silver_listings') }}
),

geo_reference AS (
    SELECT 
        id AS city_id,
        INITCAP(TRIM(city_ascii)) AS city,
        INITCAP(TRIM(country)) AS country,
        iso2 AS country_code_2,
        iso3 AS country_code_3,
        lat AS latitude,
        lng AS longitude,
        INITCAP(TRIM(admin_name)) AS admin_name,
        capital,
        CASE
            WHEN LOWER(TRIM(capital)) = 'primary' THEN 'National Capital'
            WHEN LOWER(TRIM(capital)) = 'admin' THEN 'Provincial/State Capital'
            WHEN LOWER(TRIM(capital)) = 'minor' THEN 'Administrative Capital'
            WHEN LOWER(TRIM(capital)) = '-' OR capital IS NULL THEN 'Non-capital'
            ELSE 'Unknown'
        END AS capital_type,
        population,

        -- Handle duplicate city names within a country
        -- Keep the most populated match
        ROW_NUMBER() OVER (
            PARTITION BY 
                INITCAP(TRIM(city_ascii)),
                INITCAP(TRIM(country))
            ORDER BY population DESC
        ) AS rn

    FROM {{ ref('country_cities') }}
)

SELECT 
    {{ dbt_utils.generate_surrogate_key(['u.city', 'u.country']) }} AS location_key,
    u.city,
    u.country,
    g.latitude,
    g.longitude,
    g.country_code_2,
    g.country_code_3,
    g.admin_name AS state_province,
    g.capital_type,
    g.population,
    CAST(CURRENT_TIMESTAMP() AS TIMESTAMP_LTZ) AS loaded_at
FROM unique_locations AS u
LEFT JOIN geo_reference AS g
    ON u.city = g.city
      AND u.country = g.country
      AND g.rn = 1




 


