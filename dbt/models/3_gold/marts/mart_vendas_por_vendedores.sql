WITH base AS (
    SELECT
        v.id_vendedores,
        v.nome AS vendedor,
        c.concessionaria,
        f.quantidade_vendas,
        f.valor_pago,
        f.valor_desconto,
        c.cidade,
        c.estado,
        c.regiao,
        d.ano_mes

    FROM {{ ref('fato_vendas') }} AS f
    LEFT JOIN {{ ref('dim_vendedores') }} AS v
        ON f.sk_vendedores = v.sk_vendedores
    LEFT JOIN {{ ref('dim_data') }} AS d
        ON f.sk_data = d.sk_data
    LEFT JOIN {{ ref('dim_concessionarias') }} AS c
        ON f.sk_concessionarias = c.sk_concessionarias

),

agregacao AS (
    SELECT
        id_vendedores,
        vendedor,
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
        id_vendedores,
        vendedor,
        concessionaria,
        cidade,
        estado,
        regiao,
        ano_mes

),

rank_vendedores AS (
    SELECT
        id_vendedores,
        vendedor,
        concessionaria,
        quantidade_vendas,
        receita,
        media_desconto,
        cidade,
        estado,
        regiao,
        ano_mes,
        {{ safe_divide('receita','quantidade_vendas') }} AS ticket_medio,
        dense_rank() OVER (PARTITION BY ano_mes ORDER BY receita DESC) AS posicao_vendedores,
        lag(receita) OVER (PARTITION BY id_vendedores ORDER BY ano_mes) AS receita_mes_anterior
    FROM agregacao
)

SELECT
    id_vendedores,
    vendedor,
    concessionaria,
    quantidade_vendas,
    receita,
    media_desconto,
    cidade,
    estado,
    regiao,
    ano_mes,
    ticket_medio,
    posicao_vendedores,
    receita_mes_anterior,
    {{ audit_columns() }}
FROM rank_vendedores

