{{ config(materialized='view') }}

with temperature_data as 
(
  select *,
    row_number() over(partition by station_id, mess_datum) as rn
  from {{ source('staging','temperatures_all') }}
  where station_id is not null 
)
select
    -- identifiers
    {{ dbt_utils.generate_surrogate_key(['station_id', 'mess_datum']) }} as measurement_id,
    cast(station_ids as integer) as station_id,

    -- timestamp
    cast(mess_datum as integer) as dt_measurement,
    
    -- measurement quality level
    cast(qn_3 as integer) as qn3,
    cast(qn_4 as integer) as qn4,
    
    -- measurements
    cast(fx as float) as max_wind_gust_mps,
    cast(fm  as integer) as mean_wind_velocity_mps,
    cast(rsk as float) as precipitation_heigt_mm,
    cast(rskf  as integer) as precipitation_type,
    cast(sdk as integer) as sunshine_duration_h,
    cast(shk_tag as integer) as snow_height_cm,
    cast(nm as string) as mean_cloud_coverage,
    cast(vpa as string) as mean_vapour_pressure_hpa,
    cast(pa as string) as mean_pressure_hpa,
    cast(tmk as float) as mean_temperature_2m_c,
    cast(upm as float) as mean_rel_humidity_,
    cast(txk as float) as max_temperature_2m_c,
    cast(tnk as float) as min_temperature_2m_c,
    cast(tgk as float) as mean_temperature_5cm_c,
from temperature_data
where rn = 1

-- dbt build --m <model.sql> --var 'is_test_run: false'
{% if var('is_test_run', default=false) %}

  limit 100

{% endif %}
