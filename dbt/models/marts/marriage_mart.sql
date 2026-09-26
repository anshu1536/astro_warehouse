{{ config(materialized='table', schema='marts') }}

WITH daily AS (

    SELECT
        local_datetime,

        COUNT(*) FILTER (
            WHERE driver_group = 'MARRIAGE_7TH_HOUSE'
        ) AS house_7_signal_groups,

        COUNT(*) FILTER (
            WHERE driver_group = 'MARRIAGE_7TH_LORD'
        ) AS seventh_lord_signal_groups,

        COUNT(*) FILTER (
            WHERE driver_group = 'MARRIAGE_VENUS'
        ) AS venus_signal_groups,

        COUNT(*) FILTER (
            WHERE driver_group = 'MARRIAGE_JUPITER'
        ) AS jupiter_signal_groups

    FROM {{ ref('fct_marriage_signals') }}

    GROUP BY local_datetime

)

SELECT
    local_datetime,

    house_7_signal_groups,
    seventh_lord_signal_groups,
    venus_signal_groups,
    jupiter_signal_groups,

    (
        house_7_signal_groups
        + seventh_lord_signal_groups
        + venus_signal_groups
        + jupiter_signal_groups
    ) AS marriage_signal_groups,

    CASE
        WHEN (
            house_7_signal_groups
            + seventh_lord_signal_groups
            + venus_signal_groups
            + jupiter_signal_groups
        ) >= 3
        THEN 'MARRIAGE_RELEVANT_CONVERGENCE'

        WHEN (
            house_7_signal_groups
            + seventh_lord_signal_groups
            + venus_signal_groups
            + jupiter_signal_groups
        ) >= 2
        THEN 'PARTNERSHIP_COMMITMENT_ACTIVATION'

        WHEN (
            house_7_signal_groups
            + seventh_lord_signal_groups
            + venus_signal_groups
            + jupiter_signal_groups
        ) = 1
        THEN 'MARRIAGE_SINGLE_FACTOR'

        ELSE NULL
    END AS inference_code

FROM daily