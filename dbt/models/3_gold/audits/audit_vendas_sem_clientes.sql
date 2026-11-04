SELECT
    f.id_vendas,
    c.id_clientes,
    f.data_venda
FROM {{ ref('silver_vendas') }} AS f
LEFT JOIN {{ ref('silver_clientes') }} AS c
    ON f.id_clientes = c.id_clientes
WHERE c.id_clientes IS null