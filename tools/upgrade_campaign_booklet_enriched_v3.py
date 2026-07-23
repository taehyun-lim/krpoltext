#!/usr/bin/env python
from __future__ import annotations

import argparse
import csv
import importlib
import itertools
import json
import sys
from collections import Counter
from pathlib import Path
from typing import Any

try:
    from tools.build_campaign_booklet_enriched_duckdb import (
        DEBUG_FIELDNAMES,
        DEFAULT_MATCHER_VERSION,
        LINKAGE_COLUMNS,
        audit_debug_csv,
        audit_enriched_csv,
        build_summary,
        coerce_for_schema,
        count_csv_rows,
        create_parquet_from_csv,
        load_schema,
    )
except ModuleNotFoundError:
    from build_campaign_booklet_enriched_duckdb import (
        DEBUG_FIELDNAMES,
        DEFAULT_MATCHER_VERSION,
        LINKAGE_COLUMNS,
        audit_debug_csv,
        audit_enriched_csv,
        build_summary,
        coerce_for_schema,
        count_csv_rows,
        create_parquet_from_csv,
        load_schema,
    )


BASE_MATCHER_VERSION = "campaign-booklet-enrichment-rowsearch-v2"
BASE_OMITTED_RAW_FIELDS = {"text", "filtered"}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Rebuild the full v3 enriched campaign-booklet artifacts from the raw corpus and a "
            "previously audited v2 linkage snapshot. This is valid because v2 and v3 resolution "
            "policies are equivalent over the matcher's three-decimal confidence domain."
        )
    )
    parser.add_argument("--krpoltext-repo", default=str(Path(__file__).resolve().parents[1]))
    parser.add_argument("--mcp-repo", required=True)
    parser.add_argument("--raw-csv", required=True)
    parser.add_argument("--base-linkage-csv", required=True)
    parser.add_argument("--output-dir", default="enriched")
    parser.add_argument("--output-csv", default="sk_election_campaign_booklet_enriched_v2022.csv")
    parser.add_argument("--output-parquet", default="sk_election_campaign_booklet_enriched_v2022.parquet")
    parser.add_argument("--debug-csv", default="campaign_booklet_linkage_debug.csv")
    parser.add_argument("--summary-json", default="campaign_booklet_build_summary.json")
    parser.add_argument("--matcher-version", default=DEFAULT_MATCHER_VERSION)
    parser.add_argument("--overwrite", action="store_true")
    return parser.parse_args()


def clean(value: Any) -> str:
    return str(value or "").strip()


def resolution_policies_equivalent() -> bool:
    for top_milli in range(1001):
        for runner_milli in range(top_milli + 1):
            top = top_milli / 1000
            runner = runner_milli / 1000
            old_gap_is_sufficient = round(top - runner, 3) >= 0.08
            new_gap_is_sufficient = top - runner + 1e-12 >= 0.08
            if old_gap_is_sufficient != new_gap_is_sufficient:
                return False
    return True


def ensure_base_audit_is_safe(base_audit: dict[str, Any]) -> None:
    critical_counts = {
        "invalid_status_rows": base_audit["invalid_status_rows"],
        "resolved_missing_huboid": base_audit["resolved_missing_huboid"],
        "unresolved_with_huboid": base_audit["unresolved_with_huboid"],
        "resolved_missing_scope": base_audit["resolved_missing_scope"],
        "invalid_scope_rows": base_audit["invalid_scope_rows"],
        "invalid_huboid_rows": base_audit["invalid_huboid_rows"],
        "unreviewed_identity_conflict_target_groups": base_audit[
            "unreviewed_identity_conflict_target_groups"
        ],
    }
    failures = {name: count for name, count in critical_counts.items() if count}
    if failures:
        raise SystemExit(f"Base linkage snapshot failed critical audit checks: {failures}")
    if base_audit["matcher_versions"] != [BASE_MATCHER_VERSION]:
        raise SystemExit(
            f"Expected only {BASE_MATCHER_VERSION!r} in the base linkage snapshot; "
            f"found {base_audit['matcher_versions']!r}."
        )
    if len(base_audit["nec_snapshot_ids"]) != 1:
        raise SystemExit("Base linkage snapshot must contain exactly one NEC snapshot ID.")


