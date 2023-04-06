{{ config(materialized='table') }}


select 
    cast(stations_id as string) as station_id,
    cast(stationshoehe as float64) as station_height_m,
    cast(geogr_breite as string) as latitude,
    cast(geogr_laenge as string) as longitude,
    cast(von_datum as timestamp) as dt_geo_start,
    cast(bis_datum as timestamp) as dt_geo_end,
    cast(stationsname as string) as station_name,
from {{ source('core' ,'metadata_geo') }}