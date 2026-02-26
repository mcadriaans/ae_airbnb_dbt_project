{{ 
  config(
    materialized='incremental',
    unique_key='listing_id'
  ) 
}}

WITH thresholds AS (
    SELECT *
    FROM {{ ref('silver_threshold_listings') }}
),

base AS (
    SELECT
        b.*,
        t.price_median,
        t.price_p75,
        t.bedrooms_median,
        t.bedrooms_p75
    FROM {{ ref('bronze_listings') }} b
    CROSS JOIN thresholds t
)

SELECT
    listing_id,
    host_id,
    {{ normalize_text('property_type') }} AS property_type,
    {{ normalize_text('room_type') }} AS room_type,
    {{ normalize_text('city') }} AS city,
    {{ normalize_text('country') }} AS country,
    accommodates,
    bedrooms,
    CAST(bathrooms AS NUMBER(38,2)) AS bathrooms,
    CAST(price_per_night AS NUMBER(38,2)) AS price_per_night,
    {{ normalize_text(define_tier('price_per_night', 'price_median', 'price_p75', 'low', 'high', 'very high')) }} AS price_tier,
    {{ normalize_text(size_tier('bedrooms', 'accommodates')) }} AS size_tier
FROM base
