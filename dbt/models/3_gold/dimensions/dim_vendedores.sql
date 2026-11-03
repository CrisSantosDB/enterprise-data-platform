WITH
source AS (
    SELECT
        {{ generate_surrogate_key(["id_vendedores"]) }}
            AS sk_vendedores,
        id_vendedores,
        nome,
        {{ audit_columns() }}
    FROM {{ ref("silver_vendedores") }}

),

registro_desconhecido AS (
    SELECT
        '-1' AS sk_vendedores,
        -1 AS id_vendedores,
        'Nao Informado' AS nome,
        {{ audit_columns() }}
),

uniao AS (
    SELECT * FROM registro_desconhecido
    UNION ALL
    SELECT * FROM source
)

SELECT *
FROM uniao
