{{ config(unique_key='id_vendas') }}

WITH base AS (
    SELECT
        id_vendas,
        id_veiculos,
        id_concessionarias,
        id_vendedores,
        id_clientes,
        valor_pago,
        data_venda,
        data_inclusao,
        data_atualizacao,
        {{ modification_timestamp_expr() }} AS _source_modified_at
    FROM {{ ref('bronze_vendas') }}
    WHERE id_vendas IS NOT null
),

source AS (

    SELECT
        id_vendas,
        id_veiculos,
        id_concessionarias,
        id_vendedores,
        id_clientes,
        valor_pago,
        data_venda,
        data_inclusao,
        data_atualizacao,
        _source_modified_at
    FROM base
    WHERE
        1 = 1
        {{ get_incremental_watermark('_source_modified_at') }}

),

ranked AS (
    SELECT
        id_vendas,
        id_veiculos,
        id_concessionarias,
        id_vendedores,
        id_clientes,
        valor_pago,
        data_venda,
        data_inclusao,
        data_atualizacao,
        _source_modified_at,
        row_number() OVER (PARTITION BY id_vendas ORDER BY _source_modified_at DESC) AS _rn
    FROM source
),

deduplicated AS (

    SELECT
        id_vendas,
        id_veiculos,
        id_concessionarias,
        id_vendedores,
        id_clientes,
        valor_pago,
        data_venda,
        data_inclusao,
        data_atualizacao,
        _source_modified_at

    FROM ranked
    WHERE _rn = 1

),

month_day AS (
    SELECT
        id_vendas,
        id_veiculos,
        id_concessionarias,
        id_vendedores,
        id_clientes,
        valor_pago,
        data_venda,
        data_inclusao,
        data_atualizacao,
        _source_modified_at,
        format_timestamp('%d', data_venda) AS dia_venda,
        format_timestamp('%m', data_venda) AS mes_venda,
        format_timestamp('%Y', data_venda) AS ano_venda

    FROM deduplicated

)

SELECT
    id_vendas,
    id_veiculos,
    id_concessionarias,
    id_vendedores,
    id_clientes,
    valor_pago,
    data_venda,
    cast(dia_venda AS int64) AS dia_venda,
    cast(mes_venda AS int64) AS mes_venda,
    cast(ano_venda AS int64) AS ano_venda,
    data_inclusao,
    data_atualizacao,
    _source_modified_at,
    {{ audit_columns() }}
FROM month_day
