{# 
    Teste Genérico Customizado: not_before_column
    
    Objetivo:
    Garantir a integridade cronológica ou sequencial entre duas colunas de um mesmo 
    registro, assegurando que o evento registrado em 'column_name' não tenha 
    ocorrido antes do evento registrado em 'compare_column'.
    
    Parâmetros:
    - model: O modelo dbt que está sendo testado (passado automaticamente pelo dbt).
    - column_name: A coluna de data/evento posterior a ser validada (passada automaticamente).
    - compare_column: O nome da coluna de data/evento anterior de referência para a comparação.
#}

{%  test not_before_column(model, column_name, compare_column) %}
      select *
      from {{ model }}
      where {{ column_name }} is not null 
      and {{ compare_column }} is not null  
      and  {{ column_name }} < {{ compare_column }}
{% endtest %}