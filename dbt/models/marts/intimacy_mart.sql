{{ config(materialized='table', schema='marts') }}

WITH source_data AS (

    SELECT *
    FROM {{ ref('intimacy_inference') }}

)

SELECT

    local_datetime,

    inference_code,

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
        WHEN intimacy_signal_score >= 5 THEN 5
        WHEN intimacy_signal_score = 4 THEN 4
        WHEN intimacy_signal_score = 3 THEN 3
        WHEN intimacy_signal_score = 2 THEN 2
        WHEN intimacy_signal_score = 1 THEN 1
        ELSE 0
    END AS intimacy_strength

FROM source_data