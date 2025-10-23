{{
    config(
        materialized='view'
    )
}}

with source as (
    select * from {{ source('raw', 'RAW_AIRPORTS_IATA_ICAO') }}
),

cleaned as (
    select
        -- Standardize airport codes to uppercase, handle nulls
        upper(nullif(trim(IATA), '')) as iata,
        upper(nullif(trim(ICAO), '')) as icao,
        
        -- Airport details
        trim(AIRPORT) as airport_name,
        upper(trim(COUNTRY_CODE)) as country_code,

        trim(REGION_NAME) as region_name,
        
        -- Geographic coordinates
        LATITUDE as latitude,
        LONGITUDE as longitude
        
       
        
    from source
    
    -- Data quality: must have at least one airport code
    where IATA is not null or ICAO is not null
)

select * from cleaned
