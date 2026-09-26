# Next-run recipe

Suppose the warehouse already contains data through 2026-10-31.

For November:

```bash
python src/run_pipeline.py --start 2026-11-01 --end 2026-11-30 --incremental
dbt run --project-dir dbt --profiles-dir dbt
```

For a new day only:

```bash
python src/run_pipeline.py --start 2026-12-01 --end 2026-12-01 --incremental
dbt run --project-dir dbt --profiles-dir dbt
```

For a historical correction, **do not silently overwrite raw data**. Create a new config/version hash or a new source-engine version and preserve both datasets so the change is auditable.
