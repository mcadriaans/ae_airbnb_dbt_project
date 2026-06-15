-- bookings_snapshot.sql : Uses timestamp strategy to watch updated_at and track history.
{% snapshot bookings_snapshot %} 
    {{
        config(
            target_schema='snapshots',
            unique_key='booking_id',
            strategy='timestamp',
            updated_at='updated_at'
        )
    }}

    SELECT
        booking_id,
        booking_date,
        booking_status,
        listing_id,
        stay_start_date,
        nights_booked,
        booking_amount,
        cleaning_fee,
        service_fee,
        cancellation_fee,
        created_at,
        updated_at
    FROM {{ ref('stg_airbnb__bookings') }}
    
{% endsnapshot %}