{# Jinja Examples #}

{# 1. Parameterizing SQL Logic with set in Jinja #}

{% set nights = 1 %}

SELECT * FROM {{ source('airbnb', 'bronze_bookings')}}
WHERE nights_booked > {{ nights}}
-------------------------------------------------------------
{# 2. Looping Through Columns to Generate SQL #}
{% set cols = ['nights_booked', 'booking_id', 'booking_amount']%}

SELECT 
{% for col in cols%}
    {{ col }}
    {% if not loop.last %}, {% endif %}
{% endfor %}
FROM {{ source('airbnb', 'bronze_bookings')}}

-----------------------------------------------------------------------
SELECT COUNT(*) FROM {{ source('airbnb', 'bronze_listings')}}