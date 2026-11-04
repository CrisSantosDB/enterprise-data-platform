WITH base AS (
    SELECT
        c.id_concessionarias,
        c.concessionaria,
        c.cidade,
        c.estado,
        c.regiao,
        f.quantidade_vendas,
        f.valor_pago,
        f.valor_desconto,
        d.ano_mes

    FROM {{ ref('fato_vendas') }} AS f
    LEFT JOIN {{ ref('dim_concessionarias') }} AS c
        ON f.sk_concessionarias = c.sk_concessionarias
    LEFT JOIN {{ ref('dim_data') }} AS d
        ON f.sk_data = d.sk_data

),

agregacao AS (
    SELECT
        id_concessionarias,
        concessionaria,
        cidade,
        estado,
        regiao,
        ano_mes,
        sum(quantidade_vendas) AS quantidade_vendas,
        sum(valor_pago) AS receita,
        round(avg(valor_desconto), 2) AS media_desconto
    FROM base
    GROUP BY
        id_concessionarias,
        concessionaria,
        cidade,
        estado,
        regiao,
        ano_mes
),

rank_concessionaria AS (
    SELECT
        id_concessionarias,
        concessionaria,
        cidade,
        estado,
        regiao,
        ano_mes,
        quantidade_vendas,
        receita,
        media_desconto,
        round({{ safe_divide('receita','quantidade_vendas') }}, 2) AS ticket_medio,
        dense_rank() OVER (PARTITION BY ano_mes ORDER BY receita DESC) AS posicao_nacional,
        dense_rank() OVER (PARTITION BY ano_mes, regiao ORDER BY receita DESC) AS posicao_regional,
        lag(receita) OVER (PARTITION BY id_concessionarias ORDER BY ano_mes) AS receita_mes_anterior
    FROM agregacao

)

SELECT
    id_concessionarias,
    concessionaria,
    cidade,
    estado,
    regiao,
    ano_mes,
    quantidade_vendas,
    receita,
    media_desconto,
    ticket_medio,
    posicao_nacional,
    posicao_regional,
    receita_mes_anterior,
    {{ percentage_change('receita','receita_mes_anterior') }}
        AS crescimento_mensal,
    {{ audit_columns() }}
FROM rank_concessionaria
