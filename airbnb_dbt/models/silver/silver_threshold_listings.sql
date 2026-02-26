{{ config(materialized='table') }}

SELECT
    MEDIAN(price_per_night) AS price_median,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY price_per_night) AS price_p75,
    MEDIAN(bedrooms) AS bedrooms_median,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY bedrooms) AS bedrooms_p75,
    MEDIAN(accommodates) AS accommodates_median,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY accommodates) AS accomodates_p75
FROM {{ ref('bronze_listings') }}
