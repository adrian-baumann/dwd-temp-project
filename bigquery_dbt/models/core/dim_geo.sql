{{ config(materialized='table') }}


select 
    stations_id as station_id,
    stationshoehe as station_height,
    geogr.breite as latitude,
    geogr.laenge as longitude,
    von_datum as dt_geo_start,
    bis_datum as dt_geo_end,
    stationsname as station_name,
from {{ ref('metadata_geo') }}