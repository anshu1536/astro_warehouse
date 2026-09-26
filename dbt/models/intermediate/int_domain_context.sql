{{ config(materialized='table', schema='intermediate') }}

WITH natal_house AS (

    SELECT
        calculation_id,
        local_datetime,
        cusps_json
    FROM main.raw_houses
    WHERE calculation_type = 'NATAL'
    QUALIFY ROW_NUMBER() OVER (
        ORDER BY local_datetime, calculation_id
    ) = 1

),

cusp_values AS (

    SELECT
        calculation_id,
        local_datetime,

        CAST(json_extract_string(cusps_json, '$[1]') AS DOUBLE) AS cusp_2,
        CAST(json_extract_string(cusps_json, '$[5]') AS DOUBLE) AS cusp_6,
        CAST(json_extract_string(cusps_json, '$[6]') AS DOUBLE) AS cusp_7,
        CAST(json_extract_string(cusps_json, '$[9]') AS DOUBLE) AS cusp_10,
        CAST(json_extract_string(cusps_json, '$[10]') AS DOUBLE) AS cusp_11

    FROM natal_house

),

lord_map AS (

    SELECT 0 AS sign_index, 'MARS' AS lord
    UNION ALL SELECT 1, 'VENUS'
    UNION ALL SELECT 2, 'MERCURY'
    UNION ALL SELECT 3, 'MOON'
    UNION ALL SELECT 4, 'SUN'
    UNION ALL SELECT 5, 'MERCURY'
    UNION ALL SELECT 6, 'VENUS'
    UNION ALL SELECT 7, 'MARS'
    UNION ALL SELECT 8, 'JUPITER'
    UNION ALL SELECT 9, 'SATURN'
    UNION ALL SELECT 10, 'SATURN'
    UNION ALL SELECT 11, 'JUPITER'

),

domain_context AS (

    SELECT
        c.calculation_id,

        c.cusp_2,
        c.cusp_6,
        c.cusp_7,
        c.cusp_10,
        c.cusp_11,

        l2.lord AS second_lord,
        l6.lord AS sixth_lord,
        l7.lord AS seventh_lord,
        l10.lord AS tenth_lord,
        l11.lord AS eleventh_lord

    FROM cusp_values c

    LEFT JOIN lord_map l2
        ON l2.sign_index = CAST(FLOOR(c.cusp_2 / 30.0) AS INTEGER)

    LEFT JOIN lord_map l6
        ON l6.sign_index = CAST(FLOOR(c.cusp_6 / 30.0) AS INTEGER)

    LEFT JOIN lord_map l7
        ON l7.sign_index = CAST(FLOOR(c.cusp_7 / 30.0) AS INTEGER)

    LEFT JOIN lord_map l10
        ON l10.sign_index = CAST(FLOOR(c.cusp_10 / 30.0) AS INTEGER)

    LEFT JOIN lord_map l11
        ON l11.sign_index = CAST(FLOOR(c.cusp_11 / 30.0) AS INTEGER)

)

SELECT *
FROM domain_context