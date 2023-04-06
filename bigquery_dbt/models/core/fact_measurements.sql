{{ config(materialized='table') }}

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
    measurement.dt_measurement,

    -- weather station info
    dim_geo.station_name,
    dim_operator.operator_name,
    dim_geo.station_height_m,
    dim_geo.latitude,
    dim_geo.longitude,

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
    measurements.mean_temperature_5cm_c_qn4,

from measurements
left join dim_geo as geo
on measurements.station_id = geo.station_id and measurements.dt_measurement between geo.dt_geo_start and geo.dt_geo_end
left join dim_operator as operator
on measurements.station_id = operator.station_id and measurements.dt_measurement between operator.dt_op_start and operator.dt_op_end
