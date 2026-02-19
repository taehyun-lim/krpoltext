# Data Dictionary

Variable descriptions for the two corpora provided by the **krpoltext**
package. For the full methodology and technical validation, see the Data
Descriptor:

> Lim, T.H. (2025). South Korean Election Campaign Booklet and Party
> Statements Corpora. *Scientific Data*, 12, 1030.
> <https://doi.org/10.1038/s41597-025-05220-4>

Data repository: <https://doi.org/10.17605/OSF.IO/RCT9Y>

---

## 1. Election Campaign Booklets (`sk_election_campaign_booklet_v2022.csv`)

Official election campaign booklets (공보물) from **49,678 individual
candidates** across presidential, National Assembly, and local elections in
South Korea (2000–2022). Text was extracted via OCR (black-and-white,
page-by-page using the Google Drive API) and parsed using the khaiii Korean
morphological analyzer.

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
| `code` | character | **Unique document identifier** |
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
- **Identifiers**: `code` uniquely identifies each document. `job_id` and
  `edu_id` vary across election years; use `job_code` and `edu_code` for
  consistent cross-year analysis.
- **Caution on Basic Assembly**: Basic Assembly booklets have lower average
  word counts, potentially due to lower PDF quality or genuinely shorter texts.
  See paper for discussion.
- **`filtered`**: Morphologically parsed using khaiii; retains only Korean
  content words.

---

## 2. Party Statements (`sk_party_statements_v2022.csv`)

Official statements from party spokespersons and minutes from daily
leadership meetings of South Korea's **two major political parties**
(2003–2022): the center-left Progressive Party (현 더불어민주당) and the
center-right Conservative Party (현 국민의힘). Total: **82,723 statements**
(35,115 conservative + 42,335 progressive; see paper Table 9 for yearly
breakdown).

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
| `id` | character | **Unique document identifier** (party prefix + entry number) |

### Notes

- **Missing values**: Some fields may contain `NA` or empty strings.
- **Party name changes**: Both parties have undergone frequent name changes
  (see paper Table 3). The `partisan` column uses stable ideological labels
  rather than party names.
- **`filtered`**: Morphologically parsed using khaiii; retains only Korean
  content words.

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
