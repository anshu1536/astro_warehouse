{{ config(materialized='table', schema='facts') }}

WITH ctx AS (

    SELECT *
    FROM {{ ref('int_domain_context') }}

),

transits AS (

    SELECT
        local_datetime,
        planet_code,
        house
    FROM {{ ref('int_transit_positions') }}
    WHERE planet_code IN (
        'SUN',
        'MOON',
        'MERCURY',
        'VENUS',
        'MARS',
        'JUPITER',
        'SATURN'
    )

),

aspects AS (

    SELECT
        local_datetime,
        transit_planet,
        natal_planet,
        aspect_type,
        orb
    FROM {{ ref('int_aspects') }}

),

signals AS (

    -- Transit planet in natal 7th house
    SELECT
        t.local_datetime,
        CASE
            WHEN t.planet_code IN ('VENUS', 'JUPITER')
                THEN 'MARRIAGE_7H_BENEFIC_TRANSIT'
            ELSE 'MARRIAGE_7H_TRANSIT'
        END AS signal_code,
        'MARRIAGE_7TH_HOUSE' AS driver_group,
        CAST(NULL AS DOUBLE) AS orb
    FROM transits t
    WHERE t.house = 7

    UNION ALL

    -- Transit to natal 7th lord
    SELECT
        a.local_datetime,
        'MARRIAGE_7LORD_ASPECT' AS signal_code,
        'MARRIAGE_7TH_LORD' AS driver_group,
        a.orb
    FROM aspects a
    CROSS JOIN ctx c
    WHERE a.natal_planet = c.seventh_lord

    UNION ALL

    -- Transit to natal Venus
    SELECT
        a.local_datetime,
        'MARRIAGE_VENUS_ASPECT' AS signal_code,
        'MARRIAGE_VENUS' AS driver_group,
        a.orb
    FROM aspects a
    WHERE a.natal_planet = 'VENUS'

    UNION ALL

    -- Transit to natal Jupiter
    SELECT
        a.local_datetime,
        'MARRIAGE_JUPITER_ASPECT' AS signal_code,
        'MARRIAGE_JUPITER' AS driver_group,
        a.orb
    FROM aspects a
    WHERE a.natal_planet = 'JUPITER'

)

SELECT DISTINCT
    local_datetime,
    signal_code,
    driver_group,
    orb
FROM signals