{{ config(
    materialized='incremental',
    unique_key='booking_id',
    on_schema_change='sync_all_columns'
) }}

WITH source_data AS (
    SELECT
        booking_id,
        listing_id,
        CAST(booking_date AS timestamp_ntz) AS booking_date,
        nights_booked,
        cleaning_fee,
        service_fee,
        lower(trim(booking_status)) AS booking_status,
        CAST(created_at AS timestamp_ntz) AS created_at,
        current_timestamp() AS ingested_at
    FROM {{ source('staging', 'bookings') }}
)

SELECT *
FROM source_data

{% if is_incremental() %}
    WHERE created_at > (SELECT MAX(created_at) FROM {{ this }})
{% endif %}



