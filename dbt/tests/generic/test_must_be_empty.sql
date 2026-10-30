{# 
    Teste Genérico Customizado: must_be_empty
    
    Objetivo:
    Garantir que um modelo, consulta de exceção ou view de quarentena retorne 
    zero registros. No dbt, qualquer linha retornada por uma query de teste 
    indica uma falha.
    
    Parâmetros:
    - model: O modelo, semente ou view de auditoria a ser testado (passado 
             automaticamente pelo dbt).
#}

{% test must_be_empty(model) -%}
     select *
     from {{model}}
{% endtest %}