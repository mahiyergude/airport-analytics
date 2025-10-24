# Frankfurt Airport Analytics - dbt Project

A dbt project analyzing air traffic and cargo shipments through Frankfurt Airport (FRA/EDDF) using Snowflake.

## 📊 Business Questions

1. ✅ What is the annual average of pieces arriving at Frankfurt Airport?
2. ✅ What is the monthly average of flights arriving at Frankfurt Airport?
3. ✅ What is the most common origin of masters arriving at Frankfurt Airport?

## 📁 Project Structure
```
frankfurt-airport-dbt-project/
│
├── 📄 README.md                          # Project documentation
├── 📄 DATA_SETUP.md                      # Snowflake setup instructions
├── 📄 dbt_project.yml                    # dbt configuration
├── 📄 profiles.yml.example               # Database connection template
├── 📄 packages.yml                       # dbt package dependencies
│
├── 📂 RAW/                               # Source data files
│   ├── iata-icao.csv                    # Airport reference data (7,698 airports)
│   ├── DIM_MASTER.xlsx                  # Shipment data (914,130 records)
│   └── response.json                    # Flight arrivals from OpenSky API (871 flights)
│
├── 📂 models/                            # dbt transformation models
│   │
│   ├── sources.yml                      # Source table definitions
│   │
│   ├── 📂 staging/                      # Layer 1: Data cleaning
│   │   ├── schema.yml                  # Model documentation & tests
│   │   ├── stg_airports.sql            # Clean airport reference data
│   │   ├── stg_masters.sql             # Clean shipment data
│   │   └── stg_airport_arrivals.sql    # Parse JSON flight data
│   │
│   ├── 📂 marts/                        # Layer 2: Business logic
│   │   ├── schema.yml                  # Model documentation & tests
│   │   ├── dim_airport.sql             # Airport dimension table
│   │   ├── fact_arrivals.sql           # Flight arrivals fact table
│   │   └── fact_masters.sql            # Shipment fact table
│   │
│   └── 📂 metrics/                      # Layer 3: Business questions
│       ├── q_annual_avg_pieces.sql     # Question 1: Annual average pieces
│       ├── q_monthly_avg_flights.sql   # Question 2: Monthly average flights
│       └── q_common_origin_masters.sql # Question 3: Most common origins
│
├── 📂 macros/                            # Custom SQL functions
│   └── test_positive_value.sql          # Custom test for positive values
│
├── 📂 analyses/                          # Ad-hoc analytical queries
    └── ad_hoc_queries.sql               # Exploratory analysis examples
        
```

## 🏗️ Architecture

```
RAW Data (Snowflake) → Staging (Clean) → Marts (Business Logic) → Metrics (Analytics)
```

## 🚀 Quick Start

```bash
# 1. Configure connection
cp profiles.yml.example ~/.dbt/profiles.yml
# Edit with your Snowflake credentials

# 2. Install packages
dbt deps

# 3. Run models
dbt run

# 4. Test data quality
dbt test

# 5. View documentation
dbt docs generate && dbt docs serve
```
## 📊 Query Results

```sql
USE DATABASE AIRPORT_ANALYTICS_DB;
USE SCHEMA DEV;

-- Annual average pieces to Frankfurt
SELECT * FROM q_annual_avg_pieces;

-- Monthly average flights to Frankfurt
SELECT * FROM q_monthly_avg_flights;

-- Top origins by volume
SELECT * FROM q_common_origin_masters LIMIT 10;
```

## 🔧 Setup Requirements

1. Snowflake account with data loaded (see `DATA_SETUP.md`)
2. dbt installed: `pip install dbt-snowflake`
3. Access to RAW schema with tables:
   - `RAW_AIRPORTS_IATA_ICAO`
   - `RAW_MASTER`
   - `RAW_OPENSKY_ARRIVALS`

## 📖 Documentation

Full documentation available after running:
```bash
dbt docs generate
dbt docs serve
```

## 🧪 Tests

Run all tests:
```bash
dbt test
```

Run specific layer:
```bash
dbt test --select staging
dbt test --select marts
```

## 📈 Data Model

- **Staging**: 3 views (airports, masters, arrivals)
- **Marts**: 1 dimension (airports) + 2 facts (arrivals, masters)
- **Metrics**: 3 views (business questions)

---

For detailed setup instructions, see `DATA_SETUP.md`
