SELECT DISTINCT
    listing_id,
    host_id,
    city,
    country,
    property_type,
    room_type
FROM {{ ref('silver_listings')}}