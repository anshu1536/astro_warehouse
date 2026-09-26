{{ config(materialized='table', schema='marts') }}

WITH daily AS (

    SELECT
        local_datetime,

        COUNT(*) FILTER (
            WHERE driver_group = 'JOB_10TH_HOUSE'
        ) AS tenth_house_signals,

        COUNT(*) FILTER (
            WHERE driver_group = 'JOB_6TH_HOUSE'
        ) AS sixth_house_signals,

        COUNT(*) FILTER (
            WHERE driver_group = 'JOB_10TH_LORD'
        ) AS tenth_lord_signals,

        COUNT(*) FILTER (
            WHERE driver_group = 'JOB_6TH_LORD'
        ) AS sixth_lord_signals,

        COUNT(*) FILTER (
            WHERE driver_group IN ('JOB_2ND_LORD', 'JOB_11TH_LORD')
        ) AS income_axis_signals

    FROM {{ ref('fct_job_signals') }}

    GROUP BY local_datetime

)

SELECT
    local_datetime,

    tenth_house_signals,
    sixth_house_signals,
    tenth_lord_signals,
    sixth_lord_signals,
    income_axis_signals,

    (
        tenth_house_signals
        + tenth_lord_signals
        + sixth_house_signals
        + sixth_lord_signals
    ) AS career_signal_groups,

    CASE

        WHEN
            tenth_house_signals
            + tenth_lord_signals
            + sixth_house_signals
            + sixth_lord_signals >= 3
        THEN 'CAREER_ACTIVATION'

        WHEN
            tenth_house_signals
            + tenth_lord_signals >= 2
        THEN 'CAREER_FOCUS_ACTIVATION'

        WHEN
            income_axis_signals >= 1
        THEN 'CAREER_INCOME_ACTIVATION'

        ELSE NULL

    END AS inference_code

FROM daily