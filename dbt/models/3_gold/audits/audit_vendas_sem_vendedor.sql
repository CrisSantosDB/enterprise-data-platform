SELECT
    f.id_vendas,
    v.id_vendedores,
    f.data_venda
FROM {{ ref('silver_vendas') }} AS f
LEFT JOIN {{ ref('silver_vendedores') }} AS v
    ON f.id_vendedores = v.id_vendedores
WHERE v.id_vendedores IS null
