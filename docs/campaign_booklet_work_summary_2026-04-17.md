# campaign_booklet 작업 요약 (2026-04-17)

## 1. 작업 목표
- `krpoltext`의 공개 `campaign_booklet` artifact를 enriched 기준으로 실제 생성한다.
- `huboid`, `sg_id`, `sg_typecode`, `link_status`, `matcher_version`, `nec_snapshot_id`를 포함하는 공개 CSV/Parquet를 만든다.
- 재현 가능한 생성 경로를 `krpoltext` repo 안에 남긴다.
- registry / static metadata와 실제 artifact를 맞춘다.

## 2. 지금까지 한 일

### 2.1 사전 검토
다음 파일들을 먼저 읽고 현재 contract와 구현 상태를 확인했다.
- `docs/nec_candidate_linkage_design_kr.md`
- `docs/nec_candidate_linkage_implementation_plan_kr.md`
- `R/catalog.R`
- `R/registry.R`
- `R/load_campaign_booklet.R`
- `docs/data/schema/campaign_booklet.json`

### 2.2 raw source 확보
raw source는 아래 경로에 확보했다.
- `F:\github\krpoltext\artifacts\campaign_booklet\source\sk_election_campaign_booklet_v2022.raw.csv`

### 2.3 초기 broad NEC snapshot 접근과 문제 확인
처음에는 `sg_id + sg_typecode` scope별 NEC 후보 snapshot을 먼저 수집하고 그 안에서 raw row를 merge하는 경로를 시도했다.

이 과정에서 다음 문제가 확인됐다.
- broad NEC 후보 풀을 그대로 target universe로 보면 `campaign_booklet` 후보 수보다 훨씬 많아진다.
- user가 지적한 것처럼 `campaign_booklet`의 target universe는 “해당 선거의 전체 NEC 후보”가 아니라 “krpoltext raw에 실제 들어 있는 후보 행”이다.
- 일부 local election에서 tally/fallback row가 부풀려지는 문제가 있었다.

### 2.4 kr-elections-mcp 쪽 수정
`F:\github\kr-elections-mcp-umbrella\kr-elections-mcp`에서 아래 수정 작업을 했다.
- `app/nec_api.py`
  - fallback result row expansion 보정
  - scope-aware dedupe 보정
- `tests/test_nec_api.py`
  - 관련 회귀 테스트 추가/수정

이 테스트는 통과했다.
- `tests/test_nec_api.py`

### 2.5 row-driven NEC matching 경로로 전환
그 다음 접근은 broad snapshot을 버리고 아래 경로로 바꿨다.
- raw `campaign_booklet` row 1건씩 처리
- `sg_id`, `sg_typecode`, `region`, `candidate_name`을 기반으로 `search_candidates` 호출
- NEC search 결과를 local scoring으로 평가
- 필요 시 `get_candidate_profile`을 추가 호출
- 보수적으로 `resolved / ambiguous / not_found` 결정

이 경로를 위해 stage script를 수정했다.
- `F:\github\kr-elections-mcp-umbrella\kr-elections-mcp\_krpoltext_stage\tools\build_campaign_booklet_enriched_duckdb.py`

추가로 multiline text 때문에 DuckDB가 CSV를 바로 Parquet로 못 읽는 문제를 피하기 위해 CSV reader 기반 Parquet converter를 새로 만들었다.
- `F:\github\kr-elections-mcp-umbrella\kr-elections-mcp\_krpoltext_stage\tools\convert_campaign_booklet_csv_to_parquet.py`

### 2.6 krpoltext 쪽 build entrypoint 반영
`krpoltext` 쪽에도 아래 스크립트를 복사/추가했다.
- `F:\github\krpoltext\tools\build_campaign_booklet_enriched_duckdb.py`
- `F:\github\krpoltext\tools\convert_campaign_booklet_csv_to_parquet.py`

### 2.7 sample build 검증
250행 sample로 row-driven build를 돌려 아래를 확인했다.
- `resolved=250`
- `resolved -> huboid non-null` 통과
- CSV header 일치 통과
- 이후 CSV reader 기반 Parquet 변환도 sample에서 통과

### 2.8 full CSV rebuild 수행
full CSV rebuild를 `krpoltext` 실제 artifact 경로에 수행했다.
초기 full run 결과는 아래였다.
- `resolved=49,672`
- `not_found=3`
- `ambiguous=3`

이 단계에서 생성/갱신된 주요 파일:
- `F:\github\krpoltext\artifacts\campaign_booklet\sk_election_campaign_booklet_v2022.csv`
- `F:\github\krpoltext\artifacts\campaign_booklet\campaign_booklet_linkage_debug.csv`
- `F:\github\krpoltext\artifacts\campaign_booklet\campaign_booklet_build_summary.json`

### 2.9 unresolved 6건 수동 검토
unresolved 6건을 따로 NEC search / profile로 재검토했다.

검토 결과:
1. `김광모`
- raw: `부산광역시`, `미래연합`, `giho=8`
- NEC hit: `김광모`, 그러나 `진보신당`, `giho=7`
- 결론: `not_found` 유지

2. `이동섭`
- 한때 false positive로 `충청남도 공주시가선거구` 후보가 잘못 붙는 문제를 발견
- raw는 `충청북도`
- 결론: `not_found` 유지

3. `우효태`
- NEC profile로 `우호태 / huboid=100102126`까지 보였음
- 그러나 `giho` 불일치가 커서 보수 기준상 확정 불가
- 결론: `not_found` 유지

4. `강명용`
- NEC profile로 `강명룡 / huboid=100112604` 확인
- 이름 OCR 오차 가능성은 높지만 `district` 부재로 아직 확정 근거 부족
- 결론: `ambiguous` 유지

