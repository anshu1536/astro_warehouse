# Architecture and Incremental Contract

## Layers

### 1. Raw
`raw_ephemeris` and `raw_houses` contain direct Swiss Ephemeris outputs. They are append-only.

### 2. Staging
Normalizes raw rows for dbt. No interpretation.

### 3. Intermediate
Computes aspects, orbs, motion states and house-related geometry.

### 4. Mapping
Explicit lookup tables hold the meaning vocabulary. This prevents meanings from being silently invented inside inference SQL.

### 5. Facts
`fct_signals` produces atomic signals. `driver_group` is the anti-double-counting key. For example, station + retrograde are both Venus motion observations, not two independent votes.

### 6. SCD2
Signal and inference state histories preserve valid-from / valid-to changes.

### 7. Marts
Relationship, transit and inference marts are the user-facing analytical outputs.

## Incremental rule

A run only adds missing raw calculation keys. dbt then rebuilds derived models from the append-only raw source. This is deliberately conservative and reproducible for a personal-scale warehouse. If the dataset becomes large, the intermediate/fact models can be converted to dbt incremental materializations using `local_datetime` as the partition boundary.

## Audit rule

Every prediction must be traceable:

`prediction -> inference -> signal -> aspect/motion/house calculation -> raw ephemeris -> input config`

No prose-only prediction is considered an auditable output.
