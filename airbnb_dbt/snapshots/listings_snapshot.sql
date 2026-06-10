--listings_snapshot.sql
{% snapshot listings_snapshot %}

    {{
        config(
            target_schema='snapshots',
            unique_key='listing_id',
            strategy='timestamp',
            updated_at='updated_at'
        )
    }}
    
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
    FROM {{ ref('stg_airbnb__listings') }}
    
{% endsnapshot %}