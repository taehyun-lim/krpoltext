# krpoltext-NEC 후보자 링크 구현 계획

## 문서 목적

이 문서는 `krpoltext`의 공개 배포 모델을 `public enriched artifact` 중심으로 정리한 구현 실행안이다. 이번 버전의 핵심은 다음과 같다.

- package와 API가 기본으로 제공하는 `campaign_booklet`은 enriched 버전이다.
- `huboid`는 원본 native identifier가 아니라 `kr-elections-mcp` alignment를 위한 linked NEC identifier다.
- raw 원본은 package/API 기본 인터페이스에서 노출하지 않는다.
- raw 원본은 필요할 때만 archive/provenance 용도로 유지한다.
- 내부적으로는 raw/link/review 레이어를 유지할 수 있지만, 공개 계약은 enriched 하나로 수렴시킨다.

## 이번 초안의 결정

### 1. public contract

- 공개 기준 아티팩트는 enriched `campaign_booklet`이다.
- 공개 CSV와 공개 Parquet를 둘 다 제공한다면 반드시 동일한 enriched 스키마를 유지한다.
- 사용자-facing 문서, `metadata()`, `schema()`, static API는 모두 enriched 기준으로 설명한다.

### 2. raw 원본의 위치

- raw 원본은 package/API에서 기본으로 읽지 않는다.
- raw는 재현성, provenance, 회귀 검증을 위해 archive 용도로만 유지한다.
- raw를 OSF에 유지하더라도 기본 다운로드 링크나 quick start는 enriched를 가리키게 한다.

### 3. 내부 운영 레이어

- 내부적으로는 `krpoltext_raw`, `krpoltext_nec_link`, `krpoltext_nec_link_candidate`를 유지할 수 있다.
- 이 레이어는 공개 배포물이 아니라 링크 생성과 검토를 위한 내부 운영 자료다.
- `schema/nec_candidate_linkage.sql`은 public contract가 아니라 optional internal reference로만 취급한다.

### 4. 공개 스키마에 반드시 들어갈 필드

- 기존 `campaign_booklet` 분석 필드
- `code`
- `huboid`
- `sg_id`
- `sg_typecode`
- `link_status`
- `matcher_version`
- `nec_snapshot_id`

필요하면 추가:

- `review_status`
- `resolved_district_label`
- `resolved_party_name`

### 5. 초기 scoring / resolution 규칙

- gate 1: 선거 스코프(`sg_id`, `sg_typecode`)가 복원되어야 한다.
- gate 2: 이름은 정규화 exact match 또는 신뢰 가능한 alias match여야 한다.
- score priority: `birthday` > `giho` > `district` > `party` > `education` > `career`
- auto resolve 초안:
  - `birthday` exact + 단일 후보
  - 또는 `giho` exact + `district` 또는 `party` exact + 단일 후보
  - 또는 총점이 충분히 높고 2위와 점수 차가 큰 경우
- ambiguous 유지 초안:
  - 동일 스코프/동일 이름 후보가 2명 이상 남고 `birthday`가 없거나 충돌
  - `giho`만 맞고 district 또는 party가 흔들리는 경우
  - 1위와 2위 점수 차가 작아 사람이 판단해야 하는 경우

## 구현 단계

### Phase 0. 공개 계약 먼저 고정

목표:

- enriched `campaign_booklet`의 공개 스키마를 먼저 확정
- 문서, metadata, API 설명을 raw가 아니라 enriched 기준으로 맞춤

완료 기준:

- `R/catalog.R`, `R/registry.R`, `R/metadata.R`, `docs/data/schema/campaign_booklet.json`, `data_dictionary.md`가 enriched를 기준으로 설명
- `huboid`가 linked identifier라는 문구가 문서와 schema에 일관되게 반영

### Phase 1. 내부 링크 파이프라인 구현

목표:

- raw `campaign_booklet`와 NEC snapshot에서 enriched 결과를 재현 가능하게 생성
- 내부적으로 `krpoltext_nec_link`, `krpoltext_nec_link_candidate` 수준의 중간 결과를 유지

