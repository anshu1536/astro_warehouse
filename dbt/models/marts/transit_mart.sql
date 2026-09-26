select local_datetime, planet_code, longitude, speed_longitude
from {{ ref('int_transit_positions') }}
order by local_datetime, planet_code
