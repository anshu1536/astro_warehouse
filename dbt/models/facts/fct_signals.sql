with a as (select * from {{ ref('int_aspects') }}),
m as (select * from {{ ref('int_motion_states') }}),
base as (
  select local_datetime, 'MERCURY_SATURN' as signal_code, 'MERCURY_SATURN' as driver_group, orb
  from a where transit_planet='MERCURY' and natal_planet='SATURN' and aspect_type='square'
  union all
  select local_datetime, 'VENUS_JUPITER', 'VENUS_JUPITER', orb
  from a where transit_planet='VENUS' and natal_planet='JUPITER' and aspect_type='square'
  union all
  select local_datetime, 'VENUS_MOON', 'VENUS_MOON', orb
  from a where transit_planet='VENUS' and natal_planet='MOON' and aspect_type='trine'
  union all
  select local_datetime, 'VENUS_SATURN', 'VENUS_SATURN', orb
  from a where transit_planet='VENUS' and natal_planet='SATURN' and aspect_type='square'
  union all
  select local_datetime, 'MERCURY_VENUS', 'MERCURY_VENUS', orb
  from a where transit_planet='MERCURY' and natal_planet='VENUS' and aspect_type='trine'
  union all
  select local_datetime, 'MARS_JUPITER', 'MARS_JUPITER', orb
  from a where transit_planet='MARS' and natal_planet='JUPITER' and aspect_type='conjunction'
  union all
  select local_datetime, 'VENUS_STATION', 'VENUS_MOTION', 0.0
  from m where planet_code='VENUS' and motion_state='STATIONARY'
  union all
  select local_datetime, 'VENUS_RETROGRADE', 'VENUS_MOTION', 0.0
  from m where planet_code='VENUS' and motion_state='RETROGRADE'
)
select * from base