완료 기준:

- 같은 source snapshot + NEC snapshot + matcher version이면 동일 결과 재생성
- `resolved` / `ambiguous` / `not_found` 상태가 일관되게 산출
- same-name collision fixture에서 보수적으로 `ambiguous` 유지

### Phase 2. enriched 아티팩트 배포 연결

목표:

- package와 API가 enriched artifact를 기본으로 읽도록 연결
- OSF 기본 다운로드와 문서를 enriched 중심으로 전환

완료 기준:

- `load_campaign_booklet()`가 enriched 스키마를 반환
- static API schema가 enriched 컬럼을 노출
- quick start와 README가 enriched를 기준으로 설명

### Phase 3. archive/provenance 정리

목표:

- raw 원본을 유지할 경우 archive 용도로만 분리 관리
- 사용자-facing 경로와 archive 경로를 문서상 분리

완료 기준:

- raw의 위치와 목적이 분명히 문서화
- 사용자는 기본적으로 enriched만 쓰게 됨

## 파일 단위 구현안

아래는 우선순위 순서다.

### 새 파일

#### 1. `R/linkage_constants.R`

역할:

- `link_status`, `review_status` 상수 정의
- score component 이름과 threshold 정의
- matcher version helper 제공

핵심 함수 초안:

- `.link_status_levels()`
- `.review_status_levels()`
- `.default_linkage_thresholds()`
- `.default_matcher_version()`

#### 2. `R/linkage_normalize.R`

역할:

- 이름, 정당, 선거구, 생년월일, 기호를 비교 가능한 표준형으로 정리

핵심 함수 초안:

- `.normalize_candidate_name()`
- `.normalize_party_name()`
- `.normalize_district_label()`
- `.normalize_birthday()`
- `.normalize_giho()`

주의:

- 이름 정규화는 filtering 용도이지 최종 식별키 생성 용도가 아니다.

#### 3. `R/linkage_scope.R`

역할:

- `campaign_booklet` row에서 NEC 선거 스코프 후보를 복원

핵심 함수 초안:

- `.infer_nec_scope_from_booklet_row()`
- `.office_to_sg_typecode()`
- `.build_scope_key()`

#### 4. `R/linkage_candidates.R`

역할:

- NEC snapshot에서 scope 기준 후보군 생성
- 이름과 기본 메타데이터로 1차 축소

핵심 함수 초안:

- `.candidate_pool_from_scope()`
- `.filter_candidates_by_name()`
- `.attach_candidate_features()`

#### 5. `R/linkage_score.R`

역할:

- 후보군별 score component 계산
- warning과 mismatch 이유 생성

핵심 함수 초안:

- `.score_name_signal()`
- `.score_district_signal()`
- `.score_party_signal()`
- `.score_giho_signal()`
- `.score_birthday_signal()`
- `.score_education_signal()`
- `.score_career_signal()`
- `.score_candidate_pool()`

#### 6. `R/linkage_resolve.R`

역할:

- ranked candidate table을 최종 enriched 링크 결과로 축약

핵심 함수 초안:

- `.resolve_ranked_candidates()`
- `.is_auto_resolvable()`
- `.build_link_row()`

핵심 규칙:

- `resolved`이면 `huboid` 필수
- `ambiguous` / `not_found`이면 `huboid = NA`
- `auto_accepted`는 `resolved`에서만 허용

#### 7. `R/build_campaign_booklet_enriched.R`

역할:

- raw `campaign_booklet`와 NEC snapshot을 받아 enriched 결과를 생성하는 핵심 진입점

권장 반환값:

- named list with `campaign_booklet_enriched`, `link_decisions`, `link_candidates`

메모:

- 공개 배포는 `campaign_booklet_enriched`만 쓰더라도, 내부 검토를 위해 나머지 두 테이블을 함께 반환하는 편이 좋다.

#### 8. `R/linkage_review.R`

