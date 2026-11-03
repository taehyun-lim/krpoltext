# Data Dictionary

Variable descriptions for the two corpora provided by the **krpoltext**
package. For the full methodology and technical validation, see the Data
Descriptor:

> Lim, T.H. (2025). South Korean Election Campaign Booklet and Party
> Statements Corpora. *Scientific Data*, 12, 1030.
> <https://doi.org/10.1038/s41597-025-05220-4>

Data repository: <https://doi.org/10.17605/OSF.IO/RCT9Y>

---

## 1. Election Campaign Booklets (`campaign_booklet` public artifact)

Official election campaign booklets (공보물) from **49,678 individual
candidates** across presidential, National Assembly, and local elections in
South Korea (2000–2022). Text was extracted via OCR (black-and-white,
page-by-page using the Google Drive API) and parsed using the khaiii Korean
morphological analyzer.

The package and API expose this corpus in enriched form, with
linkage-derived NEC alignment fields such as `huboid`, `sg_id`,
`sg_typecode`, `link_status`, `matcher_version`, and `nec_snapshot_id`.

| Column | Type | Description |
|--------|------|-------------|
| `date` | character | Election date (YYYY-MM-DD) |
| `name` | character | Candidate name (Korean) |
| `region` | character | Metropolitan region (province or metropolitan city) |
| `district` | character | Electoral district |
| `office_id` | integer | Office type identifier (see mapping below) |
| `office` | character | Office type label (see mapping below) |
| `giho` | integer | Candidate ballot number |
| `party` | character | Political party name (Korean) |
| `party_eng` | character | Political party name (English); transliteration if no official English name |
| `result` | character | Election result (Korean): 당선 (elected) / 낙선 (defeated) |
| `sex` | character | Sex: 남 (male) / 여 (female) |
| `birthday` | character | Date of birth (YYYY-MM-DD) |
| `age` | integer | Age at the time of the election |
| `job_id` | integer | Original NEC job category identifier (varies across years) |
| `job` | character | Standardized job category (Korean) |
| `job_name` | character | Job title (Korean) |
| `job_name_eng` | character | Job title (English) |
| `job_code` | integer | Standardized job code (consistent across years; see paper Table 6) |
| `edu_id` | integer | Original NEC education level identifier (varies across years) |
| `edu` | character | Education description (Korean, free-text from NEC) |
| `edu_name` | character | Standardized education level label (Korean) |
| `edu_name_eng` | character | Standardized education level label (English) |
| `edu_code` | integer | Standardized education code (consistent across years; see paper Table 7) |
| `career1` | character | Career description 1 |
| `career2` | character | Career description 2 |
| `pages` | integer | Number of pages in the booklet |
| `code` | character | **Unique document row identifier** |
| `huboid` | character | Linked NEC candidate identifier for `kr-elections-mcp` alignment; may be missing for unresolved rows |
| `sg_id` | character | Linked NEC election identifier associated with `huboid` |
| `sg_typecode` | character | Linked NEC election type identifier associated with `huboid` |
| `link_status` | character | NEC linkage status: `resolved`, `ambiguous`, `not_found`, or `rejected` |
| `matcher_version` | character | Version of the linkage pipeline used to assign NEC fields |
| `nec_snapshot_id` | character | Identifier of the NEC snapshot used for linkage |
| `sex_code` | integer | Sex code: 1 = male, 0 = female |
| `result_code` | integer | Result code: 1 = elected, 0 = not elected |
| `text` | character | Full OCR-extracted text of the campaign booklet |
| `filtered` | character | Parsed text after morphological analysis; Korean-only, numbers/foreign characters/symbols removed |

### Office Mapping (`office_id` → `office`)

| office_id | office | Description |
|-----------|--------|-------------|
| 1 | president | Presidential election |
| 2 | national_assembly | National Assembly election |
| 3 | edu_superintendent | Education superintendent |
| 4 | metro_head | Metropolitan city mayor / provincial governor |
| 5 | metro_assembly | Metropolitan assembly member |
| 6 | basic_head | Basic local government head (district head / mayor) |
| 7 | basic_assembly | Basic assembly member |

### Notes

- **Missing values**: 2,283 candidates lack a booklet; 151 are missing
  biographical information. 23 booklets were unprocessable (corrupted files).
  See paper Section "Methods" for details.
- **Identifiers**: `code` uniquely identifies each document row. `huboid` is
  a linkage-derived NEC candidacy identifier and may be missing when linkage
  is unresolved. `sg_id` and `sg_typecode` identify the linked NEC election
  scope. `job_id` and `edu_id` vary across election years; use `job_code` and
  `edu_code` for consistent cross-year analysis.
- **Caution on Basic Assembly**: Basic Assembly booklets have lower average
  word counts, potentially due to lower PDF quality or genuinely shorter texts.
  See paper for discussion.
