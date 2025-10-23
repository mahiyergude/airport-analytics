{{
    config(
        materialized='table',
        unique_key=['destination_iata', 'origin_iata', 'shipment_date']
    )
}}

with masters as (
    select * from {{ ref('stg_masters') }}
),

aggregated as (
    select
        -- Route (origin-destination pair)
        destination_iata,
        origin_iata,
        
        -- Time dimension (aggregated by day)
        date_trunc('day', last_seen) as shipment_date,
        
        -- Metrics
        count(distinct master_number) as shipment_count,
        sum(pieces) as total_pieces,
        avg(pieces) as avg_pieces_per_shipment,
        min(pieces) as min_pieces,
        max(pieces) as max_pieces,
        
        -- Time metrics
        min(last_seen) as earliest_shipment,
        max(last_seen) as latest_shipment,
        
        -- Metadata
        current_timestamp() as created_at
        
    from masters
    
    group by
        destination_iata,
        origin_iata,
        date_trunc('day', last_seen)
)

select * from aggregated
