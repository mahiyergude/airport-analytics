# Tests

This directory contains custom data quality tests for the dbt project.

## Purpose
Custom tests that go beyond dbt's built-in tests (unique, not_null, accepted_values, relationships).

## Test Types

### Built-in Tests (defined in schema.yml)
Located in `models/staging/schema.yml` and `models/marts/schema.yml`:
- `unique` - Ensures column values are unique
- `not_null` - Ensures no NULL values
- `accepted_values` - Validates against allowed values
- `relationships` - Checks foreign key integrity

### Custom Tests (would go here)
Examples of custom tests you might add:
- Date range validations
- Cross-table consistency checks
- Business rule validations
- Statistical anomaly detection

## Running Tests
```bash
# Run all tests
dbt test

# Run tests for specific model
dbt test --select fact_arrivals

# Run tests for specific layer
dbt test --select staging
dbt test --select marts
```

## Current Testing Strategy
This project uses:
- Schema tests defined in `schema.yml` files (45+ tests)
- Custom macro: `macros/test_positive_value.sql`
- All tests are passing ✅

## Adding Custom Tests
To add a custom test:
1. Create a SQL file in this directory (e.g., `test_custom_validation.sql`)
2. Write a SELECT statement that returns failing rows
3. Run `dbt test` to execute

Example:
```sql
-- tests/test_future_dates.sql
-- Returns rows with dates in the future (should be 0)
SELECT *
FROM {{ ref('fact_masters') }}
WHERE shipment_date > CURRENT_DATE()
```
