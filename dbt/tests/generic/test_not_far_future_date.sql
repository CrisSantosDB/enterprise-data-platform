{# 
    Teste Genérico Customizado: not_far_future_date
    
    Objetivo:
    Detectar registros com datas/timestamps inconsistentes no futuro (anomalias de digitação, 
    fusos desconfigurados ou erros de sistema, como anos 2099 ou datas à frente do permitido).
    
    Parâmetros:
    - model: O modelo dbt que está sendo testado (passado automaticamente pelo dbt).
    - column_name: A coluna de timestamp a ser validada (passada automaticamente).
    - max_days_ahead: Tolerância máxima de dias no futuro. O padrão é 1 dia para acomodar 
                      diferenças de fusos horários (UTC vs horário local).
#}

{% test not_far_future_date(model, column_name, max_days_ahead=1) %}

select *
from {{ model }}
where 
    
    {{ column_name }} is not null 

    and {{ column_name }} > timestamp_add(current_timestamp(), interval {{ max_days_ahead }} day)

{% endtest %}