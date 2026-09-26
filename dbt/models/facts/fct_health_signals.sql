{{ config(materialized='table', schema='facts') }}

WITH transits AS (

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

motion AS (

    SELECT
        local_datetime,
        planet_code,
        motion_state
    FROM {{ ref('int_motion_states') }}

),

signals AS (

    -- Body / physical self axis
    SELECT
        local_datetime,
        'HEALTH_1H_TRANSIT' AS signal_code,
        'HEALTH_BODY' AS driver_group,
        CAST(NULL AS DOUBLE) AS orb
    FROM transits
    WHERE house = 1

    UNION ALL

    -- Routine / health-maintenance axis
    SELECT
        local_datetime,
        'HEALTH_6H_TRANSIT' AS signal_code,
        'HEALTH_ROUTINE' AS driver_group,
        CAST(NULL AS DOUBLE) AS orb
    FROM transits
    WHERE house = 6

    UNION ALL

    -- Traditional body/stress indicators
    SELECT
        a.local_datetime,
        'HEALTH_BODY_PLANET_ASPECT' AS signal_code,
        'HEALTH_BODY_STRESS' AS driver_group,
        a.orb
    FROM aspects a
    WHERE a.natal_planet IN (
        'SUN',
        'MOON',
        'MARS',
        'SATURN'
    )

    UNION ALL

    -- Retrograde/direct state as a routine/review modifier
    SELECT
        local_datetime,
        'HEALTH_MOTION_REVIEW' AS signal_code,
        'HEALTH_ROUTINE' AS driver_group,
        CAST(NULL AS DOUBLE) AS orb
    FROM motion
    WHERE motion_state IN ('RETROGRADE', 'STATIONARY')

)

SELECT DISTINCT *
FROM signals