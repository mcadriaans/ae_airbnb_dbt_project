-- snapshots/listings_snapshot.sql : Uses timestamp strategy to watch updated_at and track history.

-- SCD2 Snapshot: Tracks all listing versions over time
-- When a listing record is updated, creates new version with dbt_valid_from/to
-- Result: One listing_id can have multiple rows (one per version)
-- Analyst usage: Filter WHERE dbt_valid_to IS NULL for latest, or query full history for cohort analysis.

{% snapshot listings_snapshot %}
    {{
        config(
            target_schema='snapshots',
            unique_key='listing_id',
            strategy='timestamp',
            updated_at='source_updated_at'
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
        source_created_at,
        source_updated_at:: TIMESTAMP_NTZ AS source_updated_at
    FROM {{ ref('stg_airbnb__listings') }}

{% endsnapshot %}