{% macro date_spine(datepart, start_date, end_date) %}
    {{ dbt_utils.date_spine(datepart = datepart , start_date = start_date, end_date = end_date) }}
{%- endmacro %}