WITH base AS (
    SELECT

        d.ano_mes,
        f.quantidade_vendas,
        f.valor_pago,
        f.valor_desconto
    FROM {{ ref('fato_vendas') }} AS f
    LEFT JOIN {{ ref('dim_data') }} AS d
        ON f.sk_data = d.sk_data

),

agregacao AS (

    SELECT

        ano_mes,
        sum(quantidade_vendas) AS quantidade_vendas_mes,
        sum(valor_pago) AS receita_total,
        sum(valor_desconto) AS desconto_total

    FROM base
    GROUP BY ano_mes

),

refinamento AS (
    SELECT
        ano_mes,
        quantidade_vendas_mes,
        receita_total AS receita_liquida,
        desconto_total,
        receita_total + desconto_total AS receita_bruta,
        round({{ safe_divide('receita_total','quantidade_vendas_mes') }}, 2) AS ticket_medio,
        lag(receita_total) OVER (ORDER BY ano_mes) AS receita_mes_anterior

    FROM agregacao
)

SELECT
    ano_mes,
    quantidade_vendas_mes,
    receita_liquida,
    desconto_total,
    receita_bruta,
    ticket_medio,
    receita_mes_anterior,
    {{ percentage_change('receita_liquida','receita_mes_anterior') }}
        AS crescimento_mom,
    {{ audit_columns() }}
FROM refinamento