def debug_row(base_row: dict[str, Any], nec_snapshot_id: str) -> dict[str, Any]:
    return {
        "code": clean(base_row.get("code")) or None,
        "candidate_name": clean(base_row.get("name")) or None,
        "sg_id": clean(base_row.get("sg_id")) or None,
        "sg_typecode": clean(base_row.get("sg_typecode")) or None,
        "raw_region": clean(base_row.get("region")) or None,
        "canonical_region": clean(base_row.get("region")) or None,
        "district_label": clean(base_row.get("district")) or None,
        "link_status": clean(base_row.get("link_status")) or None,
        "message": (
            "Reused the audited v2 NEC linkage after exhaustive v2/v3 resolution-policy "
            f"equivalence verification; NEC snapshot remains {nec_snapshot_id}."
        ),
        "used_profiles": False,
        "top_huboid": clean(base_row.get("huboid")) or None,
        "top_candidate_name": clean(base_row.get("name")) or None,
        "top_party_name": clean(base_row.get("party")) or None,
        "top_district_label": clean(base_row.get("district")) or None,
        "top_confidence": None,
        "top_match_method": "audited_v2_equivalent",
        "top_strong_signals": None,
        "runner_huboid": None,
        "runner_confidence": None,
        "runner_match_method": None,
        "error": None,
    }


