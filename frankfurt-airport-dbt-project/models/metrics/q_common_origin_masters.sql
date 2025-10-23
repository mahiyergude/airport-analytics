{{
    config(
        materialized='view'
    )
}}

-- What is the most common origin of masters arriving at Frankfurt Airport?

with origin_totals as (
    select
        m.origin_iata,
        a.airport_name as origin_airport_name,
        a.country_code,
        sum(m.total_pieces) as total_pieces,
        sum(m.shipment_count) as total_shipments,
        count(distinct m.shipment_date) as days_active,
        min(m.shipment_date) as first_shipment_date,
        max(m.shipment_date) as last_shipment_date
    from {{ ref('fact_masters') }} m
    left join {{ ref('dim_airport') }} a 
        on m.origin_iata = a.iata
    where m.destination_iata = '{{ var("frankfurt_iata") }}'
    group by 
        m.origin_iata,
        a.airport_name,
        a.country_code
),

ranked_origins as (
    select
        *,
        row_number() over (order by total_pieces desc) as pieces_rank,
        row_number() over (order by total_shipments desc) as shipments_rank,
        row_number() over (order by days_active desc) as days_rank
    from origin_totals
)

select
    origin_iata,
    origin_airport_name,
    country_code,
    total_pieces,
    total_shipments,
    days_active,
    first_shipment_date,
    last_shipment_date,
    pieces_rank,
    shipments_rank,
    days_rank,
    
    -- Derived metrics
    round(total_pieces / nullif(total_shipments, 0), 2) as avg_pieces_per_shipment,
    round(total_pieces / nullif(days_active, 0), 2) as avg_pieces_per_day,
    
    -- Metadata
    '{{ var("frankfurt_iata") }}' as destination_iata,
    current_timestamp() as calculated_at
    
from ranked_origins

-- Return all origins, sorted by pieces (most common first)
order by total_pieces desc
