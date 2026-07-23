#!/usr/bin/env python
from __future__ import annotations

import argparse
import csv
import hashlib
import importlib
import json
import re
import sys
import threading
import time
from collections import Counter
from concurrent.futures import ThreadPoolExecutor, as_completed
from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

RAW_CAMPAIGN_BOOKLET_URL = "https://osf.io/download/6ybj8/"
LINKAGE_COLUMNS = (
    "huboid",
    "sg_id",
    "sg_typecode",
    "link_status",
    "matcher_version",
    "nec_snapshot_id",
)
DEFAULT_MATCHER_VERSION = "campaign-booklet-enrichment-rowsearch-v3"
DEFAULT_CANDIDATE_LIMIT = 50
DEFAULT_PROFILE_LIMIT = 5
DEFAULT_REQUEST_DELAY_SECONDS = 0.0
MIN_RESOLUTION_GAP = 0.08
FLOAT_COMPARISON_EPSILON = 1e-12
AUDIT_EXAMPLE_LIMIT = 20
VALID_LINK_STATUSES = {"resolved", "ambiguous", "not_found", "rejected"}
DEBUG_FIELDNAMES = [
    "code", "candidate_name", "sg_id", "sg_typecode", "raw_region", "canonical_region",
    "district_label", "link_status", "message", "used_profiles", "top_huboid",
    "top_candidate_name", "top_party_name", "top_district_label", "top_confidence",
    "top_match_method", "top_strong_signals", "runner_huboid", "runner_confidence",
    "runner_match_method", "error",
]
DUCKDB_TYPE_MAP = {"integer": "BIGINT", "character": "VARCHAR"}
PROPORTIONAL_KEYWORD = "\ube44\ub840"
RETRYABLE_HTTP_MARKERS = ("429", "Too Many Requests", "rate limit")
OFFICE_NAME_TO_SG_TYPECODE = {
    "president": "1",
    "national_assembly": "2",
    "metro_head": "3",
    "basic_head": "4",
    "metro_assembly": "5",
    "basic_assembly": "6",
    "education_superintendent": "11",
}
PROPORTIONAL_OFFICE_TO_SG_TYPECODE = {
    "national_assembly": "7",
    "metro_assembly": "8",
    "basic_assembly": "9",
}
REGION_ALIASES = {
    "\uc11c\uc6b8": "\uc11c\uc6b8\ud2b9\ubcc4\uc2dc",
    "\ubd80\uc0b0": "\ubd80\uc0b0\uad11\uc5ed\uc2dc",
    "\ub300\uad6c": "\ub300\uad6c\uad11\uc5ed\uc2dc",
    "\uc778\ucc9c": "\uc778\ucc9c\uad11\uc5ed\uc2dc",
    "\uad11\uc8fc": "\uad11\uc8fc\uad11\uc5ed\uc2dc",
    "\ub300\uc804": "\ub300\uc804\uad11\uc5ed\uc2dc",
    "\uc6b8\uc0b0": "\uc6b8\uc0b0\uad11\uc5ed\uc2dc",
    "\uc138\uc885": "\uc138\uc885\ud2b9\ubcc4\uc790\uce58\uc2dc",
    "\uacbd\uae30": "\uacbd\uae30\ub3c4",
    "\uac15\uc6d0": "\uac15\uc6d0\ub3c4",
    "\ucda9\ubd81": "\ucda9\uccad\ubd81\ub3c4",
    "\ucda9\ub0a8": "\ucda9\uccad\ub0a8\ub3c4",
    "\uc804\ubd81": "\uc804\ub77c\ubd81\ub3c4",
    "\uc804\ub0a8": "\uc804\ub77c\ub0a8\ub3c4",
    "\uacbd\ubd81": "\uacbd\uc0c1\ubd81\ub3c4",
    "\uacbd\ub0a8": "\uacbd\uc0c1\ub0a8\ub3c4",
    "\uc81c\uc8fc": "\uc81c\uc8fc\ud2b9\ubcc4\uc790\uce58\ub3c4",
    "\uc81c\uc8fc\ub3c4": "\uc81c\uc8fc\ud2b9\ubcc4\uc790\uce58\ub3c4",
}


@dataclass(slots=True)
class Scope:
    sg_id: str | None
    sg_typecode: str | None
    raw_region: str | None
    canonical_region: str | None
    district_label: str | None
    district_raw: str | None


@dataclass(slots=True)
class CandidateScore:
    candidate: Any
    profile: Any | None
    confidence: float
    match_method: str | None
    warnings: list[str]
    strong_signal_count: int
    strong_signals: list[str]
    base_exact: bool
    identity_verified: bool


@dataclass(frozen=True, slots=True)
class ManualReviewOverride:
    status: str
    message: str
    huboid: str | None = None
    accepted_candidate_names: tuple[str, ...] = ()


@dataclass(slots=True)
class TargetAudit:
    row_count: int = 0
    names: set[str] = field(default_factory=set)
    parties: set[str] = field(default_factory=set)
    gihos: set[str] = field(default_factory=set)
    regions: set[str] = field(default_factory=set)
    districts: set[str] = field(default_factory=set)
    birthdays: set[str] = field(default_factory=set)
    codes: set[str] = field(default_factory=set)
    first_row: dict[str, str | None] | None = None
    duplicate_rows: list[dict[str, str | None]] = field(default_factory=list)


MANUAL_REVIEW_OVERRIDES: dict[tuple[str, str, str, str, str, str, str], ManualReviewOverride] = {
    (
        "2010-06-02",
        "김광모",
        "부산광역시",
        "",
        "basic_assembly",
        "미래연합",
        "8",
    ): ManualReviewOverride(
        status="not_found",
        message="Manual review kept the row unresolved because the NEC 김광모 record belongs to 진보신당/giho 7, not 미래연합/giho 8.",
    ),
    (
        "2010-06-02",
        "이동섭",
        "충청북도",
        "",
        "basic_assembly",
        "자유선진당",
        "3나",
    ): ManualReviewOverride(
        status="not_found",
        message="Manual review kept the row unresolved because the 충청남도 공주시가선거구 candidate cannot be reused for this 충청북도 row.",
    ),
    (
        "2012-04-11",
        "우효태",
        "경기도",
        "",
        "national_assembly",
        "무소속",
        "8",
    ): ManualReviewOverride(
        status="not_found",
        message="Manual review kept the row unresolved because 우호태/100102126 remained too weak given the material giho mismatch.",
    ),
    (
        "2014-06-04",
        "강명용",
        "경기도",
        "",
        "basic_head",
        "통합진보당",
        "3",
    ): ManualReviewOverride(
        status="ambiguous",
        message="Manual review kept the row ambiguous because 강명룡/100112604 is plausible OCR drift, but district evidence is still insufficient.",
    ),
    (
        "2014-06-04",
        "김대남",
        "울산광역시",
        "",
        "basic_head",
        "새정치민주연합",
        "2",
    ): ManualReviewOverride(
        status="not_found",
        message="Manual review kept the row unresolved because no safe region-constrained NEC candidate remained.",
    ),
    (
        "2018-06-13",
        "권해정",
        "경기도",
        "",
        "metro_assembly",
        "자유한국당",
        "2",
    ): ManualReviewOverride(
        status="resolved",
        message="Manual review resolved the row to NEC huboid 100125215 despite the 권해정/권혜정 OCR variation.",
        huboid="100125215",
        accepted_candidate_names=("권해정", "권혜정"),
    ),
}


