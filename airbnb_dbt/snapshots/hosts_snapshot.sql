-- snapshots/hosts_snapshot.sql : Uses timestamp strategy to watch updated_at and track history.

-- SCD2 Snapshot: Tracks all host versions over time
-- When a host record is updated, creates new version with dbt_valid_from/to
-- Result: One host_id can have multiple rows (one per version)
-- Analyst usage: Filter WHERE dbt_valid_to IS NULL for latest, or query full history for cohort analysis.

{% snapshot hosts_snapshot %}
    {{
        config(
            target_schema='snapshots',
            unique_key='host_id',
            strategy='timestamp',
            updated_at='source_updated_at'
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
        source_created_at,
        source_updated_at:: TIMESTAMP_NTZ AS source_updated_at
    FROM {{ ref('stg_airbnb__hosts') }}

{% endsnapshot %}