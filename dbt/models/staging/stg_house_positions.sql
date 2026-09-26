select * from read_parquet('../data/raw/transit_house_positions_*.parquet', union_by_name=true)
