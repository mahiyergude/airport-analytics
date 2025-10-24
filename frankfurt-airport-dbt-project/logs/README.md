# Logs Directory

This directory contains dbt execution logs.

## Purpose
dbt automatically generates log files during execution:
- `dbt.log` - Detailed execution logs
- Debug information
- SQL compilation results
- Error messages and stack traces

## Log Files
- Created automatically by dbt
- Useful for debugging
- Should be in `.gitignore` (not committed to git)

## Viewing Logs
```bash
# View latest log
cat logs/dbt.log

# Tail logs in real-time
tail -f logs/dbt.log
```

## Note
This directory is excluded from git via `.gitignore` as logs contain execution details that don't need to be version controlled.
