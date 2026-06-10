--hosts_snapshot.sql
{% snapshot hosts_snapshot %}
    {{
        config(
            target_schema='snapshots',
            unique_key='host_id',
            strategy='timestamp',
            updated_at='updated_at'
        )
    }}
    
    SELECT
        host_id,
        host_name,
        host_since,
        host_location,
        is_superhost,
        response_rate,
        avg_host_rating,
        created_at,
        updated_at
    FROM {{ ref('stg_airbnb__hosts') }}

{% endsnapshot %}