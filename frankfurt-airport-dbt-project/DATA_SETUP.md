# Snowflake Data Setup Guide

This document explains how to set up Snowflake and load the raw data for the Airport Analytics project.

## 📋 Prerequisites

- Snowflake account with ACCOUNTADMIN access
- Raw data files:
  - `iata-icao.csv` (Airport reference data)
  - `DIM_MASTER.xlsx` or `.csv` (Shipment data)
  - `response.json` (OpenSky flight arrivals)

---

## 🔧 Step 1: Create Snowflake User & Database

Run this SQL in your Snowflake worksheet:

```sql
-- Step 1: Use an admin role
USE ROLE ACCOUNTADMIN;

-- Step 2: Create the `transform` role and assign it to ACCOUNTADMIN
CREATE ROLE IF NOT EXISTS TRANSFORM;
GRANT ROLE TRANSFORM TO ROLE ACCOUNTADMIN;

-- Step 3: Create a default warehouse
CREATE WAREHOUSE IF NOT EXISTS COMPUTE_WH;
GRANT OPERATE ON WAREHOUSE COMPUTE_WH TO ROLE TRANSFORM;

-- Step 4: Create the `dbt` user and assign to the transform role
CREATE USER IF NOT EXISTS dbt
  PASSWORD=''
  LOGIN_NAME=''
  MUST_CHANGE_PASSWORD=FALSE
  DEFAULT_WAREHOUSE='COMPUTE_WH'
  DEFAULT_ROLE=TRANSFORM
  DEFAULT_NAMESPACE='AIRPORT_ANALYTICS_DB.RAW'
  COMMENT='DBT user used for data transformation';

ALTER USER dbt SET TYPE = LEGACY_SERVICE;
GRANT ROLE TRANSFORM TO USER dbt;

-- Step 5: Create a database and schema for the project
CREATE DATABASE IF NOT EXISTS AIRPORT_ANALYTICS_DB;
CREATE SCHEMA IF NOT EXISTS AIRPORT_ANALYTICS_DB.RAW;

-- Step 6: Grant permissions to the `transform` role
GRANT ALL ON WAREHOUSE COMPUTE_WH TO ROLE TRANSFORM;
GRANT ALL ON DATABASE AIRPORT_ANALYTICS_DB TO ROLE TRANSFORM;
GRANT ALL ON ALL SCHEMAS IN DATABASE AIRPORT_ANALYTICS_DB TO ROLE TRANSFORM;
GRANT ALL ON FUTURE SCHEMAS IN DATABASE AIRPORT_ANALYTICS_DB TO ROLE TRANSFORM;
GRANT ALL ON ALL TABLES IN SCHEMA AIRPORT_ANALYTICS_DB.RAW TO ROLE TRANSFORM;
GRANT ALL ON FUTURE TABLES IN SCHEMA AIRPORT_ANALYTICS_DB.RAW TO ROLE TRANSFORM;

-- Set defaults
USE WAREHOUSE COMPUTE_WH;
USE DATABASE AIRPORT_ANALYTICS_DB;
USE SCHEMA RAW;
```

---

## 📊 Step 2: Create RAW Tables

```sql
-- Table 1: Airport Reference Data
DROP TABLE IF EXISTS AIRPORT_ANALYTICS_DB.RAW.RAW_AIRPORTS_IATA_ICAO;
CREATE OR REPLACE TABLE AIRPORT_ANALYTICS_DB.RAW.RAW_AIRPORTS_IATA_ICAO (
  COUNTRY_CODE  VARCHAR(2)      COMMENT 'ISO country code',
  REGION_NAME   VARCHAR         COMMENT 'Region or state name',
  IATA          VARCHAR(3)      COMMENT 'IATA airport code (may be null)',
  ICAO          VARCHAR(4)      NULL COMMENT 'ICAO airport code (may be null)',
  AIRPORT       VARCHAR         COMMENT 'Airport name',
  LATITUDE      FLOAT           COMMENT 'Latitude',
  LONGITUDE     FLOAT           COMMENT 'Longitude'
);

-- Table 2: Shipment Master Data
CREATE OR REPLACE TABLE RAW_MASTER (
  MASTER_NUMBER VARCHAR          COMMENT 'Official MAWB number',
  ORIGIN        VARCHAR(3)       COMMENT 'IATA origin airport code',
  DESTINATION   VARCHAR(3)       COMMENT 'IATA destination airport code',
  PIECES        NUMBER(38,0)     COMMENT 'Number of pieces in the MAWB',
  LAST_SEEN     TIMESTAMP_NTZ    COMMENT 'Last update date/time in source system'
);

-- Table 3: OpenSky Flight Arrivals (JSON format)
CREATE OR REPLACE TABLE AIRPORT_ANALYTICS_DB.RAW.RAW_OPENSKY_ARRIVALS (
  RAW VARIANT
);
```

