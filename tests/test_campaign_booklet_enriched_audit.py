from __future__ import annotations

import csv
import tempfile
import unittest
from collections import Counter
from pathlib import Path

from tools.build_campaign_booklet_enriched_duckdb import (
    CandidateScore,
    audit_debug_csv,
    audit_enriched_csv,
    build_summary,
    collect_candidate_names,
    count_csv_rows,
    load_resume_state,
    resolve_scores,
)
from tools.upgrade_campaign_booklet_enriched_v3 import resolution_policies_equivalent


FIELDNAMES = [
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
]


def normalize_text(value: str | None) -> str:
    return "".join(str(value or "").split()).casefold()


def map_party_name(value: str | None) -> str:
    normalized = normalize_text(value)
    return {
        "국민의힘": "국민의힘",
        "미래현합": "미래연합",
    }.get(normalized, normalized)


class CampaignBookletEnrichedAuditTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temp_dir = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp_dir.cleanup)
        self.root = Path(self.temp_dir.name)

    def write_csv(self, name: str, rows: list[dict[str, object]], fieldnames: list[str] = FIELDNAMES) -> Path:
        path = self.root / name
        with path.open("w", encoding="utf-8", newline="") as handle:
            writer = csv.DictWriter(handle, fieldnames=fieldnames)
            writer.writeheader()
            writer.writerows(rows)
        return path

    def audit(self, rows: list[dict[str, object]]) -> dict[str, object]:
        return audit_enriched_csv(
            self.write_csv("enriched.csv", rows),
            normalize_candidate_name=normalize_text,
            normalize_district_name=normalize_text,
            map_party_name=map_party_name,
        )

    def test_reports_benign_row_preserving_duplicate_without_identity_conflict(self) -> None:
        rows = [
            {
                "date": "2000-04-13",
                "name": "양정규",
                "region": "제주도",
                "district": "북제주군",
                "office": "national_assembly",
                "party": "한나라당",
                "code": "row-1",
                "huboid": "10041168",
                "sg_id": "20000413",
                "sg_typecode": "2",
                "link_status": "resolved",
            },
            {
                "date": "2000-04-13",
                "name": "양정규",
                "region": "제주특별자치도",
                "office": "national_assembly",
                "party": "한나라당",
                "code": "row-2",
                "huboid": "10041168",
                "sg_id": "20000413",
                "sg_typecode": "2",
                "link_status": "resolved",
            },
            {"name": "unmatched", "link_status": "not_found"},
        ]

        audit = self.audit(rows)

        self.assertEqual(audit["row_count"], 3)
        self.assertEqual(audit["duplicate_target_groups"], 1)
        self.assertEqual(audit["duplicate_target_extra_rows"], 1)
        self.assertEqual(audit["identity_conflict_target_groups"], 0)
        self.assertEqual(audit["region_conflict_target_groups"], 0)
        self.assertEqual(audit["resolved_missing_huboid"], 0)

    def test_flags_invalid_linkage_invariants(self) -> None:
        rows = [
            {"name": "missing-id", "sg_id": "20200101", "sg_typecode": "2", "link_status": "resolved"},
            {"name": "unresolved-id", "huboid": "123", "link_status": "ambiguous"},
            {"name": "missing-scope", "huboid": "124", "link_status": "resolved"},
            {
                "name": "bad-id",
                "huboid": "ABC",
                "sg_id": "20200101",
                "sg_typecode": "2",
                "link_status": "resolved",
            },
            {
                "name": "bad-scope",
                "huboid": "125",
                "sg_id": "2020-01-01",
                "sg_typecode": "metro",
                "link_status": "resolved",
            },
            {"name": "bad-status", "link_status": "maybe"},
        ]

        audit = self.audit(rows)

        self.assertEqual(audit["resolved_missing_huboid"], 1)
        self.assertEqual(audit["unresolved_with_huboid"], 1)
        self.assertEqual(audit["resolved_missing_scope"], 1)
        self.assertEqual(audit["invalid_scope_rows"], 1)
        self.assertEqual(audit["invalid_huboid_rows"], 1)
        self.assertEqual(audit["invalid_status_rows"], 1)

    def test_flags_unreviewed_identity_conflict_and_conflicting_code(self) -> None:
        rows = [
            {
                "name": "Alice",
                "code": "shared",
                "huboid": "101",
                "sg_id": "20200101",
                "sg_typecode": "2",
                "link_status": "resolved",
            },
            {
                "name": "Bob",
                "code": "other",
                "huboid": "101",
                "sg_id": "20200101",
                "sg_typecode": "2",
                "link_status": "resolved",
            },
            {
                "name": "Carol",
                "code": "shared",
                "huboid": "102",
                "sg_id": "20200101",
                "sg_typecode": "2",
                "link_status": "resolved",
            },
            {
                "name": "Dave",
                "code": "shared",
                "huboid": "103",
                "sg_id": "20200101",
                "sg_typecode": "2",
                "link_status": "resolved",
            },
        ]

        audit = self.audit(rows)

        self.assertEqual(audit["identity_conflict_target_groups"], 1)
        self.assertEqual(audit["unreviewed_identity_conflict_target_groups"], 1)
        self.assertEqual(audit["duplicate_code_groups"], 1)
        self.assertEqual(audit["conflicting_code_target_groups"], 1)
        self.assertEqual(audit["duplicate_code_rows"], 3)
        self.assertEqual(len(audit["conflicting_code_examples"][0]["rows"]), 3)

    def test_manual_reviewed_ocr_name_conflict_is_reported_but_allowed(self) -> None:
        rows = [
            {
                "date": "2018-06-13",
                "name": "권해정",
                "huboid": "100125215",
                "sg_id": "20180613",
                "sg_typecode": "5",
                "link_status": "resolved",
            },
            {
                "date": "2018-06-13",
                "name": "권혜정",
                "huboid": "100125215",
                "sg_id": "20180613",
                "sg_typecode": "5",
                "link_status": "resolved",
            },
        ]

        audit = self.audit(rows)

        self.assertEqual(audit["identity_conflict_target_groups"], 1)
        self.assertEqual(audit["unreviewed_identity_conflict_target_groups"], 0)

        rows.append(
            {
                "date": "2018-06-13",
                "name": "전혀다른후보",
                "huboid": "100125215",
                "sg_id": "20180613",
                "sg_typecode": "5",
                "link_status": "resolved",
            }
        )
        audit = self.audit(rows)
        self.assertEqual(audit["unreviewed_identity_conflict_target_groups"], 1)

    def test_counts_csv_and_debug_processing_errors(self) -> None:
        debug_path = self.write_csv(
            "debug.csv",
            [{"error": ""}, {"error": "request failed"}],
            fieldnames=["error"],
        )

        self.assertEqual(count_csv_rows(debug_path), 2)
        self.assertEqual(
            audit_debug_csv(debug_path, expected_fieldnames=["error"]),
            {"row_count": 2, "processing_error_rows": 1, "header_match": True},
        )

    def test_collect_candidate_names_is_unique_sorted_and_ignores_blanks(self) -> None:
        path = self.write_csv(
            "raw.csv",
            [{"name": "홍길동"}, {"name": ""}, {"name": "김영희"}, {"name": "홍길동"}],
            fieldnames=["name"],
        )

        self.assertEqual(collect_candidate_names(path), ["김영희", "홍길동"])

    def test_prefetch_stops_queued_requests_after_rate_limit(self) -> None:
        from tools.build_campaign_booklet_enriched_duckdb import prefetch_candidate_name_rows

        path = self.write_csv(
            "raw.csv",
            [{"name": "A"}, {"name": "B"}, {"name": "C"}],
            fieldnames=["name"],
        )

        class RateLimitedClient:
            calls: list[str] = []

            def __init__(self, settings: object) -> None:
                self.settings = settings

            def _request_paginated_rows(self, service: str, params: dict[str, str], max_pages: int):
                self.calls.append(params["name"])
                raise RuntimeError("429 Too Many Requests")

        summary = prefetch_candidate_name_rows(
            raw_csv=path,
            workers=1,
            settings=object(),
            NecApiClient=RateLimitedClient,
        )

        self.assertEqual(RateLimitedClient.calls, ["A"])
        self.assertEqual(summary["attempted"], 1)
        self.assertEqual(summary["errors"], 1)
        self.assertEqual(summary["skipped"], 2)
        self.assertEqual(summary["rate_limited"], 1)

    def test_resolution_gap_is_not_rounded_up_to_threshold(self) -> None:
        def score(confidence: float, strong_signal_count: int) -> CandidateScore:
            return CandidateScore(
                candidate=object(),
                profile=None,
                confidence=confidence,
                match_method=None,
                warnings=[],
                strong_signal_count=strong_signal_count,
                strong_signals=[],
                base_exact=False,
                identity_verified=False,
            )

        status, _, _ = resolve_scores([score(0.6296, 2), score(0.55, 0)])
        self.assertEqual(status, "ambiguous")

        status, selected, _ = resolve_scores([score(0.63, 2), score(0.55, 0)])
        self.assertEqual(status, "resolved")
        self.assertIsNotNone(selected)

    def test_v2_v3_resolution_policies_are_equivalent_on_matcher_domain(self) -> None:
        self.assertTrue(resolution_policies_equivalent())

    def test_summary_hashes_raw_input_and_omits_skipped_stale_parquet(self) -> None:
        raw = self.root / "raw.csv"
        output = self.root / "output.csv"
        debug = self.root / "debug.csv"
        parquet = self.root / "stale.parquet"
        for path, content in ((raw, "raw"), (output, "output"), (debug, "debug"), (parquet, "stale")):
            path.write_text(content, encoding="utf-8")

        summary = build_summary(
            output_csv=output,
            output_parquet=parquet,
            debug_csv=debug,
            raw_csv=raw,
            matcher_version="test-v1",
            nec_snapshot_id="test-snapshot",
            counts=Counter(),
            total_rows=0,
            validation={},
            include_parquet=False,
        )

        self.assertIn("raw_csv", summary["artifacts"])
        self.assertEqual(len(summary["artifacts"]["raw_csv"]["sha256"]), 64)
        self.assertNotIn("parquet", summary["artifacts"])

    def test_resume_rejects_mixed_linkage_provenance(self) -> None:
        fields = ["link_status", "matcher_version", "nec_snapshot_id"]
        path = self.write_csv(
            "resume.csv",
            [{"link_status": "resolved", "matcher_version": "v2", "nec_snapshot_id": "snapshot-a"}],
            fieldnames=fields,
        )

        processed_rows, counts = load_resume_state(
            path,
            fields,
            matcher_version="v2",
            nec_snapshot_id="snapshot-a",
        )
        self.assertEqual(processed_rows, 1)
        self.assertEqual(counts["resolved"], 1)

        with self.assertRaisesRegex(SystemExit, "matcher_version"):
            load_resume_state(
                path,
                fields,
                matcher_version="v3",
                nec_snapshot_id="snapshot-a",
            )


if __name__ == "__main__":
    unittest.main()
