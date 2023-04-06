{{ config(materialized='view') }}

with temperature_data as 
(
  select *,
    row_number() over(partition by stations_id, mess_datum) as _rn
  from {{ source('staging','temperatures_all') }}
  where stations_id is not null and mess_datum is not null 
)
select
    -- identifiers
    {{ dbt_utils.generate_surrogate_key(['stations_id', 'mess_datum']) }} as measurement_id,
    cast(stations_id as string) as station_id,

    -- timestamp
    cast(mess_datum as timestamp) as dt_measurement_utc,
    
    -- measurement quality level
    cast(qn_3 as integer) as quality_niveau_3,
    cast(qn_4 as integer) as quality_niveau_4,
    
    -- measurements
    round(cast(fx as float64), 2) as max_wind_gust_mps_qn3,
    round(cast(fm  as float64), 2) as mean_wind_velocity_mps_qn3,
    round(cast(rsk as float64), 2) as precipitation_heigt_mm_qn4,
    cast(rskf  as integer) as precipitation_type_qn4,
    cast(sdk as integer) as sunshine_duration_h_qn4,
    cast(shk_tag as integer) as snow_depth_cm_qn4,
    cast(nm as string) as mean_cloud_coverage_qn4,
    round(cast(vpm as float64), 2) as mean_vapour_pressure_hpa_qn4,
    round(cast(pm as float64), 2) as mean_pressure_hpa_qn4,
    round(cast(tmk as float64), 2) as mean_temperature_2m_c_qn4,
    round(cast(upm as float64), 2) as mean_rel_humidity_qn4,
    round(cast(txk as float64), 2) as max_temperature_2m_c_qn4,
    round(cast(tnk as float64), 2) as min_temperature_2m_c_qn4,
    round(cast(tgk as float64), 2) as mean_temperature_5cm_c_qn4,
from temperature_data
where _rn = 1

-- dbt build --m <model.sql> --var 'is_test_run: false'
{% if var('is_test_run', default=false) %}

  limit 100

{% endif %}
