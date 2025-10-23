{{
    config(
        materialized='view'
    )
}}

with source as (
    select * from {{ source('raw', 'RAW_MASTER') }}
),

cleaned as (
    select
        -- Shipment identifiers
        trim(MASTER_NUMBER) as master_number,
        
        -- Airport codes (standardized to uppercase)
        upper(trim(ORIGIN)) as origin_iata,
        upper(trim(DESTINATION)) as destination_iata,
        
        -- Metrics
        PIECES as pieces,
        
        -- Timestamps
        cast(LAST_SEEN as timestamp_ntz) as last_seen
        
    from source
    
    -- Data quality filters
    where 
        MASTER_NUMBER is not null
        and ORIGIN is not null
        and DESTINATION is not null
        and PIECES is not null
        and PIECES > 0  -- Shipments must have at least 1 piece
        and LAST_SEEN is not null
)

select * from cleaned
