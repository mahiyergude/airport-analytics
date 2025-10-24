# Snapshots

This directory contains dbt snapshot definitions for tracking slowly changing dimensions (SCD Type 2).

## Purpose
Snapshots capture the state of mutable tables over time, allowing you to track historical changes.

## What are Snapshots?
Snapshots implement Slowly Changing Dimension (SCD) Type 2 logic:
- Track changes to records over time
- Preserve historical values
- Add validity timestamps (valid_from, valid_to)

## When to Use Snapshots
- Tracking changes in dimension tables (e.g., airport names, addresses)
- Maintaining audit trails
- Historical reporting requirements
- Regulatory compliance

## Usage
```bash
# Run snapshots
dbt snapshot

# Run specific snapshot
dbt snapshot --select snapshot_name
```

## Example Snapshot
```sql
-- snapshots/snapshot_airport_changes.sql
{% snapshot snapshot_airport_changes %}

{{
    config(
      target_schema='snapshots',
      unique_key='iata',
      strategy='timestamp',
      updated_at='updated_at',
    )
}}

SELECT * FROM {{ source('raw', 'RAW_AIRPORTS_IATA_ICAO') }}

{% endsnapshot %}
```

## Snapshot Strategies

### Timestamp Strategy
Uses an `updated_at` column to detect changes

### Check Strategy
Compares specified columns to detect changes

## Current Project Status
Currently, this project does not use snapshots as the airport and shipment data is relatively static. However, snapshots could be added for:
- Tracking airport metadata changes
- Monitoring shipment status updates
- Historical price tracking

## Output
Snapshots create tables in the target schema with additional columns:
- `dbt_scd_id` - Unique identifier
- `dbt_updated_at` - When record was snapshotted
- `dbt_valid_from` - Start of validity period
- `dbt_valid_to` - End of validity period (NULL = current)
