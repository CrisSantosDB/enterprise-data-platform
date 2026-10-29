{{ config(unique_key="id_clientes") }}

WITH source AS (
    SELECT
        id_clientes,
        cliente,
        endereco,
        id_concessionarias,
        data_inclusao,
        data_atualizacao
    FROM {{ source("raw","clientes") }}
)

SELECT
    id_clientes,
    cliente,
    endereco,
    id_concessionarias,
    data_inclusao,
    data_atualizacao,
    current_timestamp() AS _loaded_at
FROM source AS src
{% if is_incremental() %}

WHERE src.data_inclusao >= (SELECT max(destino.data_inclusao) FROM {{ this }} AS destino)

{% endif %}