def parse_args() -> argparse.Namespace:
    build_stamp = datetime.now(timezone.utc).strftime("%Y%m%d")
    parser = argparse.ArgumentParser(
        description=(
            "Build the enriched campaign_booklet artifact by attaching conservative "
            "NEC linkage fields to the raw krpoltext rows."
        )
    )
    parser.add_argument("--krpoltext-repo", default=None)
    parser.add_argument("--mcp-repo", required=True)
    parser.add_argument("--raw-url", default=RAW_CAMPAIGN_BOOKLET_URL)
    parser.add_argument("--output-dir", default="enriched")
    parser.add_argument("--source-dir", default="enriched/source")
    parser.add_argument("--raw-csv", default=None)
    parser.add_argument("--output-csv", default="sk_election_campaign_booklet_enriched_v2022.csv")
    parser.add_argument("--output-parquet", default="sk_election_campaign_booklet_enriched_v2022.parquet")
    parser.add_argument("--debug-csv", default="campaign_booklet_linkage_debug.csv")
    parser.add_argument("--summary-json", default="campaign_booklet_build_summary.json")
    parser.add_argument("--matcher-version", default=DEFAULT_MATCHER_VERSION)
    parser.add_argument("--nec-snapshot-id", default=f"nec-openapi-live-{build_stamp}")
    parser.add_argument("--candidate-limit", type=int, default=DEFAULT_CANDIDATE_LIMIT)
    parser.add_argument("--profile-limit", type=int, default=DEFAULT_PROFILE_LIMIT)
    parser.add_argument(
        "--prefetch-workers",
        type=int,
        default=0,
        help="Pre-cache unique NEC candidate-name queries with this many workers before row linkage (0 disables).",
    )
    parser.add_argument("--request-delay-seconds", type=float, default=DEFAULT_REQUEST_DELAY_SECONDS)
    parser.add_argument("--skip-parquet", action="store_true")
    parser.add_argument("--overwrite", action="store_true")
    parser.add_argument("--cache-dir", default=None)
    parser.add_argument("--env-file", default=None)
    return parser.parse_args()


def ensure_dependency(name: str, package: str | None = None) -> Any:
    try:
        return importlib.import_module(name)
    except ImportError as exc:
        install_name = package or name
        raise SystemExit(
            f"Missing Python dependency '{install_name}'. "
            "Install it into the kr-elections-mcp virtual environment before running this build."
        ) from exc


def add_mcp_repo_to_path(mcp_repo: Path) -> None:
    if str(mcp_repo) not in sys.path:
        sys.path.insert(0, str(mcp_repo))


def load_schema(repo_root: Path) -> tuple[list[str], dict[str, str], dict[str, str]]:
    schema_path = repo_root / "docs" / "data" / "schema" / "campaign_booklet_enriched.json"
    payload = json.loads(schema_path.read_text(encoding="utf-8"))
    columns = payload["columns"]
    fieldnames = [column["name"] for column in columns]
    type_map = {column["name"]: column["type"] for column in columns}
    return fieldnames, type_map, {name: DUCKDB_TYPE_MAP[type_map[name]] for name in fieldnames}


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def download_file(requests_module: Any, url: str, destination: Path) -> Path:
    destination.parent.mkdir(parents=True, exist_ok=True)
    response = requests_module.get(url, stream=True, timeout=120)
    response.raise_for_status()
    with destination.open("wb") as handle:
        for chunk in response.iter_content(chunk_size=1024 * 1024):
            if chunk:
                handle.write(chunk)
    return destination


def resolve_output_path(base_dir: Path, value: str) -> Path:
    candidate = Path(value)
    return candidate if candidate.is_absolute() else base_dir / candidate


def normalize_region(region: str | None) -> str | None:
    text = (region or "").strip()
    if not text or text in {"\uad11\uc5ed", "\uc81c\uc8fc\ud2b9\ubcc4"}:
        return None
    return REGION_ALIASES.get(text, text)


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
        match = re.search(r"-?\d+", text)
        if match:
            return int(match.group(0))
        return None


def extract_sg_id(date_value: Any) -> str | None:
    digits = "".join(character for character in str(date_value or "") if character.isdigit())
    return digits[:8] if len(digits) >= 8 else None


def infer_sg_typecode(row: dict[str, Any]) -> str | None:
    office_id = clean_int(row.get("office_id"))
    office_name = clean_text(row.get("office"))
    district = clean_text(row.get("district")) or ""
    if PROPORTIONAL_KEYWORD in district and office_name in PROPORTIONAL_OFFICE_TO_SG_TYPECODE:
        return PROPORTIONAL_OFFICE_TO_SG_TYPECODE[office_name]
    if office_id is not None:
        # Raw campaign_booklet rows already carry NEC-style election type codes
        # for most elections, so keep the native value when present.
        return str(office_id)
    return OFFICE_NAME_TO_SG_TYPECODE.get(office_name)


def build_scope(row: dict[str, Any], build_region_district_label: Any) -> Scope:
    region = clean_text(row.get("region"))
    district = clean_text(row.get("district"))
    return Scope(
        sg_id=extract_sg_id(row.get("date")),
        sg_typecode=infer_sg_typecode(row),
        raw_region=region,
        canonical_region=normalize_region(region),
        district_label=build_region_district_label(region, district),
        district_raw=district,
    )


def make_row_record(row: dict[str, Any], build_region_district_label: Any, KrPolTextMetaRecord: Any) -> Any:
    sg_id = extract_sg_id(row.get("date"))
    return KrPolTextMetaRecord(
        record_id=str(clean_text(row.get("code")) or "campaign_booklet-row"),
        code=clean_text(row.get("code")),
        candidate_name=clean_text(row.get("name")),
        office_id=clean_int(row.get("office_id")),
        office_name=clean_text(row.get("office")),
        election_year=clean_int(sg_id[:4] if sg_id else None),
        region_name=clean_text(row.get("region")),
        district_raw=clean_text(row.get("district")),
        district_name=build_region_district_label(clean_text(row.get("region")), clean_text(row.get("district"))),
        giho=clean_text(row.get("giho")),
        party_name=clean_text(row.get("party")),
        party_name_eng=clean_text(row.get("party_eng")),
        result=clean_text(row.get("result")),
        result_code=clean_int(row.get("result_code")),
        sex=clean_text(row.get("sex")),
        sex_code=clean_int(row.get("sex_code")),
        birthday=clean_text(row.get("birthday")),
        age=clean_int(row.get("age")),
        job_id=clean_text(row.get("job_id")),
        job=clean_text(row.get("job")),
        job_name=clean_text(row.get("job_name")),
        job_name_eng=clean_text(row.get("job_name_eng")),
        job_code=clean_int(row.get("job_code")),
        edu_id=clean_text(row.get("edu_id")),
        edu=clean_text(row.get("edu")),
        edu_name=clean_text(row.get("edu_name")),
        edu_name_eng=clean_text(row.get("edu_name_eng")),
        edu_code=clean_int(row.get("edu_code")),
        career1=clean_text(row.get("career1")),
        career2=clean_text(row.get("career2")),
        page_count=clean_int(row.get("pages")),
        has_text=bool(clean_text(row.get("text")) or clean_text(row.get("filtered"))),
        dataset_version=None,
        source="krpoltext",
        source_url=None,
        time_range=clean_text(row.get("date")),
        warnings=[],
        raw_fields={},
    )


def _normalized_comparison(value: Any) -> str:
    return re.sub(r"\s+", "", clean_text(value) or "").casefold()


def _add_normalized(values: set[str], value: Any, normalizer: Any = _normalized_comparison) -> None:
    cleaned = clean_text(value)
    if not cleaned:
        return
    normalized = clean_text(normalizer(cleaned))
    if normalized:
        values.add(normalized)


def _audit_row_summary(row: dict[str, Any]) -> dict[str, str | None]:
    return {
        name: clean_text(row.get(name))
        for name in (
            "date",
            "name",
            "region",
            "district",
            "office",
            "giho",
            "party",
            "birthday",
            "code",
            "huboid",
            "sg_id",
            "sg_typecode",
            "link_status",
        )
    }


def _manual_reviewed_identity_names(
    normalize_candidate_name: Any,
) -> dict[tuple[str, str, str], set[str]]:
    targets: dict[tuple[str, str, str], set[str]] = {}
    for review_key, override in MANUAL_REVIEW_OVERRIDES.items():
        if override.status != "resolved" or not override.huboid:
            continue
        date_value, source_name, _, district, office, _, _ = review_key
        sg_id = extract_sg_id(date_value)
        sg_typecode = infer_sg_typecode({"date": date_value, "office": office, "district": district})
        if sg_id and sg_typecode:
            accepted_names = override.accepted_candidate_names or (source_name,)
            normalized_names = {
                normalized
                for name in accepted_names
                if (normalized := clean_text(normalize_candidate_name(name)))
            }
            targets[(sg_id, sg_typecode, override.huboid)] = normalized_names
    return targets


