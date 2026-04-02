{#
  Macro: size_tier
  Purpose: Classifies a listing into a size tier (small, medium, large) by comparing its
           actual accommodates value to the expected capacity derived from bedroom count.
           This hybrid approach captures both structural size (bedrooms) and functional size
           (how many guests the listing can realistically host).

  Business Logic:
    - small  → accommodates < expected_capacity
    - medium → accommodates == expected_capacity or expected_capacity + 1
    - large  → accommodates > expected_capacity + 1

  Example Usage:
    {{ size_tier('bedrooms', 'accommodates') }}

  Returns:
    A SQL CASE expression that outputs 'small', 'medium', or 'large'.
#}

{% macro size_tier(bedrooms, accommodates) %}
    CASE
        WHEN {{ accommodates }} < ({{ expected_capacity(bedrooms) }}) THEN 'small'
        WHEN {{ accommodates }} <= ({{ expected_capacity(bedrooms) }}) + 1 THEN 'medium'
        ELSE 'large'
    END
{% endmacro %}