---

## 📥 Step 3: Load Data

### Option A: Snowflake UI (Recommended for Small Files)

1. **Load Airport Data**:
   - Go to Databases → AIRPORT_ANALYTICS_DB → RAW → RAW_AIRPORTS_IATA_ICAO
   - Click "Load Data"
   - Upload `iata-icao.csv`
   - Map columns to table schema
   - Click "Load"

2. **Load Master Data**:
   - Go to RAW → RAW_MASTER
   - Click "Load Data"
   - Upload `DIM_MASTER.csv`
   - **Important**: If file has semicolon delimiter, set delimiter to `;`
   - Map columns: MASTER_NUMBER, ORIGIN, DESTINATION, PIECES, LAST_SEEN
   - Click "Load"

3. **Load OpenSky Data**:
   - Go to RAW → RAW_OPENSKY_ARRIVALS
   - Click "Load Data"
   - Upload `response.json`
   - File format: JSON
   - Click "Load"

### Option B: Snowflake COPY Command

```sql
-- 1. Create file format for JSON
CREATE OR REPLACE FILE FORMAT JSON_FORMAT_ARRIVALS
  TYPE = 'JSON'
  STRIP_OUTER_ARRAY = TRUE
  IGNORE_UTF8_ERRORS = TRUE;

-- 2. Create internal stage
CREATE OR REPLACE STAGE AIRPORT_STAGE;

-- 3. Upload files to stage (using SnowSQL or UI)
-- PUT file:///path/to/iata-icao.csv @AIRPORT_STAGE;
-- PUT file:///path/to/DIM_MASTER.csv @AIRPORT_STAGE;
-- PUT file:///path/to/response.json @AIRPORT_STAGE;

-- 4. Load airport data
COPY INTO RAW_AIRPORTS_IATA_ICAO
FROM @AIRPORT_STAGE/iata-icao.csv
FILE_FORMAT = (TYPE = 'CSV' SKIP_HEADER = 1 FIELD_OPTIONALLY_ENCLOSED_BY = '"');

-- 5. Load master data
-- If semicolon-delimited:
COPY INTO RAW_MASTER
FROM @AIRPORT_STAGE/DIM_MASTER.csv
FILE_FORMAT = (TYPE = 'CSV' SKIP_HEADER = 1 FIELD_DELIMITER = ';' FIELD_OPTIONALLY_ENCLOSED_BY = '"');

-- 6. Load OpenSky data
COPY INTO RAW_OPENSKY_ARRIVALS
FROM @AIRPORT_STAGE/response.json
FILE_FORMAT = JSON_FORMAT_ARRIVALS;
```

---

## ✅ Step 4: Verify Data Load

```sql
USE DATABASE AIRPORT_ANALYTICS_DB;
USE SCHEMA RAW;

-- Check airport data
SELECT COUNT(*) as airport_count FROM RAW_AIRPORTS_IATA_ICAO;
-- Expected: ~7,698 rows

-- Check master data
SELECT COUNT(*) as shipment_count FROM RAW_MASTER;
-- Expected: ~914,130 rows

SELECT COUNT(*) as fra_shipments 
FROM RAW_MASTER 
WHERE DESTINATION = 'FRA';
-- Expected: Many thousands

-- Check OpenSky data
SELECT COUNT(*) as flight_count FROM RAW_OPENSKY_ARRIVALS;
-- Expected: 871 rows

-- Sample the data
SELECT * FROM RAW_AIRPORTS_IATA_ICAO LIMIT 5;
SELECT * FROM RAW_MASTER LIMIT 5;
SELECT * FROM RAW_OPENSKY_ARRIVALS LIMIT 5;
```

