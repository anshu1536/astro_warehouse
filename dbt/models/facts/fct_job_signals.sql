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

    -- 10th house activation
    SELECT
        local_datetime,
        'JOB_10H_TRANSIT' AS signal_code,
        'JOB_10TH_HOUSE' AS driver_group,
        CAST(NULL AS DOUBLE) AS orb
    FROM transits
    WHERE house = 10

    UNION ALL

    -- 6th house activation
    SELECT
        local_datetime,
        'JOB_6H_TRANSIT' AS signal_code,
        'JOB_6TH_HOUSE' AS driver_group,
        CAST(NULL AS DOUBLE) AS orb
    FROM transits
    WHERE house = 6

    UNION ALL

    -- Transit to 10th lord
    SELECT
        a.local_datetime,
        'JOB_10LORD_ASPECT' AS signal_code,
        'JOB_10TH_LORD' AS driver_group,
        a.orb
    FROM aspects a
    CROSS JOIN ctx c
    WHERE a.natal_planet = c.tenth_lord

    UNION ALL

    -- Transit to 6th lord
    SELECT
        a.local_datetime,
        'JOB_6LORD_ASPECT' AS signal_code,
        'JOB_6TH_LORD' AS driver_group,
        a.orb
    FROM aspects a
    CROSS JOIN ctx c
    WHERE a.natal_planet = c.sixth_lord

    UNION ALL

    -- Income / earnings axis
    SELECT
        a.local_datetime,
        'JOB_2LORD_ASPECT' AS signal_code,
        'JOB_2ND_LORD' AS driver_group,
        a.orb
    FROM aspects a
    CROSS JOIN ctx c
    WHERE a.natal_planet = c.second_lord

    UNION ALL

    SELECT
        a.local_datetime,
        'JOB_11LORD_ASPECT' AS signal_code,
        'JOB_11TH_LORD' AS driver_group,
        a.orb
    FROM aspects a
    CROSS JOIN ctx c
    WHERE a.natal_planet = c.eleventh_lord

)

SELECT DISTINCT *
FROM signals