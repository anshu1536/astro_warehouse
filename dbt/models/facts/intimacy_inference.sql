{{ config(materialized='table', schema='facts') }}

WITH daily AS (

    SELECT
        local_datetime,

        COUNT(*) FILTER (
            WHERE driver_group = 'SEX_5TH_HOUSE'
        ) AS fifth_house_signals,

        COUNT(*) FILTER (
            WHERE driver_group = 'SEX_7TH_HOUSE'
        ) AS seventh_house_signals,

        COUNT(*) FILTER (
            WHERE driver_group = 'SEX_8TH_HOUSE'
        ) AS eighth_house_signals,

        COUNT(*) FILTER (
            WHERE driver_group = 'SEX_VENUS_MARS'
        ) AS venus_mars_signals,

        COUNT(*) FILTER (
            WHERE driver_group = 'SEX_VENUS'
        ) AS venus_signals,

        COUNT(*) FILTER (
            WHERE driver_group = 'SEX_MARS'
        ) AS mars_signals,

        COUNT(*) FILTER (
            WHERE driver_group = 'SEX_EMOTIONAL_INTIMACY'
        ) AS emotional_intimacy_signals,

        COUNT(*) FILTER (
            WHERE driver_group = 'SEX_JUPITER'
        ) AS jupiter_signals,

        COUNT(*) FILTER (
            WHERE driver_group = 'SEX_MOTION'
        ) AS motion_signals,

        COUNT(*) AS total_signal_count

    FROM {{ ref('intimacy_signals') }}

    GROUP BY local_datetime

),

scored AS (

    SELECT
        *,

        (
            fifth_house_signals
            + seventh_house_signals
            + eighth_house_signals
            + venus_mars_signals
            + venus_signals
            + mars_signals
            + emotional_intimacy_signals
            + jupiter_signals
        ) AS intimacy_signal_score

    FROM daily

)

SELECT
    local_datetime,

    fifth_house_signals,
    seventh_house_signals,
    eighth_house_signals,

    venus_mars_signals,
    venus_signals,
    mars_signals,

    emotional_intimacy_signals,
    jupiter_signals,
    motion_signals,

    total_signal_count,
    intimacy_signal_score,

    CASE

        /* Multiple domains simultaneously active */
        WHEN
            (
                CASE WHEN fifth_house_signals > 0 THEN 1 ELSE 0 END
                +
                CASE WHEN seventh_house_signals > 0 THEN 1 ELSE 0 END
                +
                CASE WHEN eighth_house_signals > 0 THEN 1 ELSE 0 END
                +
                CASE WHEN venus_mars_signals > 0 THEN 1 ELSE 0 END
                +
                CASE WHEN emotional_intimacy_signals > 0 THEN 1 ELSE 0 END
            ) >= 3
        THEN 'INTIMACY_CONVERGENCE'

        /* Venus/Mars polarity plus relationship house */
        WHEN
            venus_mars_signals > 0
            AND (
                fifth_house_signals > 0
                OR seventh_house_signals > 0
                OR eighth_house_signals > 0
            )
        THEN 'INTIMACY_ATTRACTION_ACTIVATION'

        /* 8th-house emphasis */
        WHEN
            eighth_house_signals > 0
            AND (
                venus_signals > 0
                OR mars_signals > 0
            )
        THEN 'DEEP_INTIMACY_ACTIVATION'

        /* 5th/7th romantic-physical emphasis */
        WHEN
            (
                fifth_house_signals > 0
                OR seventh_house_signals > 0
            )
            AND venus_mars_signals > 0
        THEN 'PHYSICAL_ATTRACTION_ACTIVATION'

        /* Single Venus/Mars activation */
        WHEN
            venus_mars_signals > 0
            OR venus_signals > 0
            OR mars_signals > 0
        THEN 'INTIMACY_ENERGY_ACTIVATION'

        ELSE NULL

    END AS inference_code

FROM scored