5. `김대남`
- region을 지키면 NEC 후보 풀이 잡히지 않음
- fuzzy hit는 `김남성` 등만 보였고 안전하지 않음
- 결론: `not_found` 유지

6. `권해정`
- NEC profile 기준 `권혜정 / huboid=100125215` 확인
- 보수 기준에서도 올릴 수 있는 케이스로 판단
- 결론: `resolved`로 승격 가능

### 2.10 수동 후속 패치
이후 아래를 반영했다.
- `권해정` 1건을 `resolved`, `huboid=100125215`로 반영
- `김대남`은 `ambiguous`가 아니라 `not_found`로 내림
- build script에 추가 보강
  - profile lookup 시 `huboid=None` 후보가 같은 key로 엉키지 않도록 candidate-level key 사용
  - profile에서 얻은 `huboid`를 final row/debug row에 반영 가능하게 수정
  - `region` mismatch false positive를 줄이기 위한 safeguard 추가
  - historical alias 보정을 위해 `제주도 -> 제주특별자치도` alias 추가

이 수동 패치 이후 CSV / debug / summary 기준 counts는 다음과 같다.
- `resolved=49,673`
- `not_found=4`
- `ambiguous=1`

## 3. 현재 실제 상태 (문서 작성 시점)

### 3.1 실제로 존재하는 artifact
- 존재함
  - `F:\github\krpoltext\artifacts\campaign_booklet\sk_election_campaign_booklet_v2022.csv`
  - `F:\github\krpoltext\artifacts\campaign_booklet\campaign_booklet_linkage_debug.csv`
  - `F:\github\krpoltext\artifacts\campaign_booklet\campaign_booklet_build_summary.json`
- 현재 없음
  - `F:\github\krpoltext\artifacts\campaign_booklet\sk_election_campaign_booklet_v2022.parquet`

### 3.2 최신 CSV 상태
현재 summary와 수동 패치 기준 최신 CSV 상태:
- row count: `49,678`
- counts:
  - `resolved=49,673`
  - `not_found=4`
  - `ambiguous=1`
- `resolved_missing_huboid=0`
- CSV sha256: `cf27837ff4a2d7730e963323f1020606e4ffeac2ff5e69eeafc8df42abc159f0`
- CSV size_bytes: `760045361`

### 3.3 최신 debug CSV 상태
- debug CSV sha256: `d2bb15e51147bb239534d1fbb5547a33bcfd0a8ca4cd37c7e1b1086bfaa37f7b`
- debug CSV size_bytes: `14517971`

### 3.4 현재 불일치 상태
아래는 아직 다시 맞춰야 한다.
- `campaign_booklet_build_summary.json`
  - 현재 파일 안에는 Parquet가 존재하는 것처럼 남아 있지만, 실제 Parquet 파일은 현재 없음.
- `R/registry.R`
  - 마지막 수동 CSV 패치 전 값(`ecfe...`) 기준으로 남아 있음.
- `docs/data/index.json`
  - 마지막 수동 CSV 패치 전 값(`ecfe...`) 기준으로 남아 있음.
- 실제 최신 CSV hash는 `cf278...`인데 registry/index는 아직 그 값을 반영하지 못한 상태다.

## 4. 현재 repo에 남아 있는 주요 파일

### 4.1 krpoltext
- `F:\github\krpoltext\tools\build_campaign_booklet_enriched_duckdb.py`
- `F:\github\krpoltext\tools\convert_campaign_booklet_csv_to_parquet.py`
- `F:\github\krpoltext\artifacts\campaign_booklet\sk_election_campaign_booklet_v2022.csv`
- `F:\github\krpoltext\artifacts\campaign_booklet\campaign_booklet_linkage_debug.csv`
- `F:\github\krpoltext\artifacts\campaign_booklet\campaign_booklet_build_summary.json`
- `F:\github\krpoltext\artifacts\campaign_booklet\source\sk_election_campaign_booklet_v2022.raw.csv`

### 4.2 kr-elections-mcp
- `F:\github\kr-elections-mcp-umbrella\kr-elections-mcp\app\nec_api.py`
- `F:\github\kr-elections-mcp-umbrella\kr-elections-mcp\tests\test_nec_api.py`
- `F:\github\kr-elections-mcp-umbrella\kr-elections-mcp\_krpoltext_stage\tools\build_campaign_booklet_enriched_duckdb.py`
- `F:\github\kr-elections-mcp-umbrella\kr-elections-mcp\_krpoltext_stage\tools\convert_campaign_booklet_csv_to_parquet.py`

## 5. 다음 작업에 바로 필요한 TODO
1. 최신 CSV (`cf278...`) 기준으로 Parquet를 다시 생성한다.
2. `campaign_booklet_build_summary.json`을 실제 Parquet 존재 상태에 맞게 갱신한다.
3. `R/registry.R`를 최신 CSV/Parquet hash/size로 다시 갱신한다.
4. `docs/data/index.json`도 최신 CSV/Parquet hash/size로 다시 갱신한다.
5. 가능하면 `resolved -> huboid non-null`, CSV/Parquet row count, schema 일치 검증을 다시 한 번 수행한다.

## 6. 다음 작업자가 주의할 점
- 현재 summary에 적힌 Parquet 값만 믿지 말고, 실제 파일 존재 여부를 먼저 확인해야 한다.
- unresolved 6건 중 `권해정`만 수동 검토 기준으로 올릴 수 있다.
- `이동섭`은 region mismatch false positive가 실제로 한 번 발생했으므로 주의해야 한다.
- `강명용`은 이름 OCR 오차 가능성이 높지만, 현재 증거만으로는 여전히 `ambiguous`가 맞다.
- `krpoltext`가 target universe이고, broad NEC snapshot을 target universe로 쓰면 다시 candidate 수가 부풀려진다.
