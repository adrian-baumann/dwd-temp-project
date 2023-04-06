{{ config(materialized='table') }}


select 
    cast(stations_id as integer) as station_id,
    cast(betreibername as string) as operator_name,
    cast(betrieb_von_datum as timestamp) as dt_op_start,
    cast(betrieb_bis_datum as timestamp) as dt_op_end,
from {{ ref('metadata_operator') }}