def count_csv_rows(path: Path, *, encoding: str = "utf-8") -> int:
    with path.open("r", encoding=encoding, newline="") as handle:
        reader = csv.reader(handle)
        if next(reader, None) is None:
            return 0
        return sum(1 for _ in reader)


def collect_candidate_names(raw_csv: Path) -> list[str]:
    names: set[str] = set()
    with raw_csv.open("r", encoding="utf-8-sig", newline="") as handle:
        for row in csv.DictReader(handle):
            name = clean_text(row.get("name"))
            if name:
                names.add(name)
    return sorted(names)


def prefetch_candidate_name_rows(
    *,
    raw_csv: Path,
    workers: int,
    settings: Any,
    NecApiClient: Any,
) -> dict[str, int]:
    if workers <= 0:
        return {
            "candidate_names": 0,
            "attempted": 0,
            "completed": 0,
            "errors": 0,
            "skipped": 0,
            "rate_limited": 0,
        }

    candidate_names = collect_candidate_names(raw_csv)
    thread_state = threading.local()
    stop_event = threading.Event()

    def fetch_name(candidate_name: str) -> bool:
        if stop_event.is_set():
            return False
        client = getattr(thread_state, "nec_client", None)
        if client is None:
            client = NecApiClient(settings)
            thread_state.nec_client = client
        try:
            client._request_paginated_rows(
                "candidate_search_name",
                {"name": candidate_name},
                max_pages=20,
            )
        except Exception as exc:
            if any(marker.lower() in str(exc).lower() for marker in RETRYABLE_HTTP_MARKERS):
                stop_event.set()
            raise
        return True

    completed = 0
    attempted = 0
    errors = 0
    skipped = 0
    rate_limited = 0
    print(
        f"Pre-caching {len(candidate_names):,} unique candidate-name queries with {workers} workers.",
        flush=True,
    )
    with ThreadPoolExecutor(max_workers=workers, thread_name_prefix="nec-name-prefetch") as executor:
        futures = {executor.submit(fetch_name, name): name for name in candidate_names}
        for future in as_completed(futures):
            try:
                if future.result():
                    attempted += 1
                    completed += 1
                else:
                    skipped += 1
            except Exception as exc:
                attempted += 1
                errors += 1
                if any(marker.lower() in str(exc).lower() for marker in RETRYABLE_HTTP_MARKERS):
                    rate_limited = 1
                    stop_event.set()
            settled = completed + errors + skipped
            if settled % 500 == 0 or settled == len(candidate_names):
                print(
                    f"Pre-cached {completed:,}/{len(candidate_names):,} candidate names "
                    f"(errors={errors:,}, skipped={skipped:,}).",
                    flush=True,
                )

    if errors:
        print(
            "Some candidate-name prefetches failed; row linkage will retry them through the normal path.",
            flush=True,
        )
    return {
        "candidate_names": len(candidate_names),
        "attempted": attempted,
        "completed": completed,
        "errors": errors,
        "skipped": skipped,
        "rate_limited": rate_limited,
    }


def audit_enriched_csv(
    output_csv: Path,
    *,
    normalize_candidate_name: Any,
    normalize_district_name: Any,
    map_party_name: Any,
) -> dict[str, Any]:
    status_counts: Counter[str] = Counter()
    invalid_status_rows = 0
    resolved_missing_huboid = 0
    unresolved_with_huboid = 0
    resolved_missing_scope = 0
    invalid_scope_rows = 0
    invalid_huboid_rows = 0
    target_audits: dict[tuple[str, str, str], TargetAudit] = {}
    code_counts: Counter[str] = Counter()
    code_targets: dict[str, set[tuple[str, str, str]]] = {}
    code_first_rows: dict[str, dict[str, str | None]] = {}
    code_examples: dict[str, list[dict[str, str | None]]] = {}
    matcher_versions: set[str] = set()
    nec_snapshot_ids: set[str] = set()
    missing_matcher_version_rows = 0
    missing_nec_snapshot_id_rows = 0
    total_rows = 0

    with output_csv.open("r", encoding="utf-8", newline="") as handle:
        reader = csv.DictReader(handle)
        for row in reader:
            total_rows += 1
            status = clean_text(row.get("link_status")) or ""
            huboid = clean_text(row.get("huboid"))
            sg_id = clean_text(row.get("sg_id"))
            sg_typecode = clean_text(row.get("sg_typecode"))
            matcher_version = clean_text(row.get("matcher_version"))
            nec_snapshot_id = clean_text(row.get("nec_snapshot_id"))
            status_counts[status or "missing"] += 1

            if matcher_version:
                matcher_versions.add(matcher_version)
            else:
                missing_matcher_version_rows += 1
            if nec_snapshot_id:
                nec_snapshot_ids.add(nec_snapshot_id)
            else:
                missing_nec_snapshot_id_rows += 1

            if status not in VALID_LINK_STATUSES:
                invalid_status_rows += 1
            if huboid and not huboid.isdigit():
                invalid_huboid_rows += 1
            if status == "resolved":
                if not huboid:
                    resolved_missing_huboid += 1
                if not sg_id or not sg_typecode:
                    resolved_missing_scope += 1
                elif not (len(sg_id) == 8 and sg_id.isdigit() and sg_typecode.isdigit()):
                    invalid_scope_rows += 1
            elif huboid:
                unresolved_with_huboid += 1

            target_key = (sg_id or "", sg_typecode or "", huboid or "")
            if status == "resolved" and all(target_key):
                target = target_audits.setdefault(target_key, TargetAudit())
                target.row_count += 1
                summary = _audit_row_summary(row)
                if target.first_row is None:
                    target.first_row = summary
                elif len(target.duplicate_rows) < 2:
                    if not target.duplicate_rows and target.first_row is not None:
                        target.duplicate_rows.append(target.first_row)
                    target.duplicate_rows.append(summary)

                _add_normalized(target.names, row.get("name"), normalize_candidate_name)
                _add_normalized(target.parties, row.get("party"), lambda value: _normalized_comparison(map_party_name(value)))
                _add_normalized(target.gihos, row.get("giho"), normalize_giho_text)
                _add_normalized(target.regions, row.get("region"), normalize_region)
                _add_normalized(target.districts, row.get("district"), normalize_district_name)
                _add_normalized(target.birthdays, row.get("birthday"), normalize_digits)
                _add_normalized(target.codes, row.get("code"))

            code = clean_text(row.get("code"))
            if code:
                code_counts[code] += 1
                code_targets.setdefault(code, set()).add(target_key)
                summary = _audit_row_summary(row)
                if code_counts[code] == 1:
                    code_first_rows[code] = summary
                else:
                    examples = code_examples.get(code)
                    if examples is None:
                        examples = [code_first_rows.pop(code)]
                        code_examples[code] = examples
                    if len(examples) < 3:
                        examples.append(summary)

    duplicate_targets = {key: audit for key, audit in target_audits.items() if audit.row_count > 1}
    reviewed_identity_names = _manual_reviewed_identity_names(normalize_candidate_name)
    identity_conflict_targets = {
        key: audit
        for key, audit in duplicate_targets.items()
        if len(audit.names) > 1 or len(audit.birthdays) > 1 or len(audit.gihos) > 1
    }
    reviewed_identity_conflicts = {
        key: audit
        for key, audit in identity_conflict_targets.items()
        if key in reviewed_identity_names
        and len(audit.birthdays) <= 1
        and len(audit.gihos) <= 1
        and audit.names.issubset(reviewed_identity_names[key])
    }
    unreviewed_identity_conflicts = {
        key: audit for key, audit in identity_conflict_targets.items() if key not in reviewed_identity_conflicts
    }
    party_conflicts = {key: audit for key, audit in duplicate_targets.items() if len(audit.parties) > 1}
    region_conflicts = {key: audit for key, audit in duplicate_targets.items() if len(audit.regions) > 1}
    district_conflicts = {key: audit for key, audit in duplicate_targets.items() if len(audit.districts) > 1}
    duplicate_codes = {code: count for code, count in code_counts.items() if count > 1}
    conflicting_codes = {
        code: count for code, count in duplicate_codes.items() if len(code_targets.get(code, set())) > 1
    }

    def target_examples(items: dict[tuple[str, str, str], TargetAudit]) -> list[dict[str, Any]]:
        return [
            {
                "sg_id": key[0],
                "sg_typecode": key[1],
                "huboid": key[2],
                "row_count": audit.row_count,
                "rows": audit.duplicate_rows,
            }
            for key, audit in list(sorted(items.items()))[:AUDIT_EXAMPLE_LIMIT]
        ]

    return {
        "row_count": total_rows,
        "status_counts": dict(status_counts),
        "invalid_status_rows": invalid_status_rows,
        "resolved_missing_huboid": resolved_missing_huboid,
        "unresolved_with_huboid": unresolved_with_huboid,
        "resolved_missing_scope": resolved_missing_scope,
        "invalid_scope_rows": invalid_scope_rows,
        "invalid_huboid_rows": invalid_huboid_rows,
        "missing_matcher_version_rows": missing_matcher_version_rows,
        "missing_nec_snapshot_id_rows": missing_nec_snapshot_id_rows,
        "matcher_versions": sorted(matcher_versions),
        "nec_snapshot_ids": sorted(nec_snapshot_ids),
        "resolved_distinct_targets": len(target_audits),
        "duplicate_target_groups": len(duplicate_targets),
        "duplicate_target_rows": sum(audit.row_count for audit in duplicate_targets.values()),
        "duplicate_target_extra_rows": sum(audit.row_count - 1 for audit in duplicate_targets.values()),
        "identity_conflict_target_groups": len(identity_conflict_targets),
        "unreviewed_identity_conflict_target_groups": len(unreviewed_identity_conflicts),
        "party_conflict_target_groups": len(party_conflicts),
        "region_conflict_target_groups": len(region_conflicts),
        "district_conflict_target_groups": len(district_conflicts),
        "duplicate_code_groups": len(duplicate_codes),
        "duplicate_code_rows": sum(duplicate_codes.values()),
        "conflicting_code_target_groups": len(conflicting_codes),
        "duplicate_target_examples": target_examples(duplicate_targets),
        "identity_conflict_examples": target_examples(identity_conflict_targets),
        "party_conflict_examples": target_examples(party_conflicts),
        "conflicting_code_examples": [
            {"code": code, "row_count": conflicting_codes[code], "rows": code_examples[code]}
            for code in list(sorted(conflicting_codes))[:AUDIT_EXAMPLE_LIMIT]
        ],
    }


