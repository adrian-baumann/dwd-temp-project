{{
 config(
   materialized = 'table',
   cluster_by = ["dt_measurement_utc"],
   partition_by = {
     'field': 'dt_measurement_utc', 
     'data_type': 'timestamp',
     'granularity': 'month',
   }
 )
}}

with measurements as (
    select *
    from {{ ref('stg_measurements') }}
), 

dim_geo as (
    select * from {{ ref('dim_geo') }}
),

dim_operator as (
    select * from {{ ref('dim_operator') }}
)
select
    -- ids
    measurements.measurement_id,
    measurements.station_id,

    -- timestamp
    measurements.dt_measurement_utc,

    -- weather station info
    geo.station_name,
    operator.operator_name,
    geo.station_height_m,
    concat(geo.latitude, ",", geo.longitude) as lat_long,

    -- measurement quality
    measurements.quality_niveau_3,
    measurements.quality_niveau_4,

    -- measurement results
    measurements.max_wind_gust_mps_qn3,
    measurements.mean_wind_velocity_mps_qn3,
    measurements.precipitation_heigt_mm_qn4,
    measurements.precipitation_type_qn4,
    measurements.sunshine_duration_h_qn4,
    measurements.snow_depth_cm_qn4,
    measurements.mean_cloud_coverage_qn4,
    measurements.mean_vapour_pressure_hpa_qn4,
    measurements.mean_pressure_hpa_qn4,
    measurements.mean_temperature_2m_c_qn4,
    measurements.mean_rel_humidity_qn4,
    measurements.max_temperature_2m_c_qn4,
    measurements.min_temperature_2m_c_qn4,
    measurements.mean_temperature_5cm_c_qn4

from measurements
left join dim_geo as geo
    on measurements.station_id = geo.station_id 
    and measurements.dt_measurement_utc >= geo.dt_geo_start 
    and (
        geo.dt_geo_end is null
        or
        measurements.dt_measurement_utc <= geo.dt_geo_end
    )
left join dim_operator as operator
    on measurements.station_id = operator.station_id 
    and measurements.dt_measurement_utc >= operator.dt_op_start 
    and (
        operator.dt_op_end is null
        or
        measurements.dt_measurement_utc <= operator.dt_op_end
    )