def main() -> None:
    args = parse_args()
    if args.matcher_version != DEFAULT_MATCHER_VERSION:
        raise SystemExit(f"This upgrader only supports the current v3 matcher {DEFAULT_MATCHER_VERSION!r}.")
    if not resolution_policies_equivalent():
        raise SystemExit("v2/v3 resolution policies are not equivalent over the confidence domain.")

    repo = Path(args.krpoltext_repo).resolve()
    mcp_repo = Path(args.mcp_repo).resolve()
    raw_csv = Path(args.raw_csv).resolve()
    base_csv = Path(args.base_linkage_csv).resolve()
    output_dir = (repo / args.output_dir).resolve()
    output_dir.mkdir(parents=True, exist_ok=True)
    output_csv = output_dir / args.output_csv
    output_parquet = output_dir / args.output_parquet
    debug_csv = output_dir / args.debug_csv
    summary_json = output_dir / args.summary_json

    if not args.overwrite and any(path.exists() for path in (output_csv, output_parquet, debug_csv, summary_json)):
        raise SystemExit("Output artifacts already exist; pass --overwrite to replace them.")
    if args.overwrite:
        for path in (output_csv, output_parquet, debug_csv, summary_json):
            if path.exists():
                path.unlink()

    if str(mcp_repo) not in sys.path:
        sys.path.insert(0, str(mcp_repo))
    from app.normalize import map_party_name, normalize_candidate_name, normalize_district_name

    base_audit = audit_enriched_csv(
        base_csv,
        normalize_candidate_name=normalize_candidate_name,
        normalize_district_name=normalize_district_name,
        map_party_name=map_party_name,
    )
    ensure_base_audit_is_safe(base_audit)
    nec_snapshot_id = base_audit["nec_snapshot_ids"][0]

    fieldnames, type_map, duckdb_type_map = load_schema(repo)
    counts: Counter[str] = Counter()
    row_count = 0
    with (
        raw_csv.open("r", encoding="utf-8-sig", newline="") as raw_handle,
        base_csv.open("r", encoding="utf-8", newline="") as base_handle,
        output_csv.open("w", encoding="utf-8", newline="") as output_handle,
        debug_csv.open("w", encoding="utf-8", newline="") as debug_handle,
    ):
        raw_reader = csv.DictReader(raw_handle)
        base_reader = csv.DictReader(base_handle)
        output_writer = csv.DictWriter(output_handle, fieldnames=fieldnames)
        debug_writer = csv.DictWriter(debug_handle, fieldnames=DEBUG_FIELDNAMES)
        output_writer.writeheader()
        debug_writer.writeheader()

        base_metadata_fields = [
            field
            for field in fieldnames
            if field not in LINKAGE_COLUMNS and field not in BASE_OMITTED_RAW_FIELDS
        ]
        missing_raw_fields = sorted(set(base_metadata_fields) - set(raw_reader.fieldnames or ()))
        missing_base_fields = sorted(set(base_metadata_fields) - set(base_reader.fieldnames or ()))
        if missing_raw_fields or missing_base_fields:
            raise SystemExit(
                "Raw/base metadata columns are incomplete: "
                f"raw_missing={missing_raw_fields}, base_missing={missing_base_fields}."
            )

        for row_count, pair in enumerate(itertools.zip_longest(raw_reader, base_reader), start=1):
            raw_row, base_row = pair
            if raw_row is None or base_row is None:
                raise SystemExit(f"Raw/base row counts diverged at row {row_count}.")
            normalized_raw = coerce_for_schema(base_metadata_fields, type_map, raw_row)
            normalized_base = coerce_for_schema(base_metadata_fields, type_map, base_row)
            for field in base_metadata_fields:
                if normalized_raw[field] != normalized_base[field]:
                    raise SystemExit(f"Raw/base metadata mismatch at row {row_count}, field {field!r}.")

            enriched = dict(raw_row)
            for field in ("huboid", "sg_id", "sg_typecode", "link_status"):
                enriched[field] = base_row.get(field)
            enriched["matcher_version"] = args.matcher_version
            enriched["nec_snapshot_id"] = nec_snapshot_id
            output_writer.writerow(coerce_for_schema(fieldnames, type_map, enriched))
            debug_writer.writerow(debug_row(base_row, nec_snapshot_id))
            counts[clean(base_row.get("link_status")) or "not_found"] += 1
            if row_count % 5000 == 0:
                print(f"Rebuilt {row_count:,} rows.", flush=True)

    output_audit = audit_enriched_csv(
        output_csv,
        normalize_candidate_name=normalize_candidate_name,
        normalize_district_name=normalize_district_name,
        map_party_name=map_party_name,
    )
    debug_audit = audit_debug_csv(debug_csv, expected_fieldnames=DEBUG_FIELDNAMES)
    raw_row_count = count_csv_rows(raw_csv, encoding="utf-8-sig")
    validation = {
        "resolution_policy_equivalent": True,
        "base_matcher_version": BASE_MATCHER_VERSION,
        "base_nec_snapshot_id": nec_snapshot_id,
        "base_metadata_fields_compared": base_metadata_fields,
        "base_metadata_fields_match": True,
        "raw_row_count": raw_row_count,
        "csv_row_count": output_audit["row_count"],
        "debug_row_count": debug_audit["row_count"],
        "row_count_preserved": raw_row_count == row_count == output_audit["row_count"],
        "debug_row_count_match": debug_audit["row_count"] == output_audit["row_count"],
        "debug_header_match": debug_audit["header_match"],
        "no_processing_errors": debug_audit["processing_error_rows"] == 0,
        "valid_link_statuses": output_audit["invalid_status_rows"] == 0,
        "resolved_requires_huboid": output_audit["resolved_missing_huboid"] == 0,
        "unresolved_clears_huboid": output_audit["unresolved_with_huboid"] == 0,
        "resolved_requires_scope": output_audit["resolved_missing_scope"] == 0,
        "scope_format_valid": output_audit["invalid_scope_rows"] == 0,
        "huboid_format_valid": output_audit["invalid_huboid_rows"] == 0,
        "linkage_provenance_complete": (
            output_audit["missing_matcher_version_rows"] == 0
            and output_audit["missing_nec_snapshot_id_rows"] == 0
        ),
        "matcher_version_consistent": output_audit["matcher_versions"] == [args.matcher_version],
        "nec_snapshot_id_consistent": output_audit["nec_snapshot_ids"] == [nec_snapshot_id],
        "no_unreviewed_identity_conflicts": output_audit["unreviewed_identity_conflict_target_groups"] == 0,
        "base_linkage_audit": base_audit,
        "linkage_audit": output_audit,
    }
    failed = [name for name, value in validation.items() if isinstance(value, bool) and not value]
    if failed:
        raise SystemExit(f"v3 CSV validation failed: {failed}")

    duckdb_module = importlib.import_module("duckdb")
    parquet_validation = create_parquet_from_csv(
        duckdb_module,
        output_csv=output_csv,
        output_parquet=output_parquet,
        fieldnames=fieldnames,
        type_map=type_map,
        duckdb_type_map=duckdb_type_map,
    )
    validation.update(
        {
            "csv_parquet_schema_match": (
                parquet_validation["parquet_columns_match"] and parquet_validation["parquet_types_match"]
            ),
            "parquet_row_count": parquet_validation["parquet_row_count"],
            "csv_parquet_row_count_match": (
                parquet_validation["csv_row_count"]
                == parquet_validation["parquet_row_count"]
                == output_audit["row_count"]
            ),
            "parquet_skipped": False,
        }
    )
    if not validation["csv_parquet_schema_match"] or not validation["csv_parquet_row_count_match"]:
        raise SystemExit("v3 Parquet validation failed.")

    summary = build_summary(
        output_csv=output_csv,
        output_parquet=output_parquet,
        debug_csv=debug_csv,
        raw_csv=raw_csv,
        matcher_version=args.matcher_version,
        nec_snapshot_id=nec_snapshot_id,
        counts=counts,
        total_rows=row_count,
        validation=validation,
        include_parquet=True,
    )
    summary["build_mode"] = "audited_v2_linkage_upgrade"
    summary["base_linkage_csv"] = str(base_csv)
    summary_json.write_text(json.dumps(summary, ensure_ascii=False, indent=2), encoding="utf-8")
    print(json.dumps(summary, ensure_ascii=False, indent=2), flush=True)


if __name__ == "__main__":
    main()
