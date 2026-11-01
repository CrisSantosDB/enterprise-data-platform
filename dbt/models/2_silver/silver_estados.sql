{{ config(unique_key='id_estados') }}

WITH base AS (
    SELECT
        id_estados,
        estado,
        sigla,
        data_inclusao,
        data_atualizacao,
        {{ modification_timestamp_expr() }} AS _source_modified_at
    FROM {{ ref('bronze_estados') }}
    WHERE id_estados IS NOT null

),

source AS (

    SELECT
        id_estados,
        estado,
        sigla,
        data_inclusao,
        data_atualizacao,
        _source_modified_at
    FROM base
    WHERE
        1 = 1
        {{ get_incremental_watermark('_source_modified_at') }}

),

ranked AS (
    SELECT
        id_estados,
        estado,
        sigla,
        data_inclusao,
        data_atualizacao,
        _source_modified_at,
        row_number() OVER (PARTITION BY id_estados ORDER BY _source_modified_at DESC) AS _rn
    FROM source

),

deduplicated AS (
    SELECT
        id_estados,
        estado,
        sigla,
        data_inclusao,
        data_atualizacao,
        _source_modified_at
    FROM ranked
    WHERE _rn = 1
),

enriquecido AS (
    SELECT
        d.id_estados,
        d.estado,
        d.sigla,
        s.regiao,
        s.ordem_regiao,
        d.data_inclusao,
        d.data_atualizacao,
        d._source_modified_at
    FROM deduplicated AS d
    LEFT JOIN {{ ref('seed_regioes_estados') }} AS s
        ON d.sigla = s.sigla
)

SELECT
    id_estados,
    {{ tira_acentos(safe_trim('estado')) }} AS estado,
    {{ normalize_upper('sigla') }} AS sigla,
    {{ safe_trim('regiao') }} AS regiao,
    ordem_regiao,
    data_inclusao,
    data_atualizacao,
    _source_modified_at,
    {{ audit_columns() }}
FROM enriquecido
