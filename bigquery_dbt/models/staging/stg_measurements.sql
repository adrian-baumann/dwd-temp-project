{{ config(materialized='view') }}

with temperature_data as 
(
  select *,
    row_number() over(partition by station_id, mess_datum) as _rn
  from {{ source('staging','temperatures_all') }}
  where station_id is not null 
)
select
    -- identifiers
    {{ dbt_utils.generate_surrogate_key(['station_id', 'mess_datum']) }} as measurement_id,
    cast(station_ids as integer) as station_id,

    -- timestamp
    cast(mess_datum as timestamp) as dt_measurement,
    
    -- measurement quality level
    cast(qn_3 as integer) as quality_niveau_3,
    cast(qn_4 as integer) as quality_niveau_4,
    
    -- measurements
    cast(fx as float) as max_wind_gust_mps_qn3,
    cast(fm  as integer) as mean_wind_velocity_mps_qn3,
    cast(rsk as float) as precipitation_heigt_mm_qn4,
    cast(rskf  as integer) as precipitation_type_qn4,
    cast(sdk as integer) as sunshine_duration_h_qn4,
    cast(shk_tag as integer) as snow_depth_cm_qn4,
    cast(nm as string) as mean_cloud_coverage_qn4,
    cast(vpa as float) as mean_vapour_pressure_hpa_qn4,
    cast(pa as float) as mean_pressure_hpa_qn4,
    cast(tmk as float) as mean_temperature_2m_c_qn4,
    cast(upm as float) as mean_rel_humidity_qn4,
    cast(txk as float) as max_temperature_2m_c_qn4,
    cast(tnk as float) as min_temperature_2m_c_qn4,
    cast(tgk as float) as mean_temperature_5cm_c_qn4,
from temperature_data
where _rn = 1

-- dbt build --m <model.sql> --var 'is_test_run: false'
{% if var('is_test_run', default=false) %}

  limit 100

{% endif %}
