-- Ad-hoc Analysis Queries for Frankfurt Airport

-- 1. Daily shipment volumes to Frankfurt
SELECT 
    shipment_date,
    SUM(total_pieces) as daily_pieces,
    SUM(shipment_count) as daily_shipments,
    AVG(avg_pieces_per_shipment) as avg_size
FROM {{ ref('fact_masters') }}
WHERE destination_iata = 'FRA'
GROUP BY shipment_date
ORDER BY shipment_date DESC
LIMIT 30;

-- 2. Top 20 routes by flight volume
SELECT 
    dep.airport_name as origin_airport,
    dep.country_code as origin_country,
    arr.airport_name as destination_airport,
    SUM(f.flight_count) as total_flights,
    AVG(f.avg_flight_duration_minutes) as avg_duration_min
FROM {{ ref('fact_arrivals') }} f
LEFT JOIN {{ ref('dim_airport') }} dep ON f.departure_airport_icao = dep.icao
LEFT JOIN {{ ref('dim_airport') }} arr ON f.arrival_airport_icao = arr.icao
WHERE f.arrival_airport_icao = 'EDDF'
GROUP BY 1, 2, 3
ORDER BY total_flights DESC
LIMIT 20;

-- 3. Monthly trends - shipments vs flights
SELECT 
    DATE_TRUNC('month', m.shipment_date) as month,
    SUM(m.total_pieces) as total_pieces,
    SUM(m.shipment_count) as total_shipments,
    SUM(f.flight_count) as total_flights,
    SUM(m.total_pieces) / NULLIF(SUM(f.flight_count), 0) as pieces_per_flight
FROM {{ ref('fact_masters') }} m
LEFT JOIN {{ ref('fact_arrivals') }} f 
    ON DATE_TRUNC('month', m.shipment_date) = DATE_TRUNC('month', f.flight_date)
    AND f.arrival_airport_icao = 'EDDF'
WHERE m.destination_iata = 'FRA'
GROUP BY 1
ORDER BY 1;

-- 4. Geographic distribution of shipment origins
SELECT 
    a.region_name,
    a.country_code,
    COUNT(DISTINCT m.origin_iata) as airports,
    SUM(m.total_pieces) as total_pieces,
    SUM(m.shipment_count) as total_shipments
FROM {{ ref('fact_masters') }} m
LEFT JOIN {{ ref('dim_airport') }} a ON m.origin_iata = a.iata
WHERE m.destination_iata = 'FRA'
GROUP BY 1, 2
ORDER BY total_pieces DESC
LIMIT 30;

-- 5. Busiest days of the week
SELECT 
    DAYNAME(shipment_date) as day_of_week,
    COUNT(DISTINCT shipment_date) as number_of_days,
    SUM(total_pieces) as total_pieces,
    AVG(total_pieces) as avg_pieces_per_day
FROM {{ ref('fact_masters') }}
WHERE destination_iata = 'FRA'
GROUP BY 1
ORDER BY CASE DAYNAME(shipment_date)
    WHEN 'Mon' THEN 1
    WHEN 'Tue' THEN 2
    WHEN 'Wed' THEN 3
    WHEN 'Thu' THEN 4
    WHEN 'Fri' THEN 5
    WHEN 'Sat' THEN 6
    WHEN 'Sun' THEN 7
END;
