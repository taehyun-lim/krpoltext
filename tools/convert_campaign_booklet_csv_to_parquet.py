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
PARQUET_ROW_GROUP_SIZE = 512


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Convert a campaign_booklet CSV variant to Parquet using Python CSV parsing.")
    parser.add_argument("--krpoltext-repo", required=True)
    parser.add_argument("--input-csv", required=True)
    parser.add_argument("--output-parquet", required=True)
    parser.add_argument(
        "--output-lookup-parquet",
        default=None,
        help="Optional text-free, row-addressable lookup Parquet output path.",
    )
    parser.add_argument("--summary-json", default=None)
    parser.add_argument(
        "--schema-json",
        default="docs/data/schema/campaign_booklet_enriched.json",
        help="Schema JSON path relative to the krpoltext repo (default: enriched schema).",
    )
    parser.add_argument("--batch-size", type=int, default=1000)
    parser.add_argument(
        "--python-csv-parser",
        action="store_true",
        help="Use the slower Python CSV parser instead of DuckDB's direct CSV scan.",
    )
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


def update_summary(
    summary_json: Path,
    output_parquet: Path,
    output_lookup_parquet: Path | None,
    csv_row_count: int,
    parquet_row_count: int,
    schema_ok: bool,
    parquet_row_group_count: int,
    lookup_validation: dict[str, Any] | None,
) -> None:
    if not summary_json.exists():
        return
    payload = json.loads(summary_json.read_text(encoding='utf-8'))
    validation = payload.setdefault('validation', {})
    validation['row_count_preserved'] = csv_row_count == parquet_row_count
    validation['csv_parquet_schema_match'] = schema_ok
    validation['parquet_row_count'] = parquet_row_count
    validation['parquet_row_group_count'] = parquet_row_group_count
    validation['parquet_skipped'] = False
    payload['output_parquet'] = str(output_parquet)
    artifacts = payload.setdefault('artifacts', {})
    artifacts['parquet'] = {
        'file': output_parquet.name,
        'size_bytes': output_parquet.stat().st_size,
        'sha256': sha256_file(output_parquet),
    }
    if output_lookup_parquet is not None and lookup_validation is not None:
        validation.update(lookup_validation)
        payload['output_lookup_parquet'] = str(output_lookup_parquet)
        artifacts['lookup_parquet'] = {
            'file': output_lookup_parquet.name,
            'size_bytes': output_lookup_parquet.stat().st_size,
            'sha256': sha256_file(output_lookup_parquet),
            'source_artifact_sha256': artifacts['parquet']['sha256'],
        }
    payload['generated_at'] = datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')
    summary_json.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')


