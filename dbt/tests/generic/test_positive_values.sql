{# 
    Teste Genérico Customizado: positive_value
    
    Objetivo:
    Garantir que os valores de uma coluna numérica sejam estritamente positivos 
    (maiores que zero), detectando registros zerados ou negativos decorrentes de 
    falhas de negócio ou anomalias no sistema de origem.
    
    Parâmetros:
    - model: O modelo dbt que está sendo testado (passado automaticamente pelo dbt).
    - column_name: A coluna numérica a ser validada (passada automaticamente pelo dbt).
#}

{% test positive_value(model,column_name) %}

   select * from {{ model }}
   where {{ column_name }} is not null and 
   {{ column_name }} <=0

{% endtest %}