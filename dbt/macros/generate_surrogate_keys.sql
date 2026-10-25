{# 
    Macro wrapper para geração de Surrogate Key.
    Encapsula o dbt_utils.generate_surrogate_key para desacoplar dependências diretas nos modelos.
#}
{% macro generate_surrogate_key(field_list) %}
    {{ dbt_utils.generate_surrogate_key(field_list) }}
{% endmacro %}