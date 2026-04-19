#!/usr/bin/env python
from __future__ import annotations

import argparse
import csv
import hashlib
import importlib
import json
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

DUCKDB_TYPE_MAP = {"integer": "BIGINT", "character": "VARCHAR", "logical": "BOOLEAN"}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Convert a campaign_booklet CSV variant to Parquet using Python CSV parsing.")
    parser.add_argument("--krpoltext-repo", required=True)
    parser.add_argument("--input-csv", required=True)
    parser.add_argument("--output-parquet", required=True)
    parser.add_argument("--summary-json", default=None)
    parser.add_argument(
        "--schema-json",
        default="docs/data/schema/campaign_booklet_enriched.json",
        help="Schema JSON path relative to the krpoltext repo (default: enriched schema).",
    )
    parser.add_argument("--batch-size", type=int, default=1000)
    return parser.parse_args()


def ensure_dependency(name: str) -> Any:
    try:
        return importlib.import_module(name)
    except ImportError as exc:
        raise SystemExit(f"Missing Python dependency '{name}'.") from exc


def clean_text(value: Any) -> str | None:
    if value is None:
        return None
    text = str(value).replace("\ufeff", "").replace("\x00", "").strip()
    return text or None


def clean_int(value: Any) -> int | None:
    if value in (None, "", "NA"):
        return None
    text = str(value).strip()
    if not text:
        return None
    try:
        return int(float(text))
    except ValueError:
        digits = "".join(ch for ch in text if ch.isdigit() or ch == "-")
        if digits and digits not in {"-", ""}:
            try:
                return int(digits)
            except ValueError:
                return None
        return None


def normalize_type(type_name: str) -> str:
    return type_name.strip().upper().split("(")[0]


def quote_identifier(value: str) -> str:
    return '"' + value.replace('"', '""') + '"'


def load_schema(schema_path: Path) -> tuple[list[str], dict[str, str], dict[str, str]]:
    payload = json.loads(schema_path.read_text(encoding='utf-8'))
    columns = payload['columns']
    fieldnames = [column['name'] for column in columns]
    type_map = {column['name']: column['type'] for column in columns}
    duckdb_types = {name: DUCKDB_TYPE_MAP[type_map[name]] for name in fieldnames}
    return fieldnames, type_map, duckdb_types


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open('rb') as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b''):
            digest.update(chunk)
    return digest.hexdigest()


def build_insert_rows(input_csv: Path, fieldnames: list[str], type_map: dict[str, str]):
    with input_csv.open('r', encoding='utf-8', newline='') as handle:
        reader = csv.DictReader(handle)
        if reader.fieldnames != fieldnames:
            raise SystemExit('CSV header did not match the documented campaign_booklet schema.')
        for row in reader:
            values = []
            for name in fieldnames:
                value = row.get(name)
                if type_map[name] == 'integer':
                    values.append(clean_int(value))
                elif type_map[name] == 'logical':
                    cleaned = clean_text(value)
                    values.append(None if cleaned is None else cleaned.lower() in {'true', 't', '1'})
                else:
                    values.append(clean_text(value))
            yield tuple(values)


def update_summary(summary_json: Path, output_parquet: Path, csv_row_count: int, parquet_row_count: int, schema_ok: bool) -> None:
    if not summary_json.exists():
        return
    payload = json.loads(summary_json.read_text(encoding='utf-8'))
    validation = payload.setdefault('validation', {})
    validation['row_count_preserved'] = csv_row_count == parquet_row_count
    validation['csv_parquet_schema_match'] = schema_ok
    validation['parquet_row_count'] = parquet_row_count
    validation['parquet_skipped'] = False
    payload['output_parquet'] = str(output_parquet)
    artifacts = payload.setdefault('artifacts', {})
    artifacts['parquet'] = {
        'file': output_parquet.name,
        'size_bytes': output_parquet.stat().st_size,
        'sha256': sha256_file(output_parquet),
    }
    payload['generated_at'] = datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')
    summary_json.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')


def main() -> None:
    args = parse_args()
    duckdb = ensure_dependency('duckdb')

    krpoltext_repo = Path(args.krpoltext_repo).resolve()
    input_csv = Path(args.input_csv).resolve()
    output_parquet = Path(args.output_parquet).resolve()
    summary_json = Path(args.summary_json).resolve() if args.summary_json else None
    schema_path = Path(args.schema_json)
    schema_path = schema_path if schema_path.is_absolute() else krpoltext_repo / schema_path

    fieldnames, type_map, duckdb_types = load_schema(schema_path)
    output_parquet.parent.mkdir(parents=True, exist_ok=True)
    if output_parquet.exists():
        output_parquet.unlink()

    connection = duckdb.connect(database=':memory:')
    try:
        create_columns = ', '.join(f"{quote_identifier(name)} {duckdb_types[name]}" for name in fieldnames)
        connection.execute(f"CREATE TABLE campaign_booklet ({create_columns})")
        placeholders = ', '.join(['?'] * len(fieldnames))
        insert_sql = f"INSERT INTO campaign_booklet VALUES ({placeholders})"
        batch: list[tuple[Any, ...]] = []
        csv_row_count = 0
        for values in build_insert_rows(input_csv, fieldnames, type_map):
            batch.append(values)
            csv_row_count += 1
            if len(batch) >= args.batch_size:
                connection.executemany(insert_sql, batch)
                batch.clear()
        if batch:
            connection.executemany(insert_sql, batch)
        connection.execute(
            "COPY campaign_booklet TO ? (FORMAT PARQUET, COMPRESSION SNAPPY)",
            [str(output_parquet)],
        )
        parquet_row_count = connection.execute("SELECT COUNT(*) FROM campaign_booklet").fetchone()[0]
        schema_rows = connection.execute(
            f"DESCRIBE SELECT * FROM read_parquet('{str(output_parquet).replace("'", "''")}')"
        ).fetchall()
    finally:
        connection.close()

    parquet_columns = [row[0] for row in schema_rows]
    parquet_types = {row[0]: normalize_type(row[1]) for row in schema_rows}
    expected_types = {name: duckdb_types[name] for name in fieldnames}
    schema_ok = parquet_columns == fieldnames and parquet_types == expected_types
    if parquet_row_count != csv_row_count:
        raise SystemExit('CSV and Parquet row counts did not match.')
    if not schema_ok:
        raise SystemExit('Parquet schema did not match the documented campaign_booklet schema.')
    if summary_json is not None:
        update_summary(summary_json, output_parquet, csv_row_count, parquet_row_count, schema_ok)

    print(json.dumps({
        'input_csv': str(input_csv),
        'output_parquet': str(output_parquet),
        'csv_row_count': csv_row_count,
        'parquet_row_count': parquet_row_count,
        'schema_ok': schema_ok,
        'parquet_size_bytes': output_parquet.stat().st_size,
        'parquet_sha256': sha256_file(output_parquet),
    }, ensure_ascii=False, indent=2))


if __name__ == '__main__':
    main()
