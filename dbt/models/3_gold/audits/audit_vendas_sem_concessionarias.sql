SELECT
    f.id_vendas,
    c.id_concessionarias,
    f.data_venda
FROM {{ ref('silver_vendas') }} AS f
LEFT JOIN {{ ref('silver_concessionarias') }} AS c
    ON f.id_concessionarias = c.id_concessionarias
WHERE c.id_concessionarias IS null
