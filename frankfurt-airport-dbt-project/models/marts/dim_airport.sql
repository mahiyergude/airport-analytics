{{
    config(
        materialized='table',
        unique_key='airport_code'
    )
}}

with airports as (
    select * from {{ ref('stg_airports') }}
),

final as (
    select
        -- Use ICAO as primary code, fall back to IATA if ICAO is null
        coalesce(icao, iata) as airport_code,
        
        -- Both code types for flexibility
        iata,
        icao,
        
        -- Airport details
        airport_name,
        country_code,
        region_name,
        
        -- Geographic coordinates
        latitude,
        longitude,
        
        -- Metadata
        current_timestamp() as created_at
        
    from airports
    
    -- Deduplicate if needed (prefer records with both codes)
    qualify row_number() over (
        partition by coalesce(icao, iata)
        order by 
            case when icao is not null and iata is not null then 1 else 2 end,
            airport_name
    ) = 1
)

select * from final
