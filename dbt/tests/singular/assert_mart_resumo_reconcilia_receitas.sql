WITH fato AS (

    SELECT
        d.ano_mes,
        sum(f.valor_pago) AS receita_fato
    FROM {{ ref('fato_vendas') }} AS f
    LEFT JOIN {{ ref('dim_data') }} AS d
        ON f.sk_data = d.sk_data
    GROUP BY d.ano_mes

),

mart AS (

    SELECT
        ano_mes,
        receita_liquida AS receita_mart
    FROM {{ ref('mart_visao_geral_mes') }}

)

SELECT
    f.ano_mes,
    f.receita_fato,
    m.receita_mart
FROM fato AS f
INNER JOIN mart AS m
    ON f.ano_mes = m.ano_mes
WHERE abs(f.receita_fato - m.receita_mart) > 0.01
