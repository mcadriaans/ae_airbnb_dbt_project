-- models/gold/core/dim_location.sql
-- Grain: One row per unique City and Country combination.
-- SCD: Type 1 (current state only) with SCD2 history preserved in silver layer.
-- Description: Geographic dimension table that enriches Airbnb listing locations with
--              coordinates,population data, and administrative metadata 
--              (e.g., capital city status).
WITH unique_locations AS (
    SELECT DISTINCT
        city,
        country
    FROM {{ ref('silver_listings') }}
    -- Filter out historical versions of listings, keeping only the most recent version for each listing_id
    WHERE is_current_record = 1
),

geo_reference AS (
    SELECT 
        id AS city_id,
        INITCAP(TRIM(city_ascii)) AS city,
        CAST(
            CASE UPPER(TRIM(country))
                -- Handle common country name variations
                WHEN 'UNITED STATES OF AMERICA' THEN 'United States of America'
                WHEN 'UNITED KINGDOM' THEN 'United Kingdom'
                WHEN 'U.S.A.' THEN 'United States of America'
                WHEN 'U.K.' THEN 'United Kingdom'
                WHEN 'USA' THEN 'United States of America'
                WHEN 'UK' THEN 'United Kingdom'
                WHEN 'US' THEN 'United States of America'
                WHEN 'UNITED STATES' THEN 'United States of America'
                ELSE INITCAP(TRIM(country))
            END AS VARCHAR 
        ) AS country,
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
            ORDER BY COALESCE(population, 0) DESC
        ) AS rn

    FROM {{ ref('country_cities') }}
)

SELECT 
    -- Matches the location_key hash lookups built into dim_listings
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
    CAST(CURRENT_TIMESTAMP() AS TIMESTAMP_LTZ) AS core_loaded_at
FROM unique_locations AS u
LEFT JOIN geo_reference AS g
    ON u.city = g.city
      AND u.country = g.country
      AND g.rn = 1




 


