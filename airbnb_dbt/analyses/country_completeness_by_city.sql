-- Jinja statement using ref()


-- This query performs a simple data‑quality check by showing, for each city,
-- how many listings exist and how many of those listings have a NULL value
-- in the country column. Ordering by the number of nulls highlights which
-- cities have the worst data completeness issues and may need cleaning
-- before moving from bronze to silver.
SELECT
    city,
    COUNT(*) as total_rows,
    count_if(country IS NULL) as null_country_rows
FROM {{ ref('silver_listings') }}
GROUP BY  1
ORDER BY 3 DESC;
