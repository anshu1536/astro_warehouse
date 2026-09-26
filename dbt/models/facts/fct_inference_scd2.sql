select *,
       local_datetime as valid_from,
       lead(local_datetime) over(partition by inference_code order by local_datetime) as valid_to,
       case when lead(local_datetime) over(partition by inference_code order by local_datetime) is null then true else false end as is_current
from {{ ref('fct_inference') }}