def main() -> None:
    args = parse_args()
    duckdb = ensure_dependency('duckdb')

    krpoltext_repo = Path(args.krpoltext_repo).resolve()
    input_csv = Path(args.input_csv).resolve()
    output_parquet = Path(args.output_parquet).resolve()
    output_lookup_parquet = (
        Path(args.output_lookup_parquet).resolve()
        if args.output_lookup_parquet
        else None
    )
    summary_json = Path(args.summary_json).resolve() if args.summary_json else None
    schema_path = Path(args.schema_json)
    schema_path = schema_path if schema_path.is_absolute() else krpoltext_repo / schema_path

    fieldnames, type_map, duckdb_types = load_schema(schema_path)
    output_parquet.parent.mkdir(parents=True, exist_ok=True)
    if output_lookup_parquet is not None:
        output_lookup_parquet.parent.mkdir(parents=True, exist_ok=True)

    if not args.python_csv_parser:
        try:
            from tools.build_campaign_booklet_enriched_duckdb import (
                create_lookup_parquet_from_csv,
                create_parquet_from_csv,
            )
        except ModuleNotFoundError:
            from build_campaign_booklet_enriched_duckdb import (
                create_lookup_parquet_from_csv,
                create_parquet_from_csv,
            )

        full_validation = create_parquet_from_csv(
            duckdb,
            output_csv=input_csv,
            output_parquet=output_parquet,
            fieldnames=fieldnames,
            type_map=type_map,
            duckdb_type_map=duckdb_types,
        )
        lookup_validation = None
        if output_lookup_parquet is not None:
            lookup_result = create_lookup_parquet_from_csv(
                duckdb,
                output_csv=input_csv,
                output_lookup_parquet=output_lookup_parquet,
                fieldnames=fieldnames,
                duckdb_type_map=duckdb_types,
            )
            lookup_validation = {
                "lookup_schema_match": (
                    lookup_result["lookup_columns_match"]
                    and lookup_result["lookup_types_match"]
                ),
                "lookup_positions_valid": lookup_result["lookup_positions_valid"],
                "lookup_row_count": lookup_result["lookup_row_count"],
                "lookup_row_count_match": (
                    lookup_result["lookup_row_count"]
                    == full_validation["csv_row_count"]
                ),
                "lookup_has_text_rows": lookup_result["lookup_has_text_rows"],
            }
        schema_ok = (
            full_validation["parquet_columns_match"]
            and full_validation["parquet_types_match"]
        )
        if (
            full_validation["csv_row_count"]
            != full_validation["parquet_row_count"]
            or not schema_ok
        ):
            raise SystemExit("Direct DuckDB Parquet conversion validation failed.")
        if lookup_validation is not None and not all(
            lookup_validation[key]
            for key in (
                "lookup_schema_match",
                "lookup_positions_valid",
                "lookup_row_count_match",
            )
        ):
            raise SystemExit("Direct DuckDB lookup Parquet validation failed.")
        if summary_json is not None:
            update_summary(
                summary_json,
                output_parquet,
                output_lookup_parquet,
                full_validation["csv_row_count"],
                full_validation["parquet_row_count"],
                schema_ok,
                full_validation["parquet_row_group_count"],
                lookup_validation,
            )
        print(
            json.dumps(
                {
                    "input_csv": str(input_csv),
                    "output_parquet": str(output_parquet),
                    **full_validation,
                    "parquet_size_bytes": output_parquet.stat().st_size,
                    "parquet_sha256": sha256_file(output_parquet),
                    "lookup_parquet": (
                        None
                        if output_lookup_parquet is None
                        else {
                            "path": str(output_lookup_parquet),
                            "size_bytes": output_lookup_parquet.stat().st_size,
                            "sha256": sha256_file(output_lookup_parquet),
                            **(lookup_validation or {}),
                        }
                    ),
                },
                ensure_ascii=False,
                indent=2,
            )
        )
        return

    if output_parquet.exists():
        output_parquet.unlink()
    if output_lookup_parquet is not None:
        output_lookup_parquet.parent.mkdir(parents=True, exist_ok=True)
        if output_lookup_parquet.exists():
            output_lookup_parquet.unlink()

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
            "COPY campaign_booklet TO ? "
            "(FORMAT PARQUET, COMPRESSION SNAPPY, ROW_GROUP_SIZE 2048)",
            [str(output_parquet)],
        )
        try:
            from tools.build_campaign_booklet_enriched_duckdb import (
                rewrite_parquet_row_groups,
            )
        except ModuleNotFoundError:
            from build_campaign_booklet_enriched_duckdb import (
                rewrite_parquet_row_groups,
            )
        rewrite_parquet_row_groups(
            output_parquet,
            row_group_size=PARQUET_ROW_GROUP_SIZE,
        )
        parquet_row_count = connection.execute("SELECT COUNT(*) FROM campaign_booklet").fetchone()[0]
        schema_rows = connection.execute(
            f"DESCRIBE SELECT * FROM read_parquet('{str(output_parquet).replace("'", "''")}')"
        ).fetchall()
        parquet_row_group_count = connection.execute(
            "SELECT COUNT(DISTINCT row_group_id) FROM parquet_metadata(?)",
            [str(output_parquet)],
        ).fetchone()[0]

        lookup_validation = None
        if output_lookup_parquet is not None:
            metadata_fields = [
                name for name in fieldnames if name not in {"text", "filtered"}
            ]
            metadata_projection = ", ".join(
                quote_identifier(name) for name in metadata_fields
            )
            connection.execute(
                "COPY (SELECT row_number() OVER () - 1 AS document_row_number, "
                f"{metadata_projection}, "
                "COALESCE(LENGTH(TRIM(text)) > 0, FALSE) AS has_text, "
                "COALESCE(LENGTH(TRIM(filtered)) > 0, FALSE) AS has_filtered "
                "FROM campaign_booklet) TO ? (FORMAT PARQUET, COMPRESSION ZSTD)",
                [str(output_lookup_parquet)],
            )
            lookup_stats = connection.execute(
                "SELECT COUNT(*), COUNT(DISTINCT document_row_number), "
                "MIN(document_row_number), MAX(document_row_number), "
                "COUNT(*) FILTER (WHERE has_text) "
                "FROM read_parquet(?)",
                [str(output_lookup_parquet)],
            ).fetchone()
            lookup_schema_rows = connection.execute(
                "DESCRIBE SELECT * FROM read_parquet(?)",
                [str(output_lookup_parquet)],
            ).fetchall()
            (
                lookup_row_count,
                distinct_positions,
                minimum_position,
                maximum_position,
                lookup_has_text_rows,
            ) = lookup_stats
            expected_lookup_columns = [
                "document_row_number",
                *metadata_fields,
                "has_text",
                "has_filtered",
            ]
            expected_lookup_types = {
                "document_row_number": "BIGINT",
                **{name: duckdb_types[name] for name in metadata_fields},
                "has_text": "BOOLEAN",
                "has_filtered": "BOOLEAN",
            }
            lookup_columns = [row[0] for row in lookup_schema_rows]
            lookup_types = {
                row[0]: normalize_type(row[1]) for row in lookup_schema_rows
            }
            lookup_validation = {
                "lookup_schema_match": (
                    lookup_columns == expected_lookup_columns
                    and lookup_types == expected_lookup_types
                ),
                "lookup_positions_valid": (
                    lookup_row_count == distinct_positions
                    and minimum_position == 0
                    and maximum_position == lookup_row_count - 1
                ),
                "lookup_row_count": lookup_row_count,
                "lookup_row_count_match": lookup_row_count == csv_row_count,
                "lookup_has_text_rows": lookup_has_text_rows,
            }
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
    if lookup_validation is not None and not all(
        lookup_validation[key]
        for key in (
            "lookup_schema_match",
            "lookup_positions_valid",
            "lookup_row_count_match",
        )
    ):
        raise SystemExit("Lookup Parquet validation failed.")
    if summary_json is not None:
        update_summary(
            summary_json,
            output_parquet,
            output_lookup_parquet,
            csv_row_count,
            parquet_row_count,
            schema_ok,
            parquet_row_group_count,
            lookup_validation,
        )

    print(json.dumps({
        'input_csv': str(input_csv),
        'output_parquet': str(output_parquet),
        'csv_row_count': csv_row_count,
        'parquet_row_count': parquet_row_count,
        'parquet_row_group_count': parquet_row_group_count,
        'schema_ok': schema_ok,
        'parquet_size_bytes': output_parquet.stat().st_size,
        'parquet_sha256': sha256_file(output_parquet),
        'lookup_parquet': (
            None
            if output_lookup_parquet is None
            else {
                'path': str(output_lookup_parquet),
                'size_bytes': output_lookup_parquet.stat().st_size,
                'sha256': sha256_file(output_lookup_parquet),
                **(lookup_validation or {}),
            }
        ),
    }, ensure_ascii=False, indent=2))


if __name__ == '__main__':
    main()
