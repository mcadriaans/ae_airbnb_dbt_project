{#
  Macro: expected_capacity
  Purpose: Derives the *expected* sleeping capacity of a listing based on its bedroom count.
           This models a business assumption used in accommodation analytics: most properties
           sleep roughly two people per bedroom, with studios and one‑bedrooms treated as equivalent.
           The output is used as a baseline for size classification (small/medium/large).

  Business Logic:
    - 0 bedrooms → expect 2 guests (studio)
    - 1 bedroom  → expect 2 guests
    - 2 bedrooms → expect 4 guests
    - 3 bedrooms → expect 6 guests
    - 4+ bedrooms → bedrooms * 2

  Example Usage:
    {{ expected_capacity('bedrooms') }}

  Returns:
    A SQL CASE expression that can be embedded inside larger transformations.
#}

{% macro expected_capacity(bedrooms) %}
    CASE
        WHEN {{ bedrooms }} = 0 THEN 2
        WHEN {{ bedrooms }} = 1 THEN 2
        WHEN {{ bedrooms }} = 2 THEN 4
        WHEN {{ bedrooms }} = 3 THEN 6
        ELSE {{ bedrooms }} * 2
    END
{% endmacro %}
