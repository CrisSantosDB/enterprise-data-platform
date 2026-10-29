{{ config(unique_key="id_veiculos") }}

WITH source AS (
    SELECT
        id_veiculos,
        nome,
        tipo,
        valor,
        data_inclusao,
        data_atualizacao

    FROM {{ source("raw","veiculos") }}
)

SELECT
    id_veiculos,
    nome,
    tipo,
    valor,
    data_inclusao,
    data_atualizacao,
    current_timestamp() AS _loaded_at
FROM source AS src
{% if is_incremental() %}

WHERE src.data_inclusao >= (SELECT max(destino.data_inclusao) FROM {{ this }} AS destino)

{% endif %}