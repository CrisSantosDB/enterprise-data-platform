{{ config(unique_key='id_vendas') }}

WITH source AS (
    SELECT
        v.id_vendas,
        v.data_inclusao,
        DATE(v.data_venda) AS data_venda,
        COALESCE(dv.sk_vendedores, '-1') AS sk_vendedores,
        COALESCE(dc.sk_concessionarias, '-1') AS sk_concessionarias,
        COALESCE(dcli.sk_clientes, '-1') AS sk_clientes,
        COALESCE(dve.sk_veiculos, '-1') AS sk_veiculos,
        COALESCE(dd.sk_data, -1) AS sk_data,
        COALESCE(ve.valor_tabela, 0.0) AS valor_tabela,
        COALESCE(v.valor_pago, 0.0) AS valor_pago,
        1 AS quantidade_vendas

    FROM {{ ref('silver_vendas') }} AS v

    LEFT JOIN {{ ref('dim_vendedores') }} AS dv
        ON v.id_vendedores = dv.id_vendedores

    LEFT JOIN {{ ref('dim_concessionarias') }} AS dc
        ON v.id_concessionarias = dc.id_concessionarias

    LEFT JOIN {{ ref('dim_clientes') }} AS dcli
        ON v.id_clientes = dcli.id_clientes

    LEFT JOIN {{ ref('dim_veiculos') }} AS dve
        ON v.id_veiculos = dve.id_veiculos

    LEFT JOIN {{ ref('dim_data') }} AS dd
        ON DATE(v.data_venda) = dd.dt_data

    LEFT JOIN {{ ref('silver_veiculos') }} AS ve
        ON v.id_veiculos = ve.id_veiculos

    {% if is_incremental() %}
    WHERE
        v.data_inclusao >= (
            SELECT MAX(destino.data_inclusao)
            FROM {{ this }} AS destino
        )
    {% endif %}
),

metricas AS (
    SELECT
        id_vendas,
        sk_vendedores,
        sk_concessionarias,
        sk_clientes,
        sk_veiculos,
        sk_data,
        data_venda,
        quantidade_vendas,
        valor_tabela,
        valor_pago,
        data_inclusao,
        valor_tabela - valor_pago AS valor_desconto,
        ROUND(
            {{ safe_divide('(valor_tabela - valor_pago)', 'valor_tabela') }},
            3
        ) AS percentual_desconto

    FROM source
),

fct_vendas AS (
    SELECT
        id_vendas,
        sk_vendedores,
        sk_concessionarias,
        sk_clientes,
        sk_veiculos,
        sk_data,
        data_venda,
        quantidade_vendas,
        valor_tabela,
        valor_pago,
        valor_desconto,
        percentual_desconto,
        data_inclusao,

        CASE
            WHEN valor_desconto <= 0 THEN 0
            ELSE 1
        END AS flag_desconto,
        {{ audit_columns() }}

    FROM metricas
)

SELECT *
FROM fct_vendas