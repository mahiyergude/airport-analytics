{{
    config(
        materialized='table',
        unique_key=['arrival_airport_icao', 'departure_airport_icao', 'flight_date']
    )
}}

with arrivals as (
    select * from {{ ref('stg_airport_arrivals') }}
),

aggregated as (
    select
        -- Airport pair (route)
        arrival_airport_icao,
        departure_airport_icao,
        
        -- Time dimension (aggregated by date)
        cast(first_seen as date) as flight_date,
        
        -- Metrics
        count(*) as flight_count,
        count(distinct icao24) as unique_aircraft,
        count(distinct callsign) as unique_callsigns,
        
        -- Time metrics
        min(first_seen) as earliest_departure,
        max(last_seen) as latest_arrival,
        avg(datediff(minute, first_seen, last_seen)) as avg_flight_duration_minutes,
        
        -- Quality metrics
        avg(arrival_horiz_distance) as avg_arrival_horiz_distance,
        avg(arrival_vert_distance) as avg_arrival_vert_distance,
        
        -- Metadata
        current_timestamp() as created_at
        
    from arrivals
    
    group by 
        arrival_airport_icao,
        departure_airport_icao,
        cast(first_seen as date)
)

select * from aggregated