---

## 🔍 Data Quality Checks

### Airport Data
```sql
-- Check for nulls
SELECT 
    COUNT(*) as total_rows,
    SUM(CASE WHEN IATA IS NULL THEN 1 ELSE 0 END) as null_iata,
    SUM(CASE WHEN ICAO IS NULL THEN 1 ELSE 0 END) as null_icao,
    SUM(CASE WHEN AIRPORT IS NULL THEN 1 ELSE 0 END) as null_name
FROM RAW_AIRPORTS_IATA_ICAO;

-- Find Frankfurt Airport
SELECT * FROM RAW_AIRPORTS_IATA_ICAO 
WHERE IATA = 'FRA' OR ICAO = 'EDDF';
```

### Master Data
```sql
-- Date range
SELECT 
    MIN(LAST_SEEN) as earliest_shipment,
    MAX(LAST_SEEN) as latest_shipment,
    DATEDIFF(day, MIN(LAST_SEEN), MAX(LAST_SEEN)) as days_span
FROM RAW_MASTER;

-- Top destinations
SELECT 
    DESTINATION,
    COUNT(*) as shipment_count,
    SUM(PIECES) as total_pieces
FROM RAW_MASTER
GROUP BY DESTINATION
ORDER BY shipment_count DESC
LIMIT 10;
```

### OpenSky Data
```sql
-- Parse JSON and check
SELECT 
    RAW:icao24::STRING as aircraft,
    RAW:estArrivalAirport::STRING as arrival_airport,
    TO_TIMESTAMP(RAW:firstSeen::NUMBER) as first_seen
FROM RAW_OPENSKY_ARRIVALS
LIMIT 5;

-- Count arrivals at Frankfurt
SELECT COUNT(*) as frankfurt_arrivals
FROM RAW_OPENSKY_ARRIVALS
WHERE RAW:estArrivalAirport::STRING = 'EDDF';
```

---

## 🔐 Security Notes

1. **Change the default password** for the `dbt` user in production
2. **Use secrets management** (e.g., AWS Secrets Manager) for credentials
3. **Enable Multi-Factor Authentication** on Snowflake accounts
4. **Follow principle of least privilege** - grant only necessary permissions

---

## 📊 Expected Data Summary

After loading, you should have:

| Table | Rows | Key Fields |
|-------|------|------------|
| RAW_AIRPORTS_IATA_ICAO | ~7,698 | IATA, ICAO, AIRPORT, LATITUDE, LONGITUDE |
| RAW_MASTER | ~914,130 | MASTER_NUMBER, ORIGIN, DESTINATION, PIECES |
| RAW_OPENSKY_ARRIVALS | 871 | JSON with flight details |

**Frankfurt-Specific**:
- FRA (IATA) / EDDF (ICAO) should be in airports table
- Many shipments with DESTINATION = 'FRA' in RAW_MASTER
- Many flights with estArrivalAirport = 'EDDF' in RAW_OPENSKY_ARRIVALS

---

## 🐛 Troubleshooting

### Issue: Data load fails with "invalid UTF-8 character"
**Solution**: Add `ENCODING = 'UTF8'` to file format

### Issue: Dates not parsing correctly
**Solution**: Specify date format, e.g., `DATE_FORMAT = 'YYYY-MM-DD HH24:MI:SS'`

### Issue: Semicolon delimiter not recognized
**Solution**: Explicitly set `FIELD_DELIMITER = ';'` in file format

### Issue: Permission denied errors
**Solution**: Re-run the GRANT statements in Step 1

---

## ✅ Next Steps

Once data is loaded and verified:

1. Configure dbt connection (`profiles.yml`)
2. Run `dbt debug` to test connection
3. Run `dbt run` to build models
4. Run `dbt test` to validate data quality

See main README.md for dbt setup instructions.

---

**Last Updated**: January 2025
