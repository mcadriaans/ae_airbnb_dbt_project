{{ config(
    materialized='incremental',
    unique_key='LISTING_ID'
) }}

SELECT *
FROM {{ source('staging', 'listings') }}

{% if is_incremental() %}
  WHERE CREATED_AT > (SELECT MAX(CREATED_AT) FROM {{ this }}
  )
{% endif %}









