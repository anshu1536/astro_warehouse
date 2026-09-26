# Astrology Warehouse Architecture

## Overview

The astrology warehouse follows a layered data-warehouse architecture:

```text
Swiss Ephemeris
       │
       ▼
   Raw Layer
       │
       ▼
    Staging
       │
       ▼
  Intermediate
       │
       ▼
 Signals / Facts
       │
       ▼
     SCD2
       │
       ▼
   Inference
       │
       ▼
     Marts
```

The system separates astronomical calculation, transformation, signal generation,
historical versioning, inference, and analytical presentation.

## Core principles

- Raw astronomical calculations remain immutable.
- dbt performs deterministic transformations.
- Signals are separated from inference.
- SCD2 models preserve historical state.
- Marts provide domain-specific analytical outputs.
- DuckDB provides the local analytical warehouse.

## Domain layers

### Relationship

```text
Transit / Natal Geometry
        ↓
Relationship Signals
        ↓
Relationship Inference
        ↓
relationship_mart
```

### Sexual Intimacy

```text
Transit / Natal Geometry
        ↓
Sex Signals
        ↓
Sex Inference
        ↓
sex_mart
```

### Marriage

```text
Transit / Natal Geometry
        ↓
Marriage Signals
        ↓
Marriage Inference
        ↓
marriage_mart
```

### Additional domains

The warehouse also contains health, job, core inference, and transit marts.

## Technology

- Swiss Ephemeris
- Python
- DuckDB
- dbt
- Parquet
- SQL
