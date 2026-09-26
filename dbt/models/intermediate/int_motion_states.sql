select local_datetime, planet_code,
       case when abs(speed_longitude) < 0.02 then 'STATIONARY'
            when speed_longitude < 0 then 'RETROGRADE'
            else 'DIRECT' end as motion_state,
       speed_longitude
from {{ ref('int_transit_positions') }}
