{{ config(unique_key='id_clientes') }}

WITH base AS (
    SELECT
        id_clientes,
        cliente,
        endereco,
        id_concessionarias,
        data_inclusao,
        data_atualizacao,
        {{ modification_timestamp_expr() }} AS _source_modified_at
    FROM {{ ref('bronze_clientes') }}
    WHERE id_clientes IS NOT null
),

source AS (
    SELECT
        id_clientes,
        cliente,
        endereco,
        id_concessionarias,
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
        id_clientes,
        cliente,
        endereco,
        id_concessionarias,
        data_inclusao,
        data_atualizacao,
        _source_modified_at,
        row_number() OVER (PARTITION BY id_clientes ORDER BY _source_modified_at DESC) AS _rn
    FROM source
),

deduplicated AS (
    SELECT
        id_clientes,
        cliente,
        endereco,
        id_concessionarias,
        data_inclusao,
        data_atualizacao,
        _source_modified_at
    FROM ranked
    WHERE _rn = 1
)

SELECT
    id_clientes,
    {{ tira_acentos(safe_trim('cliente')) }} AS cliente,
    {{ tira_acentos(safe_trim('endereco')) }} AS endereco,
    id_concessionarias,
    data_inclusao,
    data_atualizacao,
    _source_modified_at,
    {{ audit_columns() }}
FROM deduplicated
