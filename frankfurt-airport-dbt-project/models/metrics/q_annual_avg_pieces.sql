{{
    config(
        materialized='view'
    )
}}

-- What is the annual average of pieces arriving at Frankfurt Airport?

with yearly_totals as (
    select
        date_trunc('year', shipment_date) as year,
        sum(total_pieces) as total_pieces_in_year,
        count(distinct shipment_date) as days_with_data
    from {{ ref('fact_masters') }}
    where destination_iata = '{{ var("frankfurt_iata") }}'
    group by date_trunc('year', shipment_date)
),

annual_average as (
    select
        count(distinct year) as years_count,
        sum(total_pieces_in_year) as total_pieces_all_years,
        avg(total_pieces_in_year) as annual_avg_pieces,
        min(total_pieces_in_year) as min_year_pieces,
        max(total_pieces_in_year) as max_year_pieces,
        stddev(total_pieces_in_year) as stddev_pieces
    from yearly_totals
)

select
    annual_avg_pieces,
    years_count,
    total_pieces_all_years,
    min_year_pieces,
    max_year_pieces,
    stddev_pieces,
    
    -- Metadata
    '{{ var("frankfurt_iata") }}' as airport_iata,
    current_timestamp() as calculated_at
    
from annual_average
