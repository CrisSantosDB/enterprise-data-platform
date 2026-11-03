WITH source AS (
    SELECT
        {{ generate_surrogate_key(['id_veiculos']) }}
            AS sk_veiculos,
        id_veiculos,
        nome,
        tipo,
        categoria_veiculo,
        segmento_veiculo,
        {{ audit_columns() }}
    FROM {{ ref('silver_veiculos') }}

),

registro_desconhecido AS (
    SELECT
        '-1' AS sk_veiculos,
        -1 AS id_veiculos,
        'Nao Informado' AS nome,
        'Nao Informado' AS tipo,
        'Nao Informado' AS categoria_veiculo,
        'Nao Informado' AS segmento_veiculo,
        {{ audit_columns() }}

),

uniao AS (
    SELECT * FROM registro_desconhecido
    UNION ALL
    SELECT * FROM source
)


SELECT * FROM uniao
