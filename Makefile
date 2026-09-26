install:
	python -m pip install -r requirements.txt

run:
	python src/run_pipeline.py --start 2026-09-26 --end 2026-10-31

dbt:
	dbt run --project-dir dbt --profiles-dir dbt

all: run dbt
