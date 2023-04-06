{{ config(materialized='table') }}


select 
    stations_id as station_id,
    betreibername as operator_name,
    betrieb_von_datum as dt_op_start,
    betrieb_bis_datum as dt_op_end,
from {{ ref('metadata_operator') }}