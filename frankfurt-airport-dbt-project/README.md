# Frankfurt Airport Analytics - dbt Project

A dbt project analyzing air traffic and cargo shipments through Frankfurt Airport (FRA/EDDF) using Snowflake.

## 📊 Business Questions

1. ✅ What is the annual average of pieces arriving at Frankfurt Airport?
2. ✅ What is the monthly average of flights arriving at Frankfurt Airport?
3. ✅ What is the most common origin of masters arriving at Frankfurt Airport?

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

## 📁 Project Structure

- `models/staging/` - Data cleaning & standardization
- `models/marts/` - Business logic (facts & dimensions)
- `models/metrics/` - Analytics views answering business questions

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
