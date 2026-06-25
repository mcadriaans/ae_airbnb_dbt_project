-- staging/airbnb/stg_airbnb__bookings.sql : 
-- Standardizes raw booking data, handles optional NULLs, and filters out incomplete records.

{% set mandatory_columns = [
    'booking_id',
    'booking_date',
    'booking_status',
    'listing_id',
    'stay_start_date',
    'nights_booked',
    'booking_amount'
]%}

WITH source AS (
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
    FROM {{ source('airbnb', 'bronze_bookings') }}

),

standardized AS (
    SELECT
       -- Keys & Status
        LOWER(TRIM(booking_id)) AS booking_id,
        CAST(listing_id AS INT) AS listing_id,
        LOWER(TRIM(booking_status)) AS booking_status,

        -- Dates
        CAST(booking_date AS DATE) AS booking_date,
        CAST(stay_start_date AS DATE) AS stay_start_date,

        -- Mandatory Metrics
        CAST(nights_booked AS INT) AS nights_booked,
        CAST(booking_amount AS DECIMAL(18,2)) AS booking_amount,

        -- Optional Metrics (Resiliency; Coalesce NULLs to 0.00)
        CAST(COALESCE(cleaning_fee, 0) AS DECIMAL(18,2)) AS cleaning_fee,
        CAST(COALESCE(service_fee, 0) AS DECIMAL(18,2)) AS service_fee,
        CAST(COALESCE(cancellation_fee, 0) AS DECIMAL(18,2)) AS cancellation_fee,

        -- Metadata tracking
        CAST(created_at AS timestamp_ntz) AS created_at,
        CAST(updated_at AS timestamp_ntz) AS updated_at
    FROM source
    -- Data Integrity: Filter out records missing mandatory business logic keys or metrics.
    WHERE 
     {% for col in mandatory_columns -%}
        {{ col }} IS NOT NULL {% if not loop.last %} AND {% endif %}
     {%- endfor %}
)

SELECT * FROM standardized