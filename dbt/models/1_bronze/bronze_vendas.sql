{{ config(unique_key="id_vendas") }}

WITH source AS (
    SELECT
        id_vendas,
        id_veiculos,
        id_concessionarias,
        id_vendedores,
        id_clientes,
        valor_pago,
        data_venda,
        data_inclusao,
        data_atualizacao
    FROM {{ source("raw","vendas") }}
)

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
    current_timestamp() AS _loaded_at
FROM source AS src

{% if is_incremental() %}

WHERE src.data_inclusao >= (SELECT max(destino.data_inclusao) FROM {{ this }} AS destino)

{% endif %}