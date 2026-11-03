WITH source AS (

    SELECT
        {{ generate_surrogate_key(['id_clientes']) }}
            AS sk_clientes,
        id_clientes,
        cliente,
        endereco,
        {{ audit_columns() }}
    FROM {{ ref('silver_clientes') }}

),

registro_desconhecido AS (
    SELECT
        '-1' AS sk_clientes,
        1 AS id_clientes,
        'Nao Informado' AS cliente,
        'Nao Informado' AS endereco,
        {{ audit_columns() }}

),

uniao AS (

    SELECT * FROM registro_desconhecido
    UNION ALL
    SELECT * FROM source
)


SELECT *
FROM uniao
