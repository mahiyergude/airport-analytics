{{
    config(
        materialized='view'
    )
}}

-- What is the monthly average of flights arriving at Frankfurt Airport?

with monthly_totals as (
    select
        date_trunc('month', flight_date) as month,
        sum(flight_count) as total_flights_in_month,
        count(distinct flight_date) as days_with_data
    from {{ ref('fact_arrivals') }}
    where arrival_airport_icao = '{{ var("frankfurt_icao") }}'
    group by date_trunc('month', flight_date)
),

monthly_average as (
    select
        count(distinct month) as months_count,
        sum(total_flights_in_month) as total_flights_all_months,
        avg(total_flights_in_month) as monthly_avg_flights,
        min(total_flights_in_month) as min_month_flights,
        max(total_flights_in_month) as max_month_flights,
        stddev(total_flights_in_month) as stddev_flights
    from monthly_totals
)

select
    monthly_avg_flights,
    months_count,
    total_flights_all_months,
    min_month_flights,
    max_month_flights,
    stddev_flights,
    
    -- Metadata
    '{{ var("frankfurt_icao") }}' as airport_icao,
    current_timestamp() as calculated_at
    
from monthly_average
