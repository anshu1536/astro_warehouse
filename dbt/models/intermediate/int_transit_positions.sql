select * from {{ ref('stg_ephemeris') }} where calculation_type = 'TRANSIT'