역할:

- ambiguous row를 사람이 승인/반려할 때 쓰는 helper

핵심 함수 초안:

- `accept_campaign_booklet_link()`
- `reject_campaign_booklet_link()`
- `reopen_campaign_booklet_link()`

규칙:

- human decision은 reviewer, reviewed_at, decision_note 없이는 완료되면 안 된다.

#### 9. `tools/build_nec_snapshot.R`

역할:

- NEC 원천 데이터를 canonical Parquet snapshot으로 정리
- 필드명, 날짜형, district label을 통일

출력:

- `nec_candidate_snapshot.parquet`

#### 10. `tools/build_campaign_booklet_enriched.R`

역할:

- end-to-end batch runner
- raw source 로드, NEC snapshot 로드, 링크 빌드, 품질 검사, enriched export 담당

출력:

- public artifact: enriched CSV/Parquet
- internal artifact: review/debug용 intermediate outputs

#### 11. `schema/nec_candidate_linkage.sql`

역할:

- optional internal PostgreSQL reference
- review queue나 운영 DB가 필요할 때만 사용

메모:

- public package/API contract로 취급하지 않는다.
- 구현을 반드시 SQL로 할 필요는 없다.

#### 12. `tests/testthat/test-linkage-normalize.R`

테스트 범위:

- 이름/정당/선거구/기호/생년월일 정규화
- 결측치와 형식 차이 처리

#### 13. `tests/testthat/test-linkage-score.R`

테스트 범위:

- `birthday`, `giho`, `district`, `party`, `edu`, `career` scoring
- 동점과 근소 차이 처리

#### 14. `tests/testthat/test-linkage-resolve.R`

테스트 범위:

- `resolved`, `ambiguous`, `not_found`, `rejected`
- `review_status` 전이 규칙

#### 15. `tests/testthat/test-campaign-booklet-enriched.R`

테스트 범위:

- enriched 출력 컬럼 집합
- `huboid`, `sg_id`, `sg_typecode`, `link_status`, `matcher_version`, `nec_snapshot_id` 존재 여부
- unresolved row에서 `huboid` null 정책

### 기존 파일 수정

#### 16. `R/load_campaign_booklet.R`

역할:

- package 사용자에게 반환하는 기본 dataset이 enriched 스키마라는 점을 반영
- roxygen 문서의 컬럼 설명을 업데이트

핵심 수정:

- 반환 컬럼 설명에 `huboid`, `sg_id`, `sg_typecode`, `link_status`, `matcher_version`, `nec_snapshot_id` 추가
- `code`는 row identifier이고 `huboid`는 linked NEC identifier라는 설명 추가

#### 17. `R/catalog.R`

역할:

- `campaign_booklet` dataset spec를 enriched 기준으로 업데이트

핵심 수정:

- columns 목록에 링크 필드 추가
- notes에 linked identifier 설명 추가
- raw는 공개 dataset catalog에서 기본 설명 대상으로 쓰지 않음

#### 18. `R/registry.R`

역할:

- `campaign_booklet` artifact를 enriched 파일 기준으로 갱신

핵심 수정:

- 파일명, SHA, size, version을 enriched artifact 기준으로 갱신
- raw archive가 남더라도 public registry에는 기본 artifact로 넣지 않음

#### 19. `R/metadata.R`

역할:

- `metadata("campaign_booklet")`와 `schema("campaign_booklet")`가 enriched 정의를 반환하도록 유지

핵심 수정:

- identifier 설명에서 `code`와 `huboid`의 역할 차이를 명시

#### 20. `docs/data/schema/campaign_booklet.json`

역할:

- static API의 canonical public schema

핵심 수정:

- 링크 필드 추가
- `huboid` description에 native field가 아니라 linkage-derived identifier라고 명시

#### 21. `docs/data/metadata.json`

역할:

- static metadata에서 `campaign_booklet` 설명을 enriched 기준으로 갱신

핵심 수정:

