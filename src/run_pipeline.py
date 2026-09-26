import argparse, hashlib, json, math, os
from datetime import datetime, date, timedelta, timezone
from zoneinfo import ZoneInfo

import duckdb
import pandas as pd
import swisseph as swe
import yaml

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CONFIG = os.path.join(ROOT, 'config', 'chart.yml')
DB = os.path.join(ROOT, 'data', 'warehouse', 'astro.duckdb')
RAW = os.path.join(ROOT, 'data', 'raw')

PLANETS = {
    'SUN': swe.SUN, 'MOON': swe.MOON, 'MERCURY': swe.MERCURY,
    'VENUS': swe.VENUS, 'MARS': swe.MARS, 'JUPITER': swe.JUPITER,
    'SATURN': swe.SATURN, 'TRUE_NODE': swe.TRUE_NODE,
}


def load_config():
    with open(CONFIG, 'r', encoding='utf-8') as f:
        return yaml.safe_load(f)


def jd_for_local(dt_local):
    utc = dt_local.astimezone(timezone.utc)
    hour = utc.hour + utc.minute / 60 + utc.second / 3600 + utc.microsecond / 3_600_000_000
    return swe.julday(utc.year, utc.month, utc.day, hour, swe.GREG_CAL)


def calc_positions(jd):
    swe.set_sid_mode(swe.SIDM_LAHIRI)
    flags = swe.FLG_SWIEPH | swe.FLG_SPEED | swe.FLG_SIDEREAL
    rows = []
    for code, pid in PLANETS.items():
        vals, retflag = swe.calc_ut(jd, pid, flags)
        rows.append({
            'planet_code': code,
            'longitude': float(vals[0]),
            'latitude': float(vals[1]),
            'distance_au': float(vals[2]),
            'speed_longitude': float(vals[3]),
            'speed_latitude': float(vals[4]),
            'speed_distance': float(vals[5]),
            'calc_flags': int(retflag),
        })
    return rows


def calc_houses(jd, lat, lon, hsys='P'):
    # swe.houses_ex returns tropical cusps; convert cusps/angles to Lahiri sidereal.
    cusps, ascmc = swe.houses_ex(jd, lat, lon, hsys.encode(), swe.FLG_SIDEREAL)
    return {'cusps': list(cusps), 'ascendant': float(ascmc[0]), 'mc': float(ascmc[1])}


def house_for_longitude(lon, cusps):
    lon %= 360
    for h in range(1, 13):
        start = cusps[h-1] % 360
        end = cusps[h % 12] % 360
        if start <= end:
            if start <= lon < end:
                return h
        else:
            if lon >= start or lon < end:
                return h
    return 12


def angle_distance(a, b):
    d = abs((a - b) % 360)
    return min(d, 360 - d)


def aspect_type(sep, orb):
    targets = [('conjunction', 0), ('sextile', 60), ('square', 90), ('trine', 120), ('opposition', 180)]
    best = None
    for name, target in targets:
        diff = abs(sep - target)
        if diff <= orb and (best is None or diff < best[2]):
            best = (name, target, diff)
    return best


def input_hash(cfg):
    return hashlib.sha256(json.dumps(cfg, sort_keys=True, default=str).encode()).hexdigest()


def ensure_raw_table(con):
    con.execute('''CREATE TABLE IF NOT EXISTS raw_ephemeris (
        calculation_id VARCHAR,
        chart_name VARCHAR,
        calculation_type VARCHAR,
        local_datetime TIMESTAMP,
        utc_datetime TIMESTAMP,
        jd DOUBLE,
        planet_code VARCHAR,
        longitude DOUBLE,
        latitude DOUBLE,
        distance_au DOUBLE,
        speed_longitude DOUBLE,
        speed_latitude DOUBLE,
        speed_distance DOUBLE,
        calc_flags BIGINT,
        ayanamsha VARCHAR,
        zodiac VARCHAR,
        source_engine VARCHAR,
        input_hash VARCHAR,
        loaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        PRIMARY KEY (calculation_id)
    )''')
    con.execute('''CREATE TABLE IF NOT EXISTS raw_houses (
        calculation_id VARCHAR PRIMARY KEY,
        chart_name VARCHAR,
        calculation_type VARCHAR,
        local_datetime TIMESTAMP,
        utc_datetime TIMESTAMP,
        jd DOUBLE,
        house_system VARCHAR,
        ascendant DOUBLE,
        mc DOUBLE,
        cusps_json VARCHAR,
        ayanamsha VARCHAR,
        zodiac VARCHAR,
        source_engine VARCHAR,
        input_hash VARCHAR,
        loaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )''')


def calculation_id(chart_name, typ, local_dt, planet_code=''):
    return hashlib.sha256(f'{chart_name}|{typ}|{local_dt.isoformat()}|{planet_code}'.encode()).hexdigest()


