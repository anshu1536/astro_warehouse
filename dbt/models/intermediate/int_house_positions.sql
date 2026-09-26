select local_datetime, planet_code, longitude, house
from {{ ref('stg_house_positions') }}
