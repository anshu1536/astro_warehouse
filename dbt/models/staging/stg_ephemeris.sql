select * from read_parquet('../data/raw/*.parquet', union_by_name=true)