def generate(start, end, incremental=False):
    cfg = load_config()
    chart = cfg['chart']
    con = duckdb.connect(DB)
    ensure_raw_table(con)
    ih = input_hash(cfg)
    tz = ZoneInfo(chart['timezone'])
    os.makedirs(RAW, exist_ok=True)

    birth = datetime.fromisoformat(f"{chart['date']}T{chart['time']}").replace(tzinfo=tz)
    natal_jd = jd_for_local(birth)
    natal_positions = calc_positions(natal_jd)
    natal_houses = calc_houses(natal_jd, chart['latitude'], chart['longitude'], 'P')

    # Natal is a stable input. Insert only if absent.
    for p in natal_positions:
        cid = calculation_id(chart['name'], 'NATAL', birth, p['planet_code'])
        con.execute('''INSERT OR IGNORE INTO raw_ephemeris
          (calculation_id, chart_name, calculation_type, local_datetime, utc_datetime, jd, planet_code,
           longitude, latitude, distance_au, speed_longitude, speed_latitude, speed_distance, calc_flags,
           ayanamsha, zodiac, source_engine, input_hash)
          VALUES (?, ?, 'NATAL', ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'LAHIRI', 'SIDEREAL', 'SWISS_EPHEMERIS', ?)''',
          [cid, chart['name'], birth.replace(tzinfo=None), birth.astimezone(timezone.utc).replace(tzinfo=None), natal_jd,
           p['planet_code'], p['longitude'], p['latitude'], p['distance_au'], p['speed_longitude'],
           p['speed_latitude'], p['speed_distance'], p['calc_flags'], ih])
    ncid = calculation_id(chart['name'], 'NATAL_HOUSES', birth)
    con.execute('''INSERT OR IGNORE INTO raw_houses
      (calculation_id, chart_name, calculation_type, local_datetime, utc_datetime, jd, house_system,
       ascendant, mc, cusps_json, ayanamsha, zodiac, source_engine, input_hash)
      VALUES (?, ?, 'NATAL', ?, ?, ?, 'P', ?, ?, ?, 'LAHIRI', 'SIDEREAL', 'SWISS_EPHEMERIS', ?)''',
      [ncid, chart['name'], birth.replace(tzinfo=None), birth.astimezone(timezone.utc).replace(tzinfo=None), natal_jd,
       natal_houses['ascendant'], natal_houses['mc'], json.dumps(natal_houses['cusps']), ih])

    house_rows = []
    # Daily transit snapshots at local midnight. Raw rows are append-only.
    d = start
    while d <= end:
        local_dt = datetime.combine(d, datetime.min.time()).replace(tzinfo=tz)
        jd = jd_for_local(local_dt)
        houses = calc_houses(jd, chart['latitude'], chart['longitude'], 'P')
        daily_positions = calc_positions(jd)
        for p in daily_positions:
            house_rows.append({
                'chart_name': chart['name'], 'calculation_type': 'TRANSIT',
                'local_datetime': local_dt.replace(tzinfo=None), 'planet_code': p['planet_code'],
                'longitude': p['longitude'], 'house': house_for_longitude(p['longitude'], houses['cusps']),
                'input_hash': ih, 'source_engine': 'SWISS_EPHEMERIS'
            })
            cid = calculation_id(chart['name'], 'TRANSIT', local_dt, p['planet_code'])
            con.execute('''INSERT OR IGNORE INTO raw_ephemeris
              (calculation_id, chart_name, calculation_type, local_datetime, utc_datetime, jd, planet_code,
               longitude, latitude, distance_au, speed_longitude, speed_latitude, speed_distance, calc_flags,
               ayanamsha, zodiac, source_engine, input_hash)
              VALUES (?, ?, 'TRANSIT', ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'LAHIRI', 'SIDEREAL', 'SWISS_EPHEMERIS', ?)''',
              [cid, chart['name'], local_dt.replace(tzinfo=None), local_dt.astimezone(timezone.utc).replace(tzinfo=None), jd,
               p['planet_code'], p['longitude'], p['latitude'], p['distance_au'], p['speed_longitude'],
               p['speed_latitude'], p['speed_distance'], p['calc_flags'], ih])
        hcid = calculation_id(chart['name'], 'TRANSIT_HOUSES', local_dt)
        con.execute('''INSERT OR IGNORE INTO raw_houses
          (calculation_id, chart_name, calculation_type, local_datetime, utc_datetime, jd, house_system,
           ascendant, mc, cusps_json, ayanamsha, zodiac, source_engine, input_hash)
          VALUES (?, ?, 'TRANSIT', ?, ?, ?, 'P', ?, ?, ?, 'LAHIRI', 'SIDEREAL', 'SWISS_EPHEMERIS', ?)''',
          [hcid, chart['name'], local_dt.replace(tzinfo=None), local_dt.astimezone(timezone.utc).replace(tzinfo=None), jd,
           houses['ascendant'], houses['mc'], json.dumps(houses['cusps']), ih])
        d += timedelta(days=1)

    # Export immutable partitions. Never overwrite an existing raw snapshot.
    partition = os.path.join(RAW, f"transits_{start.isoformat()}_{end.isoformat()}_{ih[:10]}.parquet")
    df = con.execute('''SELECT * FROM raw_ephemeris WHERE calculation_type='TRANSIT'
                        AND local_datetime::DATE BETWEEN ? AND ? ORDER BY local_datetime, planet_code''', [start, end]).df()
    if not os.path.exists(partition):
        df.to_parquet(partition, index=False)

    hp = pd.DataFrame(house_rows)
    house_partition = os.path.join(RAW, f"transit_house_positions_{start.isoformat()}_{end.isoformat()}_{ih[:10]}.parquet")
    if not os.path.exists(house_partition):
        hp.to_parquet(house_partition, index=False)

    natal_partition = os.path.join(RAW, f"natal_{ih[:10]}.parquet")
    natal_df = con.execute("SELECT * FROM raw_ephemeris WHERE calculation_type='NATAL' ORDER BY planet_code").df()
    if not os.path.exists(natal_partition):
        natal_df.to_parquet(natal_partition, index=False)
    con.close()
    print(f'Raw warehouse updated: {DB}')
    print(f'Immutable raw partition: {partition}')
    print(f'Transit rows in requested window: {len(df)}')


if __name__ == '__main__':
    ap = argparse.ArgumentParser()
    ap.add_argument('--start', required=True)
    ap.add_argument('--end', required=True)
    ap.add_argument('--incremental', action='store_true')
    args = ap.parse_args()
    generate(date.fromisoformat(args.start), date.fromisoformat(args.end), args.incremental)
