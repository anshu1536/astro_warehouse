select * from {{ ref('fct_inference') }}
where inference_code <> 'BACKGROUND'
order by local_datetime
