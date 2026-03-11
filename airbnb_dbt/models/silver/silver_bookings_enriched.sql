{{ config(materialized='view') }}

WITH BASE AS (
    SELECT * FROM {{ ref('silver_bookings_deduped') }}
)

SELECT *
FROM BASE