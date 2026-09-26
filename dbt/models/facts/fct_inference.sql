with s as (select * from {{ ref('fct_signals') }}),
agg as (
 select local_datetime,
   count(distinct driver_group) filter(where signal_code like 'VENUS%') as venus_signal_groups,
   count(distinct driver_group) filter(where signal_code in ('MARS_JUPITER')) as action_signal_groups,
   count(distinct driver_group) filter(where signal_code in ('MERCURY_SATURN','MERCURY_VENUS')) as communication_signal_groups
 from s group by 1
)
select local_datetime,
 case
   when venus_signal_groups >= 2 and communication_signal_groups >= 1 then 'ROMANCE_COMMUNICATION_CONVERGENCE'
   when venus_signal_groups >= 2 then 'RELATIONSHIP_CONVERGENCE'
   when action_signal_groups >= 1 then 'ACTION_ACTIVATION'
   when communication_signal_groups >= 1 then 'COMMUNICATION_ACTIVATION'
   else 'BACKGROUND'
 end as inference_code,
 venus_signal_groups, action_signal_groups, communication_signal_groups
from agg