- description, notes, download url이 enriched 기준인지 점검

#### 22. `tools/build_api.R`

역할:

- 정적 API JSON 산출물이 enriched schema를 반영하도록 생성

#### 23. `data_dictionary.md`

역할:

- 사용자-facing 데이터 사전이 enriched 기준이 되도록 수정

핵심 수정:

- 기존 booklet 컬럼 설명에 링크 필드 추가
- `huboid`는 linked NEC identifier, `code`는 document row identifier라고 명시

#### 24. `README.md`, `README_kr.md`, `vignettes/quick-start.Rmd`

역할:

- quick start와 패키지 소개가 enriched 사용법을 기준으로 하도록 갱신

핵심 수정:

- 예시 출력에 링크 필드 반영
- `kr-elections-mcp` alignment를 위한 필드라는 설명 추가
- raw archive는 기본 사용 흐름에서 제거

#### 25. `tests/testthat/test-metadata.R`

역할:

- `metadata()` / `schema()`가 enriched 스키마를 설명하는지 검증

핵심 수정:

- `huboid`, `sg_id`, `sg_typecode`, `link_status` 등의 존재 확인

#### 26. `tests/testthat/test-load.R`

역할:

- `load_campaign_booklet()`가 enriched artifact를 정상 로드하는지 검증

핵심 수정:

- fixture 컬럼에 링크 필드 포함
- 로더가 새 컬럼을 유지하는지 확인

## 권장 함수 책임 분리

- normalization은 pure function으로 둔다.
- scope inference는 NEC와 분리된 로직으로 둔다.
- scoring은 입력/출력이 분명한 테이블 함수로 둔다.
- resolution은 scoring 결과만 보고 상태를 결정하게 둔다.
- export는 public enriched artifact와 internal intermediate artifact를 분리해 관리한다.

이렇게 나누면 테스트가 쉬워지고, public contract와 내부 매칭 로직이 서로 덜 얽힌다.

## 테스트 전략

### 1. 작은 fixture 우선

- same-name collision 케이스를 최소 fixture로 만든다.
- `birthday`가 있는 경우와 없는 경우를 분리한다.
- `giho`는 맞지만 district가 다른 케이스를 분리한다.

### 2. public contract 테스트

- 공개 CSV와 공개 Parquet가 같은 컬럼 집합을 가지는지 확인한다.
- `code`는 항상 존재해야 한다.
- `huboid`는 일부 row에서 `NA`일 수 있지만 컬럼 자체는 항상 존재해야 한다.

### 3. property-like 체크

- `resolved`이면 항상 `huboid`가 있어야 한다.
- `ambiguous`이면 사람이 검토할 수 있는 intermediate evidence가 남아야 한다.
- `human_accepted`이면 reviewer / reviewed_at / decision_note가 있어야 한다.

### 4. snapshot reproducibility

- 같은 source snapshot, NEC snapshot, matcher version이면 결과 checksum이 같아야 한다.

## 운영 체크리스트

- 공개 package/API 기본 아티팩트는 enriched 하나인지 확인
- 공개 CSV와 Parquet 스키마가 동일한지 확인
- `huboid` 설명이 native identifier처럼 읽히지 않는지 확인
- review 과정에서 수동 수정이 있더라도 raw source row는 수정하지 않는지 확인
- matcher version을 바꾸면 결과를 새로 생성하고 변경 사실을 문서화

## 바로 다음 작업 추천

우선순위는 다음 순서가 가장 좋다.

1. `R/catalog.R`, `R/registry.R`, `R/metadata.R`, `docs/data/schema/campaign_booklet.json`의 공개 계약부터 enriched 기준으로 수정
2. `R/linkage_normalize.R`, `R/linkage_scope.R`, `R/linkage_score.R`, `R/linkage_resolve.R` 작성
3. fixture 기반 테스트 작성
4. `tools/build_campaign_booklet_enriched.R`로 end-to-end export 연결
5. README와 quick start를 enriched 기준으로 마무리
