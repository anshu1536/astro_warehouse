# Data contracts

## Raw immutability
- `calculation_id` is deterministic.
- Re-running the same dates uses `INSERT OR IGNORE`.
- Existing parquet partitions are never overwritten.

## No double counting
- `driver_group` is the unit of signal independence.
- Multiple observations of the same underlying motion/aspect must not be treated as independent votes.

## Person-B boundary
- No table contains inferred biography, emotions, relationship status or intentions of an unidentified second person.
- A second chart is a separate input profile.

## Reproducibility
- Config hash is stored with raw rows.
- Zodiac, ayanamsha, house system and source engine are explicit.
