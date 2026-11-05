{{ config(
    materialized='table',
    schema='03_dbt_gold'
) }}

WITH calendar_spine AS (
    {{ date_spine(
        datepart="day",
        start_date="cast('2020-01-01' as date)",
        end_date="cast('2031-01-01' as date)"
    ) }}
),

enriquecido AS (
    SELECT
        c.*,
        f.data AS _feriado_data,
        f.nome_feriado
    FROM calendar_spine AS c
    LEFT JOIN {{ ref('seed_feriados_nacionais') }} AS f
        ON date(c.date_day) = f.data
),

source AS (
    SELECT

        cast(format_date('%Y%m%d', date(date_day)) AS int64) AS sk_data,
        date(date_day) AS dt_data,

        extract(YEAR FROM date_day) AS ano,
        CASE WHEN extract(MONTH FROM date_day) <= 6 THEN 1 ELSE 2 END AS semestre,

        extract(QUARTER FROM date_day) AS trimestre,

        extract(MONTH FROM date_day) AS mes,
        format_date('%Y-%m', date_day) AS ano_mes,
        CASE extract(MONTH FROM date_day)
            WHEN 1 THEN 'Janeiro' WHEN 2 THEN 'Fevereiro' WHEN 3 THEN 'Março'
            WHEN 4 THEN 'Abril' WHEN 5 THEN 'Maio' WHEN 6 THEN 'Junho'
            WHEN 7 THEN 'Julho' WHEN 8 THEN 'Agosto' WHEN 9 THEN 'Setembro'
            WHEN 10 THEN 'Outubro' WHEN 11 THEN 'Novembro' WHEN 12 THEN 'Dezembro'
        END AS nome_mes_pt,

        extract(ISOWEEK FROM date_day) AS semana_ano,
        extract(DAY FROM date_day) AS dia_mes,
        extract(DAYOFWEEK FROM date_day) AS dia_semana_numero,
        CASE extract(DAYOFWEEK FROM date_day)
            WHEN 1 THEN 'Domingo' WHEN 2 THEN 'Segunda-feira' WHEN 3 THEN 'Terça-feira'
            WHEN 4 THEN 'Quarta-feira' WHEN 5 THEN 'Quinta-feira' WHEN 6 THEN 'Sexta-feira'
            WHEN 7 THEN 'Sábado'
        END AS nome_dia_semana_pt,

        coalesce(extract(DAYOFWEEK FROM date_day) IN (1, 7), FALSE)
            AS eh_fim_de_semana,
        NOT coalesce(extract(DAYOFWEEK FROM date_day) IN (1, 7), FALSE) AS eh_dia_util,
        nome_feriado,
        NOT coalesce(
            extract(DAYOFWEEK FROM date_day) IN (1, 7) OR _feriado_data IS NOT NULL, FALSE
        ) AS eh_dia_util_bancario,

        {{ audit_columns() }}

    FROM enriquecido
),


registro_desconhecido AS (
    SELECT
        -1 AS sk_data,
        cast('1900-01-01' AS date) AS dt_data,
        1900 AS ano,
        1 AS semestre,
        1 AS trimestre,
        1 AS mes,
        '1900-01' AS ano_mes,
        'Nao Informado' AS nome_mes_pt,
        1 AS semana_ano,
        1 AS dia_mes,
        1 AS dia_semana_numero,
        'Nao Informado' AS nome_dia_semana_pt,
        FALSE AS eh_fim_de_semana,
        FALSE AS eh_dia_util,
        'Nao Informado' AS nome_feriado,
        FALSE AS eh_dia_util_bancario,
        {{ audit_columns() }}
),

uniao AS (
    SELECT * FROM registro_desconhecido
    UNION ALL
    SELECT * FROM source
)

SELECT *
FROM uniao
