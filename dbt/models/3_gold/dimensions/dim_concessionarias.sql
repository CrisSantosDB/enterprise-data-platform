WITH source AS (
    SELECT
        {{ generate_surrogate_key(['id_concessionarias']) }}
            AS sk_concessionarias,
        s.id_concessionarias,
        s.concessionaria,
        c.cidade,
        e.estado,
        e.sigla,
        e.regiao,
        {{ audit_columns() }}
    FROM {{ ref('silver_concessionarias') }} AS s
    LEFT JOIN {{ ref('silver_cidades') }} AS c
        ON s.id_cidades = c.id_cidades
    LEFT JOIN {{ ref('silver_estados') }} AS e
        ON c.id_estados = e.id_estados

),

registro_desconhecido AS (
    SELECT
        '-1' AS sk_concessionarias,
        -1 AS id_concessionarias,
        'Não Informado' AS concessionaria,
        'Não Informado' AS cidade,
        'Não Informado' AS estado,
        'ND' AS sigla,
        'Não Informado' AS regiao,
        {{ audit_columns() }}
),

uniao AS (
    SELECT * FROM registro_desconhecido
    UNION ALL
    SELECT * FROM source
)

SELECT * FROM uniao
