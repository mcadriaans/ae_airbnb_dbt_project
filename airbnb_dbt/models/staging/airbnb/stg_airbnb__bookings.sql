-- staging/airbnb/stg_airbnb__bookings.sql : This staging model extracts raw booking data from the bronze layer, 
-- performs initial data cleaning and standardization, and prepares it for further transformation in the silver layer. 
-- It includes data type conversions, trimming of string fields, and basic formatting to ensure consistency and readiness for downstream processing.

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
        LOWER(TRIM(booking_id)) AS booking_id,
        CAST(booking_date AS DATE) AS booking_date,
        LOWER(TRIM(booking_status)) AS booking_status,
        CAST(listing_id AS NUMERIC(38,0)) AS listing_id,
        CAST(stay_start_date AS DATE) AS stay_start_date,
        CAST(nights_booked AS INTEGER) AS nights_booked,
        CAST(booking_amount AS DECIMAL(18,2)) AS booking_amount,
        CAST(cleaning_fee AS DECIMAL(18,2)) AS cleaning_fee,
        CAST(service_fee AS DECIMAL(18,2)) AS service_fee,
        CAST(cancellation_fee AS DECIMAL(18,2)) AS cancellation_fee,
        CAST(created_at AS timestamp_ntz) AS created_at,
        CAST(updated_at AS timestamp_ntz) AS updated_at
    FROM source
)

SELECT * FROM standardized