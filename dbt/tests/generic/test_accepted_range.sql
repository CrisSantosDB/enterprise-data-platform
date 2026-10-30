{# 
    Teste Genérico Customizado: accepted_range
    
    Objetivo:
    Validar se os valores de uma coluna numérica ou ordenável estão dentro de uma 
    faixa esperada (mínimo, máximo ou ambos), detectando anomalias ou violações 
    de regras de negócio.
    
    Parâmetros:
    - model: O modelo dbt que está sendo testado (passado automaticamente pelo dbt).
    - column_name: A coluna a ser validada (passada automaticamente pelo dbt).
    - min_value: Limite inferior aceito. Se for 'none', nenhum piso é validado.
    - max_value: Limite superior aceito. Se for 'none', nenhum teto é validado.
    - inclusive: Booleano que define se os limites informados são aceitos como válidos:
                 * true (padrão): Os limites fazem parte da faixa aceita (erro: < min ou > max).
                 * false: Os limites são estritamente exclusivos (erro: <= min ou >= max).
#}

{% test accepted_range(model, column_name, min_value=none, max_value=none, inclusive=true) %}

    with validation as (
        select {{ column_name }} as value_field
        from {{ model }}
        where {{ column_name }} is not null
    )

    select *
    from validation
    where
        {% if min_value is not none %}
            {% if inclusive %} value_field < {{ min_value }}
            {% else %} value_field <= {{ min_value }}
            {% endif %}
        {% else %} 1 = 0
        {% endif %}
        or
        {% if max_value is not none %}
            {% if inclusive %} value_field > {{ max_value }}
            {% else %} value_field >= {{ max_value }}
            {% endif %}
        {% else %} 1 = 0
        {% endif %}

{% endtest %}