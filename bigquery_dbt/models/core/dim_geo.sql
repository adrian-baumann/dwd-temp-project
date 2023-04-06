{{ config(materialized='table') }}


select 
    cast(stations_id as integer) as station_id,
    cast(stationshoehe as float) as station_height_m,
    cast(geogr.breite as string) as latitude,
    cast(geogr.laenge as string) as longitude,
    cast(von_datum as timestamp) as dt_geo_start,
    cast(bis_datum as timestamp) as dt_geo_end,
    cast(stationsname as string) as station_name,
from {{ ref('metadata_geo') }}