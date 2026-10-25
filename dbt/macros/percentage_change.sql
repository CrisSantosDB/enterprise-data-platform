{#
    Macro: percentage_change
    Objetivo: Calcular a taxa de variação percentual (crescimento/queda) entre dois valores ou períodos.
    Fórmula: ((current_value - previous_value) / previous_value)

    Parâmetros:
      - current_value: Nome da coluna ou expressão do valor no período atual (ex: faturamento_atual).
      - previous_value: Nome da coluna ou expressão do valor no período base/anterior (ex: faturamento_anterior).

    Detalhes técnicos:
      1. O operador `~` do Jinja concatena as strings para construir a subtração `current_value - previous_value`.
      2. Reutiliza a macro `safe_divide` para evitar falhas de execução por divisão por zero caso `previous_value` seja 0 ou nulo.
#}
{% macro percentage_change(current_value, previous_value) -%}
    {{ safe_divide(current_value ~ " - " ~ previous_value, previous_value) }}
{%- endmacro %}