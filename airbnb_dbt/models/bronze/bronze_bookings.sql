{{ config(
    materialized='incremental',
    unique_key='BOOKING_ID',
    on_schema_change='sync_all_columns'
) }}

SELECT *
FROM {{ source('staging', 'bookings') }}

{% if is_incremental() %}
  WHERE CREATED_AT > (SELECT MAX(CREATED_AT) FROM {{ this }}
  )
{% endif %}
