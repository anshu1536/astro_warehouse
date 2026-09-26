# dbt Lineage

The authoritative transformation lineage is generated directly from the dbt
project.

## Generate lineage documentation

From the `dbt` directory:

```powershell
dbt docs generate
```

This generates the dbt catalog and manifest from the current project.

## Serve the lineage UI

```powershell
dbt docs serve
```

The resulting dbt documentation provides:

- model dependencies
- column metadata
- source relationships
- compiled SQL
- model-level lineage
- upstream and downstream dependencies

## Why lineage is generated

The repository should not rely on a manually maintained dependency graph for
model-level lineage. dbt already knows the actual DAG from `ref()` and `source()`
relationships.

The architecture diagram in `architecture.mmd` therefore represents the
high-level system design, while the dbt documentation represents the
authoritative model-level lineage.
