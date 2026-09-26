with x as (
  select *,
    case when lead(local_datetime) over(partition by driver_group order by local_datetime) is null then true else false end as is_current,
    local_datetime as valid_from,
    lead(local_datetime) over(partition by driver_group order by local_datetime) as valid_to
  from {{ ref('fct_signals') }}
)
select * from x