def audit_debug_csv(
    debug_csv: Path,
    *,
    expected_fieldnames: list[str] | None = None,
) -> dict[str, Any]:
    row_count = 0
    processing_error_rows = 0
    with debug_csv.open("r", encoding="utf-8", newline="") as handle:
        reader = csv.DictReader(handle)
        header_match = expected_fieldnames is None or reader.fieldnames == expected_fieldnames
        for row in reader:
            row_count += 1
            if clean_text(row.get("error")):
                processing_error_rows += 1
    return {
        "row_count": row_count,
        "processing_error_rows": processing_error_rows,
        "header_match": header_match,
    }


def dedupe_candidates(candidates: list[Any]) -> list[Any]:
    seen: set[tuple[str | None, str | None, str | None]] = set()
    output: list[Any] = []
    for candidate in candidates:
        ref = candidate.candidate_ref
        marker = (ref.sg_id, ref.sg_typecode, ref.huboid or ref.candidacy_uid)
        if marker in seen:
            continue
        seen.add(marker)
        output.append(candidate)
    return output


def candidate_lookup_key(candidate: Any) -> str:
    ref = candidate.candidate_ref
    stable_id = clean_text(ref.huboid) or clean_text(ref.candidacy_uid)
    if stable_id:
        return '|'.join([clean_text(ref.sg_id) or '', clean_text(ref.sg_typecode) or '', stable_id])
    parts = [
        clean_text(ref.sg_id),
        clean_text(ref.sg_typecode),
        clean_text(ref.candidate_name),
        clean_text(candidate.party_name or ref.party_name),
        clean_text(candidate.giho or ref.giho),
        clean_text(ref.sd_name),
        clean_text(ref.sgg_name),
        clean_text(ref.wiw_name),
        clean_text(ref.district_label),
    ]
    return '|'.join(part or '' for part in parts)


def candidate_score_huboid(score: CandidateScore | None) -> str | None:
    if score is None:
        return None
    candidate_huboid = clean_text(score.candidate.candidate_ref.huboid)
    profile_huboid = clean_text(score.profile.candidate.candidate_ref.huboid) if score.profile else None
    return candidate_huboid or profile_huboid


def candidate_score_identity_key(score: CandidateScore) -> str:
    resolved_huboid = candidate_score_huboid(score)
    if resolved_huboid:
        ref = score.candidate.candidate_ref
        return '|'.join([clean_text(ref.sg_id) or '', clean_text(ref.sg_typecode) or '', resolved_huboid])
    return candidate_lookup_key(score.candidate)


def manual_review_key(row: dict[str, Any]) -> tuple[str, str, str, str, str, str, str]:
    return (
        clean_text(row.get("date")) or "",
        clean_text(row.get("name")) or "",
        normalize_region(clean_text(row.get("region"))) or "",
        clean_text(row.get("district")) or "",
        clean_text(row.get("office")) or "",
        clean_text(row.get("party")) or "",
        clean_text(row.get("giho")) or "",
    )


def select_score_by_huboid(scores: list[CandidateScore], huboid: str) -> CandidateScore | None:
    for score in scores:
        if candidate_score_huboid(score) == huboid:
            return score
    return None


def apply_manual_review_override(
    row: dict[str, Any],
    *,
    scores: list[CandidateScore],
    status: str,
    selected: CandidateScore | None,
    message: str,
) -> tuple[str, CandidateScore | None, str]:
    override = MANUAL_REVIEW_OVERRIDES.get(manual_review_key(row))
    if override is None:
        return status, selected, message
    if override.status == "resolved":
        if not override.huboid:
            raise RuntimeError(f"Resolved manual override for {manual_review_key(row)!r} is missing a huboid.")
        override_selected = select_score_by_huboid(scores, override.huboid)
        if override_selected is None:
            raise RuntimeError(
                f"Manual override for {manual_review_key(row)!r} expected huboid {override.huboid}, "
                "but the candidate was not present in the scored pool."
            )
        return override.status, override_selected, override.message
    return override.status, None, override.message


def is_retryable_exception(exc: Exception) -> bool:
    text = str(exc)
    return any(marker in text for marker in RETRYABLE_HTTP_MARKERS)


def call_with_retry(
    func: Any,
    *args: Any,
    request_delay_seconds: float = 0.0,
    **kwargs: Any,
) -> Any:
    delay_seconds = 2.0
    attempts = 5
    for attempt in range(1, attempts + 1):
        if request_delay_seconds > 0:
            time.sleep(request_delay_seconds)
        try:
            return func(*args, **kwargs)
        except Exception as exc:
            if attempt >= attempts or not is_retryable_exception(exc):
                raise
            time.sleep(delay_seconds)
            delay_seconds = min(delay_seconds * 2, 30.0)


def normalize_digits(value: Any) -> str:
    return "".join(character for character in str(value or "") if character.isdigit())


def normalize_giho_text(value: Any) -> str:
    text = clean_text(value)
    if not text:
        return ""
    digits = normalize_digits(text)
    return digits or text


def extract_candidate_raw_value(candidate: Any, first_of: Any, *names: str) -> str | None:
    return clean_text(first_of(candidate.raw_fields, *names))


