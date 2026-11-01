{{ config(unique_key='id_vendedores') }}

WITH base AS (
    SELECT
        id_vendedores,
        nome,
        id_concessionarias,
        data_inclusao,
        data_atualizacao,
        {{ modification_timestamp_expr() }} AS _source_modifiel_at
    FROM {{ ref('bronze_vendedores') }}
    WHERE id_vendedores IS NOT null
),

source AS (
    SELECT
        id_vendedores,
        nome,
        id_concessionarias,
        data_inclusao,
        data_atualizacao,
        _source_modifiel_at
    FROM base
    WHERE
        1 = 1
        {{ get_incremental_watermark('_source_modifiel_at') }}

),

ranked AS (
    SELECT
        id_vendedores,
        nome,
        id_concessionarias,
        data_inclusao,
        data_atualizacao,
        _source_modifiel_at,
        row_number() OVER (PARTITION BY id_vendedores ORDER BY _source_modifiel_at DESC) AS _rn
    FROM source
),

deduplicated AS (

    SELECT
        id_vendedores,
        nome,
        id_concessionarias,
        data_inclusao,
        data_atualizacao,
        _source_modifiel_at

    FROM ranked
    WHERE _rn = 1
)

SELECT
    id_vendedores,
    {{ tira_acentos(safe_trim('nome')) }} AS nome,
    id_concessionarias,
    data_inclusao,
    data_atualizacao,
    _source_modifiel_at,
    {{ audit_columns() }}

FROM deduplicated
