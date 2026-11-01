{{ config(unique_key='id_veiculos') }}
WITH
base AS (
    SELECT
        id_veiculos,
        nome,
        tipo,
        valor AS valor_tabela,
        data_atualizacao,
        data_inclusao,
        {{ modification_timestamp_expr() }} AS _source_modifiel_at
    FROM {{ ref('bronze_veiculos') }}
    WHERE id_veiculos IS NOT null
),

source AS (
    SELECT
        id_veiculos,
        nome,
        tipo,
        valor_tabela,
        data_atualizacao,
        data_inclusao,
        _source_modifiel_at
    FROM base
    WHERE
        1 = 1
        {{ get_incremental_watermark('_source_modifiel_at') }}
),

ranked AS (
    SELECT
        id_veiculos,
        nome,
        tipo,
        valor_tabela,
        data_atualizacao,
        data_inclusao,
        _source_modifiel_at,
        row_number() OVER (PARTITION BY id_veiculos ORDER BY _source_modifiel_at DESC) AS _rn
    FROM source
),

deduplicated AS (
    SELECT
        id_veiculos,
        nome,
        tipo,
        valor_tabela,
        data_atualizacao,
        data_inclusao,
        _source_modifiel_at

    FROM ranked
    WHERE _rn = 1
),

enriquecido_tipos AS (
    SELECT
        t.id_veiculos,
        t.nome,
        t.tipo,
        t.valor_tabela,
        t.data_atualizacao,
        t.data_inclusao,
        t._source_modifiel_at,
        coalesce(s.tipo_padronizado, t.tipo) AS tipo_padronizado,
        coalesce(s.categoria, 'Outros') AS categoria_veiculo

    FROM deduplicated AS t
    LEFT JOIN {{ ref('seed_tipos_veiculos') }} AS s
        ON t.tipo = s.tipo_origem
),

enriquecido_segmentos AS (

    SELECT
        e.id_veiculos,
        e.nome,
        e.tipo,
        e.tipo_padronizado,
        e.categoria_veiculo,
        e.valor_tabela,
        e.data_atualizacao,
        e.data_inclusao,
        e._source_modifiel_at,
        coalesce(s.segmento, 'Não Informado') AS segmento_veiculo,
        coalesce(s.ordem_segmento, 0) AS ordem_segmento

    FROM enriquecido_tipos AS e
    LEFT JOIN {{ ref('seed_segmentos_veiculos') }} AS s
        ON e.valor_tabela = s.valor_maximo

)


SELECT
    id_veiculos,
    {{ tira_acentos(safe_trim('nome')) }} AS nome,
    {{ tira_acentos(normalize_upper('tipo')) }} AS tipo,
    {{ tira_acentos(normalize_upper('tipo_padronizado')) }} AS tipo_padronizado,
    categoria_veiculo,
    valor_tabela,
    segmento_veiculo,
    ordem_segmento,
    data_atualizacao,
    data_inclusao,
    _source_modifiel_at,
    {{ audit_columns() }}

FROM enriquecido_segmentos
