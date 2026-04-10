-- Jinja Control logic example

{% set focus_on_superhosts = true %}

{% if focus_on_superhosts %}
    -- Return only superhosts
    SELECT
        host_id,
        host_name,
        host_since,
        response_rate
    FROM {{ ref('silver_hosts') }}
    WHERE is_superhost = TRUE
    ORDER BY response_rate DESC

{% else %}
    -- Return only regular (non‑superhost) hosts
    SELECT
        host_id,
        host_name,
        host_since,
        response_rate
    FROM {{ ref('silver_hosts') }}
    WHERE is_superhost = FALSE
    ORDER BY response_rate DESC
{% endif %}