- **`filtered`**: Morphologically parsed using khaiii; retains only Korean
  content words.
- **Provenance**: The package and static API describe the enriched public
  artifact. A native pre-linkage source snapshot may be retained separately
  for provenance and reproducibility.

---

## 2. Party Statements (`sk_party_statements_v2026.csv`)

Official statements from party spokespersons and minutes from daily
leadership meetings of South Korea's **two major political parties**
(2003-09-28 to 2026-08-27): the center-left Progressive Party
(현 더불어민주당) and the center-right Conservative Party (현 국민의힘).
Total: **121,271 statements** (51,141 conservative + 70,130 progressive).

`v2026` is the package default. It keeps all 83,201 rows of the published
`v2022` release unchanged (35,115 conservative + 48,086 progressive; see
paper Table 9 for yearly breakdown) and adds 38,070 statements collected
from the parties' official boards. Load the original release with
`load_party_statements(data_version = "v2022")`.

### Core columns (all versions)

| Column | Type | Description |
|--------|------|-------------|
| `no` | integer | Sequential entry number within each party |
| `year` | integer | Year the statement was posted |
| `ymd` | character | Full date (YYYY-MM-DD) |
| `title` | character | Title of the statement |
| `text` | character | Full text of the statement |
| `filtered` | character | Parsed text after morphological analysis; Korean-only |
| `partisan` | character | Party affiliation: Progressive / Conservative |
| `conservative` | integer | Binary indicator: 1 = Conservative Party, 0 = Progressive Party |
| `id` | character | **Unique document identifier**. `v2022` rows keep their published id (party prefix + entry number); new `v2026` rows use their `board_record_id` |

In `v2026`, `no` is `NA` and `filtered` is empty for the 38,070 rows that
are not part of `v2022`.

### Additional `v2026` columns

| Column | Type | Description |
|--------|------|-------------|
| `board_record_id` | character | Stable official-board key `<namespace>_<source_id>`; empty when board provenance is unavailable |
| `legacy_id`, `legacy_no` | character, integer | Published `v2022` `id` / `no` for rows that belong to `v2022` |
| `id_scheme` | character | Scheme of `id`: `krpoltext_v2022` or `board_source_v1` |
| `legacy_match_status` | character | `dual_id_matched`, `public_only_unmapped`, or `board_source_only_no_safe_legacy_match` |
| `crosswalk_method` | character | Audited rule that matched a `v2022` row to an official board post |
| `media`, `party`, `category`, `source_id`, `url` | character | Official-site source, party name, category, post number, and URL |
| `board_id`, `source_board`, `doc_type` | character | Official board identifier, board name, and document type |
| `source_content_hash`, `content_hash` | character | Collector hash, and SHA-256 of normalized `ymd`, `title`, and `text` |
| `collected_at` | character | Collection timestamp |
| `attachment_urls`, `attachment_names`, `attachment_hashes`, `image_urls` | character | Attachment and embedded-image provenance |
| `embedded_image_count` | integer | Number of embedded images |
| `text_source` | character | Where `text` came from: `html`, `attachment`, or `image_only_html` |
| `attachment_extraction_status`, `attachment_extraction_error` | character | Attachment text extraction outcome |
| `detail_status`, `collection_error` | character | Detail-page collection outcome |
| `site_ymd`, `date_is_placeholder`, `date_resolution_status` | character | Site-displayed date and placeholder-date handling |
| `asset_status`, `asset_error` | character | Attachment and image download outcome |
| `filtered_status` | character | `legacy_khaiii_available`, `legacy_khaiii_missing`, or `not_processed` |
| `filtered_analyzer` | character | Analyzer that produced `filtered` (`khaiii_legacy`) |

### Notes

- **Missing values**: Some fields may contain `NA` or empty strings. In
  `v2026`, collection and provenance columns are empty for `v2022`-only rows.
- **Party name changes**: Both parties have undergone frequent name changes
  (see paper Table 3). The `partisan` column uses stable ideological labels
  rather than party names.
- **`filtered`**: Morphologically parsed using khaiii; retains only Korean
  content words. Available only for `v2022` rows; check `filtered_status`
  before using it with `v2026`.
- **Identifiers**: `id` is unique across all `v2026` rows. 2,444 `v2022`
  rows were safely matched to an official post and carry both `id` and
  `board_record_id`.

---

## General Notes

- All text is UTF-8 encoded Korean.
- `text` contains the full original text; `filtered` contains the parsed
  version suitable for direct text analysis.
- For complete data provenance, OCR methodology, technical validation, and
  use case examples, see the Data Descriptor:
  <https://doi.org/10.1038/s41597-025-05220-4>
- Supplementary Information (party name mappings, example analyses):
  available in the paper's supplementary materials.
