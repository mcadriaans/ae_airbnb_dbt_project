{% set cols = ['listing_id', 'property_type', 'city', 'country']%}

SELECT 
    {{ cols | join(', ') }} 
FROM {{ ref('silver_listings') }}
