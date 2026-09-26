select * from {{ ref('fct_inference_scd2') }} order by local_datetime
