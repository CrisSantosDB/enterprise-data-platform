{# 
    Calcula a data da última modificação do registo usando (greatest(inclusion_col,update_col) e pega a data mais atual).
    Compara inclusão e atualização e retorna a maior data (greatest).
    O '1900-01-01' evita que valores NULL anulem a comparação quando a linha nunca foi editada.
#}
{% macro modification_timestamp_expr(inclusion_col='data_inclusao', update_col='data_atualizacao') -%}
    greatest(
        coalesce({{ inclusion_col }}, timestamp('1900-01-01 00:00:00')),
        coalesce({{ update_col }}, timestamp('1900-01-01 00:00:00'))
    )
{%- endmacro %}

{# 
    Gera o filtro WHERE para cargas incrementais com janela de segurança (lookback window).
    Calcula a marca de água a partir do valor máximo na tabela de destino ({{ this }})
    e subtrai um intervalo de tolerância (padrão de 5 minutos) para capturar dados atrasados.
#}
{% macro get_incremental_watermark(modification_ts_column, watermark_column=none) -%}
    {%- set watermark_column = watermark_column or modification_ts_column -%}
    {% if is_incremental() %}
    and {{ modification_ts_column }} >= (
        select coalesce(max({{ watermark_column }}), timestamp('1900-01-01 00:00:00'))
        from {{ this }}
    ) - interval {{ var("incremental_safety_window_minutes", 5) }} minute
    {% endif %}
{%- endmacro %}