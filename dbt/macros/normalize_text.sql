{# trim espaços e converte string vazia pra null#}
{% macro normalize_text(column_name)-%}
    nullif(
        trim(
            regexp_replace(cast({{column_name}} as string), r'\s+', ' ')
        ),
        '')  
{%- endmacro%}

{# trim simples#}
{% macro safe_trim(column_name) -%}
    nullif(trim(cast({{column_name}} as string)), '')
{%- endmacro %}

{# converte pra maisculas #}
{% macro normalize_upper(column_name) -%}
    upper({{ normalize_text(column_name)}})
{%- endmacro%}

{# Tira acentos #}
{% macro tira_acentos(column_name) -%}
     regexp_replace(normalize({{ column_name }}, NFD), r'\pM', '')

{%- endmacro %}