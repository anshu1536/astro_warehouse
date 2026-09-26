# Astrology Calculation Warehouse

A reproducible, calculation-first astrology research project designed for **incremental runs**.

## Principles

1. Swiss Ephemeris is the source of truth for astronomical positions.
2. Raw ephemeris is immutable and never overwritten.
3. All derived geometry is deterministic SQL/Python transformation.
4. Astrology meanings live in explicit mapping tables, not hidden prose.
5. Signals are deduplicated by underlying driver to avoid double-counting.
6. Relationship inference is separated from raw calculations.
7. SCD Type 2 tables preserve changes in signal/inference state over time.
8. The system never infers facts about an unidentified second person.

## Stack

- Python + pyswisseph for ephemeris generation
- DuckDB as local analytical warehouse
- dbt-duckdb for transformations
- Parquet for immutable raw ephemeris snapshots

## First run

```bash
python -m venv .venv
# Windows: .venv\\Scripts\\activate
# macOS/Linux: source .venv/bin/activate
pip install -r requirements.txt
python src/run_pipeline.py --start 2026-09-26 --end 2026-10-31
```

Then run dbt:

```bash
dbt run --project-dir dbt --profiles-dir dbt
```

## Next run

You do **not** need to rebuild the historical window.

For a new period:

```bash
python src/run_pipeline.py --start 2026-11-01 --end 2026-11-30 --incremental
 dbt run --project-dir dbt --profiles-dir dbt
```

The raw layer is append-only and keyed by calculation inputs + date/time. Existing raw rows are not replaced.

## Project flow

```text
Swiss Ephemeris
      |
      v
RAW EPHEMERIS (Parquet, immutable)
      |
      v
stg_ephemeris / stg_natal / stg_config
      |
      +--> int_planet_positions
      +--> int_house_positions
      +--> int_aspects
      +--> int_motion_states
      |
      v
explicit mapping tables
      |
      v
fct_signals
      |
      v
fct_signal_scd2
      |
      v
fct_inference
      |
      v
fct_inference_scd2
      |
      +--> relationship_mart
      +--> transit_mart
      +--> inference_mart
```

## Important limitation

This project calculates the user's chart and transit-derived relationship symbolism. It does **not** manufacture information about another person. A second person's chart requires a second input profile.
