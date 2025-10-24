# Seeds

This directory contains CSV files that can be loaded into the data warehouse using `dbt seed`.

## Purpose
Seeds are CSV files in your dbt project that dbt can load into your data warehouse using the `dbt seed` command.

## Usage
```bash
dbt seed
```

## When to Use Seeds
- Small reference data (countries, categories, lookup tables)
- Static configuration data
- Test data for development

## When NOT to Use Seeds
- Large datasets (use proper data loading instead)
- Frequently changing data
- Sensitive data

## Example Structure
```
seeds/
├── countries.csv
├── airport_categories.csv
└── currency_codes.csv
```

Currently, this project loads data directly into Snowflake RAW tables, so seeds are not used.