def district_matches(
    candidate: Any,
    row_record: Any,
    *,
    normalize_district_name: Any,
    similarity: Any,
) -> bool:
    candidate_label = clean_text(candidate.candidate_ref.district_label)
    row_district = clean_text(row_record.district_name) or clean_text(row_record.district_raw)
    if not candidate_label or not row_district:
        return False
    candidate_norm = normalize_district_name(candidate_label)
    row_norm = normalize_district_name(row_district)
    if candidate_norm == row_norm:
        return True
    if candidate_norm and row_norm and (candidate_norm in row_norm or row_norm in candidate_norm):
        return True
    return similarity(candidate_label, row_district) >= 0.9


def region_matches(candidate: Any, row_record: Any) -> bool:
    row_region = normalize_region(clean_text(row_record.region_name))
    candidate_region = normalize_region(clean_text(candidate.candidate_ref.sd_name))
    if not row_region:
        return True
    if not candidate_region:
        return False
    return candidate_region == row_region


def party_matches(candidate: Any, row_record: Any, *, map_party_name: Any) -> bool:
    candidate_party = clean_text(candidate.party_name or candidate.candidate_ref.party_name)
    row_party = clean_text(row_record.party_name)
    if not candidate_party or not row_party:
        return False
    return map_party_name(candidate_party) == map_party_name(row_party)


def shared_field_filtered_pool(
    candidates: list[Any],
    row_record: Any,
    *,
    map_party_name: Any,
    normalize_district_name: Any,
    similarity: Any,
    first_of: Any,
) -> list[Any]:
    filtered = list(candidates)

    regional_matches = [candidate for candidate in filtered if region_matches(candidate, row_record)]
    if regional_matches:
        filtered = regional_matches
    elif clean_text(row_record.region_name):
        return []

    birthday_digits = normalize_digits(row_record.birthday)
    if birthday_digits:
        birthday_matches = [
            candidate
            for candidate in filtered
            if normalize_digits(extract_candidate_raw_value(candidate, first_of, "birthday", "birthDay", "birth")) == birthday_digits
        ]
        if birthday_matches:
            filtered = birthday_matches

    giho_value = normalize_giho_text(row_record.giho)
    if giho_value:
        giho_matches = [
            candidate
            for candidate in filtered
            if normalize_giho_text(candidate.giho or candidate.candidate_ref.giho) == giho_value
        ]
        if giho_matches:
            filtered = giho_matches

    district_candidates = [
        candidate
        for candidate in filtered
        if district_matches(
            candidate,
            row_record,
            normalize_district_name=normalize_district_name,
            similarity=similarity,
        )
    ]
    if district_candidates:
        filtered = district_candidates

    party_candidates = [candidate for candidate in filtered if party_matches(candidate, row_record, map_party_name=map_party_name)]
    if party_candidates:
        filtered = party_candidates

    age_value = clean_int(row_record.age)
    if age_value is not None:
        age_matches = [
            candidate
            for candidate in filtered
            if clean_int(extract_candidate_raw_value(candidate, first_of, "age", "ageNum")) == age_value
        ]
        if age_matches:
            filtered = age_matches

    sex_value = clean_text(row_record.sex)
    if sex_value:
        sex_matches = [
            candidate
            for candidate in filtered
            if clean_text(extract_candidate_raw_value(candidate, first_of, "gender", "sex")) == sex_value
        ]
        if sex_matches:
            filtered = sex_matches

    return dedupe_candidates(filtered)


def fetch_candidate_pool(
    nec_client: Any,
    search_cache: dict[tuple[str, str, str, str], list[Any]],
    row_record: Any,
    scope: Scope,
    *,
    candidate_limit: int,
    map_party_name: Any,
    normalize_district_name: Any,
    similarity: Any,
    first_of: Any,
    request_delay_seconds: float,
) -> list[Any]:
    if not row_record.candidate_name or not scope.sg_id or not scope.sg_typecode:
        return []

    search_regions: list[str | None] = []
    for region_name in (scope.raw_region, scope.canonical_region, None):
        cleaned = clean_text(region_name)
        if cleaned not in search_regions:
            search_regions.append(cleaned)

    district_hint = clean_text(row_record.district_name) or clean_text(row_record.district_raw)
    candidates: list[Any] = []
    seen_variants: set[tuple[str | None, str | None]] = set()

    def run_search(region_name: str | None, district_name: str | None) -> list[Any]:
        cache_key = (
            scope.sg_id,
            scope.sg_typecode,
            clean_text(row_record.candidate_name) or "",
            "|".join([clean_text(region_name) or "", clean_text(district_name) or ""]),
        )
        cached = search_cache.get(cache_key)
        if cached is not None:
            return list(cached)
        items = call_with_retry(
            nec_client.search_candidates,
            request_delay_seconds=request_delay_seconds,
            candidate_name=row_record.candidate_name,
            sg_id=scope.sg_id,
            sg_typecode=scope.sg_typecode,
            sd_name=region_name,
            district_name=district_name,
            limit=max(candidate_limit, DEFAULT_CANDIDATE_LIMIT),
        )
        deduped = dedupe_candidates(list(items))
        search_cache[cache_key] = deduped
        return list(deduped)

    for region_name in search_regions:
        variant = (clean_text(region_name), None)
        if variant in seen_variants:
            continue
        seen_variants.add(variant)
        candidates.extend(run_search(region_name, None))

    candidates = dedupe_candidates(candidates)
    if not candidates and district_hint:
        for region_name in search_regions:
            variant = (clean_text(region_name), district_hint)
            if variant in seen_variants:
                continue
            seen_variants.add(variant)
            candidates.extend(run_search(region_name, district_hint))
        candidates = dedupe_candidates(candidates)

    if not candidates:
        return []

    candidates = shared_field_filtered_pool(
        candidates,
        row_record,
        map_party_name=map_party_name,
        normalize_district_name=normalize_district_name,
        similarity=similarity,
        first_of=first_of,
    )
    return candidates[:candidate_limit]


def score_candidates(
    candidates: list[Any],
    row_record: Any,
    *,
    profile_by_key: dict[str, Any] | None,
    rank_krpoltext_candidate_matches: Any,
) -> list[CandidateScore]:
    scored: list[CandidateScore] = []
    for candidate in candidates:
        profile = (profile_by_key or {}).get(candidate_lookup_key(candidate))
        details = rank_krpoltext_candidate_matches(candidate, profile, [row_record])
        if not details:
            continue
        detail = details[0]
        scored.append(
            CandidateScore(
                candidate=candidate,
                profile=profile,
                confidence=detail.metadata.match_confidence or 0.0,
                match_method=detail.metadata.match_method,
                warnings=list(detail.metadata.warnings),
                strong_signal_count=detail.strong_signal_count,
                strong_signals=list(detail.strong_signals),
                base_exact=detail.base_exact,
                identity_verified=detail.identity_verified,
            )
        )
    scored.sort(
        key=lambda item: (item.confidence, item.strong_signal_count, 1 if item.identity_verified else 0),
        reverse=True,
    )
    deduped: list[CandidateScore] = []
    seen_identity_keys: set[str] = set()
    for item in scored:
        identity_key = candidate_score_identity_key(item)
        if identity_key in seen_identity_keys:
            continue
        seen_identity_keys.add(identity_key)
        deduped.append(item)
    return deduped


def resolve_scores(scores: list[CandidateScore]) -> tuple[str, CandidateScore | None, str]:
    if not scores:
        return "not_found", None, "No NEC candidates matched the inferred election scope strongly enough."
    top = scores[0]
    runner_up = scores[1] if len(scores) > 1 else None
    runner_confidence = runner_up.confidence if runner_up else 0.0
    gap = top.confidence - runner_confidence
    gap_is_sufficient = gap + FLOAT_COMPARISON_EPSILON >= MIN_RESOLUTION_GAP
    if top.confidence < 0.55:
        return "not_found", None, "No NEC candidate matched the raw row strongly enough."
    if len(scores) == 1 and top.base_exact:
        return "resolved", top, "Resolved from election, office, district, and name context."
    if top.identity_verified and (
        runner_up is None or top.strong_signal_count > runner_up.strong_signal_count or gap_is_sufficient
    ):
        return "resolved", top, "Resolved using stronger personal identifiers."
    if top.strong_signal_count >= 2 and gap_is_sufficient:
        return "resolved", top, "Resolved using multiple corroborating metadata fields."
    return "ambiguous", None, "Multiple NEC candidates remain plausible for this raw row."


