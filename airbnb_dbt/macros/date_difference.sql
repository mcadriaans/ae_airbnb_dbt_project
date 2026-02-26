{#
  Macro: date_diff
  Purpose: Compute the difference between two dates or timestamps using a specified date part.
           This wraps the warehouse DATEDIFF function and keeps models clean and consistent.

  Parameters:
    - date_part: the unit of difference ('day', 'month', 'year', etc.)
    - start_date: the earlier date or timestamp column
    - end_date: the later date or timestamp column

  Example Usage:
    {{ date_diff('day', 'host_since', 'current_date') }}
    {{ date_diff('year', 'host_since', 'booking_date') }}

  Returns:
    A SQL DATEDIFF expression.
#}

{% macro date_diff(date_part, start_date, end_date) %}
    DATEDIFF({{ date_part }}, {{ start_date }}, {{ end_date }})
{% endmacro %}
