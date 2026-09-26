{{ config(materialized='table', schema='marts') }}

WITH daily AS (

    SELECT
        local_datetime,

        COUNT(*) FILTER (
            WHERE driver_group = 'HEALTH_BODY'
        ) AS body_signals,

        COUNT(*) FILTER (
            WHERE driver_group = 'HEALTH_ROUTINE'
        ) AS routine_signals,

        COUNT(*) FILTER (
            WHERE driver_group = 'HEALTH_BODY_STRESS'
        ) AS body_stress_signals

    FROM {{ ref('fct_health_signals') }}

    GROUP BY local_datetime

)

SELECT
    local_datetime,

    body_signals,
    routine_signals,
    body_stress_signals,

    body_signals
    + routine_signals
    + body_stress_signals AS health_signal_groups,

    CASE

        WHEN body_signals >= 1
         AND body_stress_signals >= 1
        THEN 'BODY_LOAD_ACTIVATION'

        WHEN routine_signals >= 1
        THEN 'WELLNESS_ROUTINE_ACTIVATION'

        WHEN body_signals >= 1
        THEN 'BODY_AWARENESS_ACTIVATION'

        ELSE NULL

    END AS inference_code

FROM daily