def choose_profile_candidates(scores: list[CandidateScore], profile_limit: int) -> list[Any]:
    if not scores:
        return []
    top_confidence = scores[0].confidence
    selected: list[Any] = []
    for score in scores:
        if len(selected) >= profile_limit:
            break
        if score.confidence >= max(0.35, top_confidence - 0.12):
            selected.append(score.candidate)
    return selected or [score.candidate for score in scores[:profile_limit]]


def fetch_profiles(
    nec_client: Any,
    candidates: list[Any],
    *,
    profile_cache: dict[str, Any],
    request_delay_seconds: float,
) -> dict[str, Any]:
    profiles: dict[str, Any] = {}
    for candidate in candidates:
        cache_key = candidate_lookup_key(candidate)
        if cache_key in profiles:
            continue
        if cache_key in profile_cache:
            profiles[cache_key] = profile_cache[cache_key]
            continue
        try:
            profiles[cache_key] = call_with_retry(
                nec_client.get_candidate_profile,
                candidate.candidate_ref,
                request_delay_seconds=request_delay_seconds,
            )
        except Exception:
            profiles[cache_key] = None
        profile_cache[cache_key] = profiles[cache_key]
    return profiles


def raw_plus_linkage_matches_schema(raw_fieldnames: list[str], schema_fieldnames: list[str]) -> bool:
    expected = [name for name in schema_fieldnames if name not in LINKAGE_COLUMNS]
    return raw_fieldnames == expected


def coerce_for_schema(fieldnames: list[str], type_map: dict[str, str], row: dict[str, Any]) -> dict[str, Any]:
    coerced: dict[str, Any] = {}
    for name in fieldnames:
        value = row.get(name)
        coerced[name] = clean_int(value) if type_map[name] == "integer" else clean_text(value)
    return coerced


def quote_sql_identifier(identifier: str) -> str:
    return '"' + identifier.replace('"', '""') + '"'


def quote_sql_literal(value: str) -> str:
    return "'" + value.replace("'", "''") + "'"


def normalize_duckdb_type(type_name: str) -> str:
    return type_name.strip().upper().split("(")[0]


def build_csv_scan_sql(csv_path: Path) -> str:
    return (
        f"read_csv_auto({quote_sql_literal(str(csv_path))}, "
        "header = TRUE, all_varchar = TRUE, sample_size = -1)"
    )


def create_parquet_from_csv(
    duckdb_module: Any,
    *,
    output_csv: Path,
    output_parquet: Path,
    fieldnames: list[str],
    type_map: dict[str, str],
    duckdb_type_map: dict[str, str],
) -> dict[str, Any]:
    csv_scan_sql = (
        "read_csv("
        f"{quote_sql_literal(str(output_csv))}, "
        "header=true, "
        "all_varchar=true, "
        "strict_mode=false, "
        "null_padding=true, "
        "ignore_errors=false, "
        "sample_size=-1, "
        "parallel=false, "
        "escape='\"'"
        ")"
    )
    connection = duckdb_module.connect(database=":memory:")
    try:
        select_parts = []
        for name in fieldnames:
            quoted_name = quote_sql_identifier(name)
            target_type = duckdb_type_map[name]
            expression = (
                f"TRY_CAST({quoted_name} AS BIGINT) AS {quoted_name}"
                if target_type == "BIGINT"
                else f"CAST({quoted_name} AS VARCHAR) AS {quoted_name}"
            )
            select_parts.append(expression)
        select_sql = ", ".join(select_parts)
        if output_parquet.exists():
            output_parquet.unlink()
        csv_row_count = connection.execute(f"SELECT COUNT(*) FROM {csv_scan_sql}").fetchone()[0]
        connection.execute(
            "COPY ("
            f"SELECT {select_sql} FROM {csv_scan_sql}"
            f") TO {quote_sql_literal(str(output_parquet))} "
            "(FORMAT PARQUET, COMPRESSION SNAPPY)"
        )
        parquet_row_count = connection.execute(
            f"SELECT COUNT(*) FROM read_parquet({quote_sql_literal(str(output_parquet))})"
        ).fetchone()[0]
        parquet_schema_rows = connection.execute(
            f"DESCRIBE SELECT * FROM read_parquet({quote_sql_literal(str(output_parquet))})"
        ).fetchall()
    finally:
        connection.close()
    parquet_columns = [row[0] for row in parquet_schema_rows]
    parquet_types = {row[0]: normalize_duckdb_type(row[1]) for row in parquet_schema_rows}
    expected_types = {name: duckdb_type_map[name] for name in fieldnames}
    return {
        "csv_row_count": csv_row_count,
        "parquet_row_count": parquet_row_count,
        "parquet_columns_match": parquet_columns == fieldnames,
        "parquet_types_match": parquet_types == expected_types,
    }


def build_debug_row(
    *,
    code: str | None,
    candidate_name: str | None,
    scope: Scope,
    status: str,
    message: str,
    scores: list[CandidateScore],
    used_profiles: bool,
    error: str | None = None,
) -> dict[str, Any]:
    top = scores[0] if scores else None
    runner = scores[1] if len(scores) > 1 else None
    return {
        "code": code,
        "candidate_name": candidate_name,
        "sg_id": scope.sg_id,
        "sg_typecode": scope.sg_typecode,
        "raw_region": scope.raw_region,
        "canonical_region": scope.canonical_region,
        "district_label": scope.district_label,
        "link_status": status,
        "message": message,
        "used_profiles": used_profiles,
        "top_huboid": candidate_score_huboid(top) if top else None,
        "top_candidate_name": top.candidate.candidate_ref.candidate_name if top else None,
        "top_party_name": top.candidate.party_name if top else None,
        "top_district_label": top.candidate.candidate_ref.district_label if top else None,
        "top_confidence": top.confidence if top else None,
        "top_match_method": top.match_method if top else None,
        "top_strong_signals": ",".join(top.strong_signals) if top else None,
        "runner_huboid": candidate_score_huboid(runner) if runner else None,
        "runner_confidence": runner.confidence if runner else None,
        "runner_match_method": runner.match_method if runner else None,
        "error": error,
    }


def enrich_row(
    row: dict[str, Any],
    *,
    scope: Scope,
    status: str,
    selected: CandidateScore | None,
    matcher_version: str,
    nec_snapshot_id: str,
) -> dict[str, Any]:
    enriched = dict(row)
    enriched["sg_id"] = scope.sg_id
    enriched["sg_typecode"] = scope.sg_typecode
    enriched["link_status"] = status
    enriched["matcher_version"] = matcher_version
    enriched["nec_snapshot_id"] = nec_snapshot_id
    enriched["huboid"] = candidate_score_huboid(selected) if status == "resolved" and selected else None
    if status != "resolved":
        enriched["huboid"] = None
    return enriched


def build_summary(
    *,
    output_csv: Path,
    output_parquet: Path,
    debug_csv: Path,
    raw_csv: Path,
    matcher_version: str,
    nec_snapshot_id: str,
    counts: Counter[str],
    total_rows: int,
    validation: dict[str, Any],
    include_parquet: bool,
) -> dict[str, Any]:
    artifacts = {
        "raw_csv": {"file": raw_csv.name, "size_bytes": raw_csv.stat().st_size, "sha256": sha256_file(raw_csv)},
        "csv": {"file": output_csv.name, "size_bytes": output_csv.stat().st_size, "sha256": sha256_file(output_csv)},
        "debug_csv": {"file": debug_csv.name, "size_bytes": debug_csv.stat().st_size, "sha256": sha256_file(debug_csv)},
    }
    if include_parquet and output_parquet.exists():
        artifacts["parquet"] = {
            "file": output_parquet.name,
            "size_bytes": output_parquet.stat().st_size,
            "sha256": sha256_file(output_parquet),
        }
    return {
        "generated_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "matcher_version": matcher_version,
        "nec_snapshot_id": nec_snapshot_id,
        "raw_csv": str(raw_csv),
        "output_csv": str(output_csv),
        "output_parquet": str(output_parquet),
        "debug_csv": str(debug_csv),
        "row_count": total_rows,
        "counts": dict(counts),
        "validation": validation,
        "artifacts": artifacts,
    }


