with t as (
  select local_datetime, planet_code, longitude from {{ ref('int_transit_positions') }}
), n as (
  select planet_code as natal_planet, longitude as natal_longitude from {{ ref('int_natal_chart') }}
), pairs as (
  select t.local_datetime, t.planet_code as transit_planet, n.natal_planet,
         least(abs(t.longitude-n.natal_longitude), 360-abs(t.longitude-n.natal_longitude)) as separation
  from t cross join n
), candidates as (
  select *,
    case
      when abs(separation-0) <= 8 then 'conjunction'
      when abs(separation-60) <= 5 then 'sextile'
      when abs(separation-90) <= 7 then 'square'
      when abs(separation-120) <= 7 then 'trine'
      when abs(separation-180) <= 8 then 'opposition'
    end as aspect_type
  from pairs
)
select *,
  case aspect_type
    when 'conjunction' then abs(separation-0)
    when 'sextile' then abs(separation-60)
    when 'square' then abs(separation-90)
    when 'trine' then abs(separation-120)
    when 'opposition' then abs(separation-180)
  end as orb
from candidates where aspect_type is not null
