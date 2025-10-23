{{
    config(
        materialized='view'
    )
}}

with source as (
    select * from {{ source('raw', 'RAW_AIRPORT_ARRIVALS') }}
),

cleaned as (
    select
        -- Aircraft identifier
        lower(trim(ICAO24)) as icao24,
        
        -- Timestamps
        cast(FIRST_SEEN as timestamp_ntz) as first_seen,
        cast(LAST_SEEN as timestamp_ntz) as last_seen,
        
        -- Airport codes (standardized to uppercase)
        upper(trim(EST_DEPARTURE_AIRPORT)) as departure_airport_icao,
        upper(trim(EST_ARRIVAL_AIRPORT)) as arrival_airport_icao,
        
        -- Flight details
        trim(CALLSIGN) as callsign,
        
        -- Distance metrics
        EST_DEPARTURE_AIRPORT_HORIZ_DISTANCE as departure_horiz_distance,
        EST_DEPARTURE_AIRPORT_VERT_DISTANCE as departure_vert_distance,
        EST_ARRIVAL_AIRPORT_HORIZ_DISTANCE as arrival_horiz_distance,
        EST_ARRIVAL_AIRPORT_VERT_DISTANCE as arrival_vert_distance,
        
        -- Candidate counts
        DEPARTURE_AIRPORT_CANDIDATES_COUNT as departure_candidates_count,
        ARRIVAL_AIRPORT_CANDIDATES_COUNT as arrival_candidates_count
        
        
    from source
    
    -- Data quality filters
    where
        ICAO24 is not null
        and EST_ARRIVAL_AIRPORT is not null
        and FIRST_SEEN is not null
        and LAST_SEEN is not null
        and LAST_SEEN >= FIRST_SEEN  -- Arrival must be after departure
)

select * from cleaned