def load_resume_state(
    output_csv: Path,
    fieldnames: list[str],
    *,
    matcher_version: str,
    nec_snapshot_id: str,
) -> tuple[int, Counter[str]]:
    processed_rows = 0
    counts: Counter[str] = Counter()
    if not output_csv.exists() or output_csv.stat().st_size == 0:
        return processed_rows, counts
    with output_csv.open("r", encoding="utf-8", newline="") as handle:
        reader = csv.DictReader(handle)
        if reader.fieldnames != fieldnames:
            raise SystemExit("Existing enriched CSV header does not match the documented schema.")
        for row in reader:
            processed_rows += 1
            status = row.get("link_status") or "not_found"
            counts[status] += 1
            if clean_text(row.get("matcher_version")) != matcher_version:
                raise SystemExit("Existing enriched CSV matcher_version does not match this resume request.")
            if clean_text(row.get("nec_snapshot_id")) != nec_snapshot_id:
                raise SystemExit("Existing enriched CSV nec_snapshot_id does not match this resume request.")
    return processed_rows, counts


def main() -> None:
    args = parse_args()
    requests_module = ensure_dependency("requests")
    duckdb_module = ensure_dependency("duckdb")

    krpoltext_repo = Path(args.krpoltext_repo).resolve() if args.krpoltext_repo else Path(__file__).resolve().parents[1]
    mcp_repo = Path(args.mcp_repo).resolve()
    add_mcp_repo_to_path(mcp_repo)

    from app.campaign_booklet_corpus import build_region_district_label
    from app.config import Settings
    from app.krpoltext_matching import rank_krpoltext_candidate_matches
    from app.models import KrPolTextMetaRecord
    from app.nec_api import NecApiClient
    from app.normalize import first_of, map_party_name, normalize_candidate_name, normalize_district_name, similarity

    output_dir = resolve_output_path(krpoltext_repo, args.output_dir)
    source_dir = resolve_output_path(krpoltext_repo, args.source_dir)
    output_dir.mkdir(parents=True, exist_ok=True)
    source_dir.mkdir(parents=True, exist_ok=True)

    output_csv = resolve_output_path(output_dir, args.output_csv)
    output_parquet = resolve_output_path(output_dir, args.output_parquet)
    debug_csv = resolve_output_path(output_dir, args.debug_csv)
    summary_json = resolve_output_path(output_dir, args.summary_json)
    raw_csv = Path(args.raw_csv).resolve() if args.raw_csv else source_dir / "sk_election_campaign_booklet_v2022.raw.csv"

    if args.overwrite:
        for artifact_path in (output_csv, output_parquet, debug_csv, summary_json):
            if artifact_path.exists():
                artifact_path.unlink()

    fieldnames, type_map, duckdb_type_map = load_schema(krpoltext_repo)
    if not raw_csv.exists():
        print(f"Downloading raw campaign_booklet source to {raw_csv}", flush=True)
        download_file(requests_module, args.raw_url, raw_csv)
    else:
        print(f"Reusing existing raw campaign_booklet source at {raw_csv}", flush=True)

    settings_kwargs: dict[str, Any] = {
        "cache_ttl_seconds": 60 * 60 * 24 * 365,
        "retry_attempts": 6,
        "retry_backoff_seconds": 2.0,
    }
    settings_kwargs["cache_dir"] = Path(args.cache_dir).resolve() if args.cache_dir else output_dir / "_cache" / "http"
    settings = Settings.from_env(env_file=args.env_file).model_copy(update=settings_kwargs)
    settings.require_api_keys()
    nec_client = NecApiClient(settings)

    prefetch_summary = prefetch_candidate_name_rows(
        raw_csv=raw_csv,
        workers=max(args.prefetch_workers, 0),
        settings=settings,
        NecApiClient=NecApiClient,
    )

    print("Using row-driven NEC candidate search over raw campaign_booklet rows.", flush=True)
    profile_cache: dict[str | None, Any] = {}
    search_cache: dict[tuple[str, str, str, str], list[Any]] = {}

    resumed_rows, counts = load_resume_state(
        output_csv,
        fieldnames,
        matcher_version=args.matcher_version,
        nec_snapshot_id=args.nec_snapshot_id,
    )
    total_rows = resumed_rows
    csv_mode = "a" if resumed_rows > 0 else "w"
    if resumed_rows > 0:
        if not debug_csv.exists() or debug_csv.stat().st_size == 0:
            raise SystemExit("Cannot resume because the linkage debug CSV is missing or empty.")
        resume_debug_audit = audit_debug_csv(debug_csv, expected_fieldnames=DEBUG_FIELDNAMES)
        if not resume_debug_audit["header_match"]:
            raise SystemExit("Cannot resume because the linkage debug CSV header is incompatible.")
        if resume_debug_audit["row_count"] != resumed_rows:
            raise SystemExit("Cannot resume because enriched and debug CSV row counts differ.")
        if resume_debug_audit["processing_error_rows"]:
            raise SystemExit("Cannot resume an artifact whose debug CSV already contains processing errors.")
        print(f"Resuming from row {resumed_rows:,} using existing enriched CSV at {output_csv}", flush=True)
    debug_mode = "a" if resumed_rows > 0 else "w"

    with raw_csv.open("r", encoding="utf-8-sig", newline="") as source_handle, \
        output_csv.open(csv_mode, encoding="utf-8", newline="") as csv_handle, \
        debug_csv.open(debug_mode, encoding="utf-8", newline="") as debug_handle:
        reader = csv.DictReader(source_handle)
        if reader.fieldnames is None:
            raise SystemExit("Raw campaign_booklet CSV did not contain a header row.")
        if not raw_plus_linkage_matches_schema(reader.fieldnames, fieldnames):
            raise SystemExit("Raw campaign_booklet columns do not match the expected pre-linkage schema.")
        writer = csv.DictWriter(csv_handle, fieldnames=fieldnames)
        if csv_mode == "w":
            writer.writeheader()
        debug_writer = csv.DictWriter(debug_handle, fieldnames=DEBUG_FIELDNAMES)
        if debug_mode == "w":
            debug_writer.writeheader()

        skipped = 0
        while skipped < resumed_rows:
            if next(reader, None) is None:
                break
            skipped += 1

        for row in reader:
            total_rows += 1
            used_profiles = False
            try:
                row_record = make_row_record(row, build_region_district_label, KrPolTextMetaRecord)
                scope = build_scope(row, build_region_district_label)
                candidates = fetch_candidate_pool(
                    nec_client,
                    search_cache,
                    row_record,
                    scope,
                    candidate_limit=args.candidate_limit,
                    map_party_name=map_party_name,
                    normalize_district_name=normalize_district_name,
                    similarity=similarity,
                    first_of=first_of,
                    request_delay_seconds=args.request_delay_seconds,
                )
                initial_scores = score_candidates(
                    candidates,
                    row_record,
                    profile_by_key=None,
                    rank_krpoltext_candidate_matches=rank_krpoltext_candidate_matches,
                )
                status, selected, message = resolve_scores(initial_scores)
                final_scores = initial_scores
                if candidates and status != "resolved":
                    profile_candidates = choose_profile_candidates(initial_scores, args.profile_limit)
                    if profile_candidates:
                        profile_by_key = fetch_profiles(
                            nec_client,
                            profile_candidates,
                            profile_cache=profile_cache,
                            request_delay_seconds=args.request_delay_seconds,
                        )
                        final_scores = score_candidates(
                            candidates,
                            row_record,
                            profile_by_key=profile_by_key,
                            rank_krpoltext_candidate_matches=rank_krpoltext_candidate_matches,
                        )
                        used_profiles = True
                        status, selected, message = resolve_scores(final_scores)
                status, selected, message = apply_manual_review_override(
                    row,
                    scores=final_scores,
                    status=status,
                    selected=selected,
                    message=message,
                )
                if status == "resolved" and not candidate_score_huboid(selected):
                    status, selected = "not_found", None
                    message = "Top NEC candidate lacked a stable huboid, so the row stayed unresolved."
                enriched = enrich_row(
                    row,
                    scope=scope,
                    status=status,
                    selected=selected,
                    matcher_version=args.matcher_version,
                    nec_snapshot_id=args.nec_snapshot_id,
                )
                debug_row = build_debug_row(
                    code=clean_text(row.get("code")),
                    candidate_name=row_record.candidate_name,
                    scope=scope,
                    status=status,
                    message=message,
                    scores=final_scores,
                    used_profiles=used_profiles,
                )
            except Exception as exc:
                scope = build_scope(row, build_region_district_label)
                status = "not_found"
                counts["errors"] += 1
                enriched = enrich_row(
                    row,
                    scope=scope,
                    status=status,
                    selected=None,
                    matcher_version=args.matcher_version,
                    nec_snapshot_id=args.nec_snapshot_id,
                )
                debug_row = build_debug_row(
                    code=clean_text(row.get("code")),
                    candidate_name=clean_text(row.get("name")),
                    scope=scope,
                    status=status,
                    message="Row processing failed; leaving the row unresolved.",
                    scores=[],
                    used_profiles=used_profiles,
                    error=str(exc),
                )
            coerced = coerce_for_schema(fieldnames, type_map, enriched)
            writer.writerow(coerced)
            debug_writer.writerow(debug_row)
            counts[coerced["link_status"] or "not_found"] += 1
            if total_rows % 500 == 0:
                print(
                    f"Processed {total_rows:,} rows "
                    f"(resolved={counts['resolved']:,}, ambiguous={counts['ambiguous']:,}, not_found={counts['not_found']:,})",
                    flush=True,
                )

    with output_csv.open("r", encoding="utf-8", newline="") as csv_handle:
        csv_header = next(csv.reader(csv_handle), [])

    linkage_audit = audit_enriched_csv(
        output_csv,
        normalize_candidate_name=normalize_candidate_name,
        normalize_district_name=normalize_district_name,
        map_party_name=map_party_name,
    )
    debug_audit = audit_debug_csv(debug_csv, expected_fieldnames=DEBUG_FIELDNAMES)
    raw_row_count = count_csv_rows(raw_csv, encoding="utf-8-sig")
    csv_row_count = linkage_audit["row_count"]
    common_validation = {
        "raw_columns_match_expected": True,
        "csv_header_match": csv_header == fieldnames,
        "row_count_preserved": raw_row_count == csv_row_count == total_rows,
        "debug_row_count_match": debug_audit["row_count"] == csv_row_count,
        "debug_header_match": debug_audit["header_match"],
        "no_processing_errors": debug_audit["processing_error_rows"] == 0,
        "valid_link_statuses": linkage_audit["invalid_status_rows"] == 0,
        "resolved_requires_huboid": linkage_audit["resolved_missing_huboid"] == 0,
        "unresolved_clears_huboid": linkage_audit["unresolved_with_huboid"] == 0,
        "resolved_requires_scope": linkage_audit["resolved_missing_scope"] == 0,
        "scope_format_valid": linkage_audit["invalid_scope_rows"] == 0,
        "huboid_format_valid": linkage_audit["invalid_huboid_rows"] == 0,
        "linkage_provenance_complete": (
            linkage_audit["missing_matcher_version_rows"] == 0
            and linkage_audit["missing_nec_snapshot_id_rows"] == 0
        ),
        "matcher_version_consistent": linkage_audit["matcher_versions"] == [args.matcher_version],
        "nec_snapshot_id_consistent": linkage_audit["nec_snapshot_ids"] == [args.nec_snapshot_id],
        "no_unreviewed_identity_conflicts": linkage_audit["unreviewed_identity_conflict_target_groups"] == 0,
        "raw_row_count": raw_row_count,
        "csv_row_count": csv_row_count,
        "debug_row_count": debug_audit["row_count"],
        "processing_error_rows": debug_audit["processing_error_rows"],
        "candidate_name_prefetch": prefetch_summary,
        "linkage_audit": linkage_audit,
    }

    if args.skip_parquet:
        validation = {
            **common_validation,
            "csv_parquet_schema_match": None,
            "parquet_row_count": None,
            "parquet_skipped": True,
        }
    else:
        parquet_validation = create_parquet_from_csv(
            duckdb_module,
            output_csv=output_csv,
            output_parquet=output_parquet,
            fieldnames=fieldnames,
            type_map=type_map,
            duckdb_type_map=duckdb_type_map,
        )
        validation = {
            **common_validation,
            "row_count_preserved": (
                common_validation["row_count_preserved"]
                and parquet_validation["csv_row_count"] == csv_row_count == parquet_validation["parquet_row_count"]
            ),
            "csv_parquet_schema_match": parquet_validation["parquet_columns_match"] and parquet_validation["parquet_types_match"],
            "parquet_row_count": parquet_validation["parquet_row_count"],
            "parquet_skipped": False,
        }
    if not validation["csv_header_match"]:
        raise SystemExit("Enriched CSV header did not match the documented schema.")
    if not validation["row_count_preserved"]:
        raise SystemExit("CSV row count did not match the raw input row count.")
    if not args.skip_parquet and not validation["csv_parquet_schema_match"]:
        raise SystemExit("Parquet schema did not match the documented enriched schema.")
    if not validation["resolved_requires_huboid"]:
        raise SystemExit("Resolved rows without huboid were detected in the enriched artifact.")
    if not validation["debug_row_count_match"]:
        raise SystemExit("Debug CSV row count did not match the enriched CSV row count.")
    if not validation["debug_header_match"]:
        raise SystemExit("Debug CSV header did not match the expected diagnostic schema.")
    if not validation["no_processing_errors"]:
        raise SystemExit("Row processing errors were detected in the linkage debug CSV.")
    if not validation["valid_link_statuses"]:
        raise SystemExit("Invalid or missing link_status values were detected in the enriched artifact.")
    if not validation["unresolved_clears_huboid"]:
        raise SystemExit("Unresolved rows with non-null huboid values were detected in the enriched artifact.")
    if not validation["resolved_requires_scope"]:
        raise SystemExit("Resolved rows without sg_id or sg_typecode were detected in the enriched artifact.")
    if not validation["scope_format_valid"]:
        raise SystemExit("Malformed sg_id or sg_typecode values were detected in resolved rows.")
    if not validation["huboid_format_valid"]:
        raise SystemExit("Non-numeric huboid values were detected in the enriched artifact.")
    if not validation["linkage_provenance_complete"]:
        raise SystemExit("Rows without matcher_version or nec_snapshot_id provenance were detected.")
    if not validation["matcher_version_consistent"]:
        raise SystemExit("Multiple or unexpected matcher_version values were detected in the enriched artifact.")
    if not validation["nec_snapshot_id_consistent"]:
        raise SystemExit("Multiple or unexpected nec_snapshot_id values were detected in the enriched artifact.")
    if not validation["no_unreviewed_identity_conflicts"]:
        raise SystemExit("Unreviewed name, birthday, or giho conflicts share the same resolved NEC target.")

    summary = build_summary(
        output_csv=output_csv,
        output_parquet=output_parquet,
        debug_csv=debug_csv,
        raw_csv=raw_csv,
        matcher_version=args.matcher_version,
        nec_snapshot_id=args.nec_snapshot_id,
        counts=counts,
        total_rows=total_rows,
        validation=validation,
        include_parquet=not args.skip_parquet,
    )
    summary_json.write_text(json.dumps(summary, ensure_ascii=False, indent=2), encoding="utf-8")
    print(json.dumps(summary, ensure_ascii=False, indent=2), flush=True)


if __name__ == "__main__":
    main()






