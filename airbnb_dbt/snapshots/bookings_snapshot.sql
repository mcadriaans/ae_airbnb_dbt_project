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
        booking_amount,
        updated_at
    FROM {{ source('airbnb', 'bronze_bookings') }}
    
{% endsnapshot %}