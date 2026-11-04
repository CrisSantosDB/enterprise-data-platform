SELECT
    f.id_vendas,
    v.id_veiculos,
    f.data_venda
FROM {{ ref('silver_vendas') }} AS f
LEFT JOIN {{ ref('silver_veiculos') }} AS v
    ON f.id_veiculos = v.id_veiculos
WHERE v.id_veiculos IS null
