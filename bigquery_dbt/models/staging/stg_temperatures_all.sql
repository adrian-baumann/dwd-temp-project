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
    cast(rsk as float) as precipitation_heigt_mm,
    cast(rskf  as integer) as precipitation_type,
    cast(shk_tag as integer) as snow_height_cm,
    cast(nm as string) as cloud_coverage_mean,
    cast(rsk as float) as precipitation_heigt_um,
    cast(rsk as float) as precipitation_heigt_um,
    cast(rsk as float) as precipitation_heigt_um,
from tripdata
where rn = 1

"STATIONS_ID",
            "QN_3",
            "  FX",
            "  FM",
            "QN_4",
            " RSK",
            "RSKF",
            " SDK",
            "SHK_TAG",
            "  NM",
            " VPM",
            "  PM",
            " TMK",
            " UPM",
            " TXK",
            " TNK",
            " TGK",


-- dbt build --m <model.sql> --var 'is_test_run: false'
{% if var('is_test_run', default=false) %}

  limit 100

{% endif %}
