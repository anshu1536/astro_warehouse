{{ config(materialized='table', schema='facts') }}

WITH transit_positions AS (

    SELECT
        local_datetime,
        planet_code,
        house
    FROM {{ ref('int_transit_positions') }}

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

    /* ============================================================
       1. 5TH HOUSE
       Romance, attraction, pleasure, erotic expression
       ============================================================ */

    SELECT
        local_datetime,
        'SEX_5H_TRANSIT' AS signal_code,
        'SEX_5TH_HOUSE' AS driver_group,
        planet_code AS driver_planet,
        CAST(NULL AS DOUBLE) AS orb
    FROM transit_positions
    WHERE house = 5
      AND planet_code IN (
          'VENUS',
          'MARS',
          'MOON',
          'JUPITER'
      )


    UNION ALL


    /* ============================================================
       2. 7TH HOUSE
       One-to-one partnership / physical relational expression
       ============================================================ */

    SELECT
        local_datetime,
        'SEX_7H_TRANSIT' AS signal_code,
        'SEX_7TH_HOUSE' AS driver_group,
        planet_code AS driver_planet,
        CAST(NULL AS DOUBLE) AS orb
    FROM transit_positions
    WHERE house = 7
      AND planet_code IN (
          'VENUS',
          'MARS',
          'MOON',
          'JUPITER'
      )


    UNION ALL


    /* ============================================================
       3. 8TH HOUSE
       Intimacy, merging, sexuality, shared/private bonding
       ============================================================ */

    SELECT
        local_datetime,
        'SEX_8H_TRANSIT' AS signal_code,
        'SEX_8TH_HOUSE' AS driver_group,
        planet_code AS driver_planet,
        CAST(NULL AS DOUBLE) AS orb
    FROM transit_positions
    WHERE house = 8
      AND planet_code IN (
          'VENUS',
          'MARS',
          'MOON',
          'JUPITER'
      )


    UNION ALL


    /* ============================================================
       4. Transit Venus -> natal Mars
       Attraction / erotic polarity
       ============================================================ */

    SELECT
        local_datetime,
        'SEX_VENUS_MARS_ASPECT' AS signal_code,
        'SEX_VENUS_MARS' AS driver_group,
        'VENUS' AS driver_planet,
        orb
    FROM aspects
    WHERE transit_planet = 'VENUS'
      AND natal_planet = 'MARS'


    UNION ALL


    /* ============================================================
       5. Transit Mars -> natal Venus
       Attraction / physical activation
       ============================================================ */

    SELECT
        local_datetime,
        'SEX_MARS_VENUS_ASPECT' AS signal_code,
        'SEX_VENUS_MARS' AS driver_group,
        'MARS' AS driver_planet,
        orb
    FROM aspects
    WHERE transit_planet = 'MARS'
      AND natal_planet = 'VENUS'


    UNION ALL


    /* ============================================================
       6. Transit Venus -> natal Venus
       Desire / relational pleasure activation
       ============================================================ */

    SELECT
        local_datetime,
        'SEX_VENUS_VENUS_ASPECT' AS signal_code,
        'SEX_VENUS' AS driver_group,
        'VENUS' AS driver_planet,
        orb
    FROM aspects
    WHERE transit_planet = 'VENUS'
      AND natal_planet = 'VENUS'


    UNION ALL


    /* ============================================================
       7. Transit Mars -> natal Mars
       Physical drive / assertive energy
       ============================================================ */

    SELECT
        local_datetime,
        'SEX_MARS_MARS_ASPECT' AS signal_code,
        'SEX_MARS' AS driver_group,
        'MARS' AS driver_planet,
        orb
    FROM aspects
    WHERE transit_planet = 'MARS'
      AND natal_planet = 'MARS'


    UNION ALL


    /* ============================================================
       8. Transit Venus -> natal Moon
       Emotional affection / sensual bonding
       ============================================================ */

    SELECT
        local_datetime,
        'SEX_VENUS_MOON_ASPECT' AS signal_code,
        'SEX_EMOTIONAL_INTIMACY' AS driver_group,
        'VENUS' AS driver_planet,
        orb
    FROM aspects
    WHERE transit_planet = 'VENUS'
      AND natal_planet = 'MOON'


    UNION ALL


    /* ============================================================
       9. Transit Mars -> natal Moon
       Emotional + physical activation
       ============================================================ */

    SELECT
        local_datetime,
        'SEX_MARS_MOON_ASPECT' AS signal_code,
        'SEX_EMOTIONAL_INTIMACY' AS driver_group,
        'MARS' AS driver_planet,
        orb
    FROM aspects
    WHERE transit_planet = 'MARS'
      AND natal_planet = 'MOON'


    UNION ALL


    /* ============================================================
       10. Jupiter activation of Venus/Mars
       Expansion/amplification of relationship/pleasure signals
       ============================================================ */

    SELECT
        local_datetime,
        'SEX_JUPITER_VENUS_ASPECT' AS signal_code,
        'SEX_JUPITER' AS driver_group,
        'JUPITER' AS driver_planet,
        orb
    FROM aspects
    WHERE transit_planet = 'JUPITER'
      AND natal_planet = 'VENUS'


    UNION ALL

    SELECT
        local_datetime,
        'SEX_JUPITER_MARS_ASPECT' AS signal_code,
        'SEX_JUPITER' AS driver_group,
        'JUPITER' AS driver_planet,
        orb
    FROM aspects
    WHERE transit_planet = 'JUPITER'
      AND natal_planet = 'MARS'


    UNION ALL


    /* ============================================================
       11. Mars / Venus motion modifier
       ============================================================ */

    SELECT
        local_datetime,
        CASE
            WHEN planet_code = 'VENUS'
                THEN 'SEX_VENUS_MOTION'
            WHEN planet_code = 'MARS'
                THEN 'SEX_MARS_MOTION'
        END AS signal_code,
        'SEX_MOTION' AS driver_group,
        planet_code AS driver_planet,
        CAST(NULL AS DOUBLE) AS orb
    FROM motion
    WHERE planet_code IN ('VENUS', 'MARS')
      AND motion_state IN ('RETROGRADE', 'STATIONARY')

)

SELECT DISTINCT
    local_datetime,
    signal_code,
    driver_group,
    driver_planet,
    orb
FROM signals