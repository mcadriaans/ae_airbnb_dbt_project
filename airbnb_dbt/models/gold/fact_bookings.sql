WITH bookings AS (
    SELECT *
    FROM {{ ref('silver_bookings') }}
),
hosts AS (
    SELECT *
    FROM {{ ref('silver_hosts') }}
),
listings AS (
    SELECT *
    FROM {{ ref('silver_listings') }}
)


SELECT *
FROM bookings AS b