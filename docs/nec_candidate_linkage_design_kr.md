# krpoltext-NEC 후보자 링크 설계 메모

## 문서 목적

이 문서는 `krpoltext`의 `campaign_booklet` 데이터에 NEC 후보자 식별자 `huboid`를 안전하게 연결하기 위한 설계 메모다. 전제는 다음과 같다.

- `krpoltext` 원본에는 `huboid`가 없다.
- `krpoltext`의 안정적인 row 식별자는 `code`다.
- NEC 쪽의 가장 강한 후보자 자연키는 `(sg_id, sg_typecode, huboid)`다.
- 같은 사람이라도 다른 선거에 다시 출마하면 같은 `person`이 아니라 다른 `candidacy`로 취급하는 것이 안전하다.
- 공개 배포는 enriched artifact를 기준으로 하되, 내부적으로는 링크 레이어와 검토 기록을 유지하는 방식이 재현성과 감사 가능성 측면에서 낫다.

## 핵심 결론

1. `krpoltext`와 NEC를 모두 직접 공유하는 단일 변수는 현재 없다.
2. `krpoltext` 쪽 안정 키는 `code`이고, NEC 쪽 안정 키는 `(sg_id, sg_typecode, huboid)`다.
3. 따라서 `huboid`를 `krpoltext`에 넣는 방식은 "원본 필드 추가"가 아니라 "NEC 링크 결과를 부착"하는 방식이어야 한다.
4. 내부 운영 구조로는 `krpoltext_raw -> krpoltext_nec_link -> krpoltext_enriched`의 3단 구조가 가장 안전하며, ambiguous한 경우를 저장할 후보군 테이블을 별도로 두는 것이 좋다.
5. 공개 배포와 패키지/API 계약은 `krpoltext_enriched` 단일 artifact를 기준으로 두는 편이 가장 단순하다.
6. raw 원본은 package/API 기본 인터페이스에서는 숨기고, 필요하면 archive/provenance 용도로만 유지한다.
7. 장기적으로 여러 소스를 통합할 계획이 있다면 내부 공통 ID인 `candidate_master_id`를 도입하고, `huboid`는 그 ID를 생성하는 가장 중요한 anchor로 사용한다.

## 왜 원본에 바로 `huboid`를 넣지 말아야 하나

`krpoltext`의 `code`는 문서 row를 식별하는 값이고, NEC의 `huboid`는 특정 선거에서의 후보자 출마 단위를 식별하는 값이다. 둘은 역할이 다르다.

원본 CSV/Parquet에 `huboid`를 직접 박아 넣으면 다음 문제가 생긴다.

- 어떤 기준으로 붙였는지 나중에 설명하기 어렵다.
- ambiguous한 row를 억지로 하나에 연결할 위험이 커진다.
- NEC 스냅샷이나 매칭 로직이 바뀔 때 재현이 어렵다.
- 사람이 검토한 결과와 자동 매칭 결과를 분리해서 관리하기 어렵다.

따라서 `huboid`는 원본 컬럼이 아니라 "검증된 링크 결과"로 취급하는 것이 맞다.

## 공개 배포에서는 어떻게 보일 것인가

공개 사용자 관점에서는 dataset이 하나로 보이는 편이 낫다. 따라서 권장 모델은 다음과 같다.

- package와 API가 기본으로 제공하는 `campaign_booklet`은 enriched 버전이다.
- 공개 CSV와 공개 Parquet는 같은 컬럼 집합을 가져야 한다.
- `huboid`, `sg_id`, `sg_typecode`는 native field가 아니라 NEC alignment를 위한 linked field로 문서화한다.
- raw 원본은 package/API에서 기본 노출하지 않고, 필요하면 archive 또는 provenance 용도로만 보존한다.

즉, 내부적으로는 raw/link/review 레이어가 존재하더라도, 외부 계약은 "enriched 하나"로 수렴시키는 것이 좋다.

## 식별 원칙

### 1. 식별 단위는 사람이 아니라 출마다

- 같은 사람이 2016년, 2020년, 2024년에 각각 출마했다면 3개의 서로 다른 candidate row가 된다.
- 이 설계는 `person_master`보다 `candidacy_master`를 먼저 두는 쪽이 안전하다.

### 2. 각 소스는 자기 키를 유지한다

- `krpoltext` row key: `code`
- NEC candidate key: `(sg_id, sg_typecode, huboid)`
- 내부 공통키가 필요하면 별도로 `candidate_master_id`를 발급한다.

### 3. 이름은 절대 단독 키가 아니다

이름은 필터링과 후보 축소에는 유용하지만, 최종 식별 키로는 부적절하다. 같은 선거, 같은 지역, 같은 이름의 충돌이 실제로 발생할 수 있기 때문이다.

## 권장 모델: 단계적 도입

### Phase 1: 최소 링크 모델

이 단계에서는 `krpoltext`와 NEC를 연결하는 데 필요한 최소 구조만 둔다.

- `krpoltext_raw`
- `krpoltext_nec_link`
- `krpoltext_nec_link_candidate`
- `krpoltext_enriched`

### Phase 2: 확장 통합 모델

다른 소스까지 묶을 계획이 생기면 다음을 추가한다.

- `candidacy_master`
- 필요시 `person_master`
- 기타 source-specific link tables

현재 목적이 `krpoltext`에 `huboid`를 안전하게 붙이고 package/API에서 바로 쓰게 하는 것이라면, 내부적으로는 Phase 1 구조면 충분하고 공개적으로는 enriched artifact 하나만 내보내면 된다.

## 권장 테이블 설계

### 1. `krpoltext_raw`

원본 코퍼스를 보존하는 레이어다.

| 컬럼 | 설명 |
|------|------|
| `krpoltext_code` | `code`를 그대로 복사한 row 식별자 |
| `candidate_name_raw` | 원본 `name` |
| `election_date_raw` | 원본 `date` |
| `election_year` | `date`에서 추출한 연도 |
| `office_id` | 원본 `office_id` |
| `office_name_raw` | 원본 `office` |
| `region_raw` | 원본 `region` |
| `district_raw` | 원본 `district` |
| `party_name_raw` | 원본 `party` |
| `giho_raw` | 원본 `giho` |
| `birthday_raw` | 원본 `birthday` |
| `age_raw` | 원본 `age` |
| `job_raw` | 원본 `job` 또는 `job_name` |
| `edu_raw` | 원본 `edu` 또는 `edu_name` |
| `career1_raw` | 원본 `career1` |
| `career2_raw` | 원본 `career2` |
| `source_snapshot_id` | 어떤 원본 스냅샷에서 적재했는지 표시 |
| `raw_payload` | 필요시 원본 JSON/row blob |

원칙:

- 이 레이어에는 `huboid`를 넣지 않는다.
- 원본 문자열은 가급적 그대로 유지한다.
- 전처리된 값은 별도 컬럼이나 별도 뷰로 관리한다.

### 2. `krpoltext_nec_link`

각 `krpoltext` row에 대한 최종 링크 결과를 저장한다.

| 컬럼 | 설명 |
|------|------|
| `krpoltext_code` | 링크 대상 row |
| `link_status` | `resolved`, `ambiguous`, `not_found`, `rejected` |
| `sg_id` | NEC 선거 식별자 |
| `sg_typecode` | NEC 선거 유형 식별자 |
| `huboid` | 최종 연결된 NEC 후보자 ID |
| `candidate_master_id` | 내부 통합 ID가 있으면 저장 |
| `resolved_candidate_name` | 연결된 NEC 후보자 이름 |
| `resolved_district_label` | 연결된 NEC 정규화 선거구 라벨 |
| `resolved_party_name` | 연결된 NEC 정당명 |
| `resolved_giho` | 연결된 NEC 후보 번호 |
| `resolved_birthday` | 연결된 NEC 생년월일 |
| `match_method` | 어떤 신호 조합으로 연결했는지 |
| `match_confidence` | 0~1 범위 점수 |
| `strong_signal_count` | 최종 확정에 기여한 strong signal 수 |
| `review_status` | `auto_accepted`, `needs_review`, `human_accepted`, `human_rejected` |
| `reviewer` | 사람이 검토했다면 검토자 |
| `reviewed_at` | 검토 시각 |
| `decision_note` | 검토 메모 |
| `matcher_version` | 매칭 로직 버전 |
| `nec_snapshot_id` | 어떤 NEC 스냅샷 기준으로 매칭했는지 |
| `source_snapshot_id` | 어떤 `krpoltext` 스냅샷 기준인지 |
| `created_at` | 생성 시각 |
| `updated_at` | 갱신 시각 |

원칙:

- `resolved`인데 `huboid`가 없으면 안 된다.
- `ambiguous`와 `not_found`는 `huboid`를 비워 둔다.
- 자동 매칭과 사람 승인 결과를 함께 저장하되, 상태를 분리한다.

### 3. `krpoltext_nec_link_candidate`

ambiguous한 경우 후보군과 점수 근거를 저장한다.

| 컬럼 | 설명 |
|------|------|
| `krpoltext_code` | 원본 row |
| `rank` | 후보 순위 |
| `sg_id` | 후보의 NEC 선거 ID |
| `sg_typecode` | 후보의 NEC 선거 유형 |
| `huboid` | 후보의 NEC huboid |
| `candidate_name` | NEC 후보자 이름 |
| `district_label` | NEC 정규화 선거구 |
| `party_name` | NEC 정당명 |
| `giho` | NEC 후보 번호 |
| `birthday` | NEC 생년월일 |
| `score_total` | 총점 |
| `score_name` | 이름 점수 |
| `score_office` | 직위 점수 |
| `score_district` | 선거구 점수 |
| `score_party` | 정당 점수 |
| `score_giho` | 후보 번호 점수 |
| `score_birthday` | 생년월일 점수 |
| `score_education` | 학력 점수 |
| `score_career` | 경력 점수 |
| `is_top_candidate` | 1위 후보 여부 |
| `warning_summary` | 불일치 또는 주의사항 |

이 테이블의 목적은 "왜 자동 확정하지 않았는가"를 나중에도 설명할 수 있게 하는 것이다.

### 4. `krpoltext_enriched`

분석용 파생 뷰 또는 테이블이다.

| 컬럼군 | 설명 |
|--------|------|
| `krpoltext_raw.*` | 원본 row 정보 |
| `link_status` | 링크 상태 |
| `sg_id`, `sg_typecode`, `huboid` | NEC 연결 결과 |
| `candidate_master_id` | 내부 통합 ID |
| `match_method`, `match_confidence` | 매칭 근거 |
| `review_status` | 자동 승인인지 사람 승인인지 |

원칙:

- 외부 분석과 downstream 사용은 이 레이어를 읽게 한다.
- 원본 row는 그대로 두고, 링크 결과만 옆에 붙인다.
- ambiguous한 row는 `huboid = null`로 유지한다.
- 공개 package/API와 OSF 기본 배포물은 이 레이어를 기준으로 한다.

권장 공개 컬럼:

- 원본 분석에 이미 쓰이는 주요 필드
- `code`
- `huboid`
- `sg_id`
- `sg_typecode`
- `link_status`
- `nec_snapshot_id`
- `matcher_version`

## 선택적 확장: `candidacy_master`

장기적으로는 `huboid`를 직접 쓰기보다, 내부 통합 ID인 `candidate_master_id`를 중심으로 가는 편이 좋다.

권장 최소 컬럼:

- `candidate_master_id`
- `canonical_source`
- `sg_id`
- `sg_typecode`
- `huboid`
- `election_year`
- `office_id`
- `office_name`
- `district_uid`
- `district_label`
- `candidate_name_canonical`
- `party_name_canonical`
- `giho`
- `birthday`
- `identity_status`

이 레이어는 여러 소스를 한 후보자 단위로 묶을 때 유용하지만, `krpoltext`에 `huboid`를 붙이는 목적만으로는 당장 필수는 아니다.

## 키와 유니크 제약 권장안

### 자연키

- `krpoltext_raw`: `krpoltext_code`
- NEC candidate: `(sg_id, sg_typecode, huboid)`
- optional internal key: `candidate_master_id`

### 유니크 제약

- `krpoltext_raw`: `unique (krpoltext_code)`
- `krpoltext_nec_link`: `unique (krpoltext_code)`
- `krpoltext_nec_link_candidate`: `unique (krpoltext_code, rank)`
- `candidacy_master`: `unique (sg_id, sg_typecode, huboid)` where `huboid is not null`

### 주의할 점

- `candidacy_uid`처럼 이름 fallback이 들어간 문자열은 편의용 내부 식별자일 수는 있어도 영구 자연키로는 약하다.
- 이름 정규화 문자열을 최종 키로 쓰면 안 된다.

## 매칭 파이프라인

### 1단계: 선거 스코프 복원

`krpoltext_raw`에서 다음을 읽어 선거 스코프를 복원한다.

- `election_date_raw` 또는 `election_year`
- `office_id` 또는 `office_name_raw`
- `region_raw`, `district_raw`

목표는 NEC의 `sg_id`, `sg_typecode`, 정규화 선거구 라벨 후보를 만드는 것이다.

### 2단계: NEC 후보군 생성

복원한 선거 스코프 안에서 NEC 후보자 풀을 생성한다.

- 같은 `sg_id`
- 같은 `sg_typecode`
- 가능한 경우 같은 시도/선거구 범위

### 3단계: 약한 신호로 1차 축소

다음 필드로 후보군을 줄인다.

- 이름
- 직위
- 선거구
- 정당

이 단계는 후보를 좁히는 단계이지 최종 확정 단계가 아니다.

### 4단계: 강한 신호로 최종 확정

다음 신호를 strong signal로 사용한다.

- `birthday`
- `giho`
- 보조적으로 `edu`, `job`, `career1`, `career2`

### 5단계: 상태 결정

- 한 후보만 강하게 남으면 `resolved`
- plausible한 후보가 둘 이상 남으면 `ambiguous`
- 충분히 강한 후보가 없으면 `not_found`

## 신호 우선순위

권장 우선순위는 다음과 같다.

1. `sg_id`, `sg_typecode`, `huboid`가 이미 알려진 경우 direct match
2. 선거연도와 직위
3. 정규화 선거구
4. 후보자 이름
5. 정당명
6. `birthday`
7. `giho`
8. `edu`, `job`, `career1`, `career2`

해석 주의:

- `giho`는 선거구 내부에서는 강하지만 전국 단위 유일키는 아니다.
- `birthday`는 강하지만 누락 또는 형식 차이가 있을 수 있다.
- `education`과 `career`는 텍스트 차이로 인해 fuzzy하게 다뤄야 한다.

## 자동 확정 규칙

자동으로 `huboid`를 넣어도 되는 경우:

- 같은 선거 스코프에서 1명만 남고 `birthday`가 exact match
- 같은 선거, 같은 선거구, 같은 이름에서 `giho` exact match이고 정당 또는 district가 추가로 일치
- `birthday`는 없지만 `education + career`가 복수 strong signal로 유일하게 수렴

자동으로 확정하면 안 되는 경우:

- 같은 선거, 같은 선거구, 같은 이름인데 `birthday`와 `giho`가 모두 없음
- `giho`만 맞고 이름이나 선거구가 흔들림
- 선거연도만 맞고 office/district가 약함
- 후보군 점수 차이가 작고 2명 이상이 비슷하게 plausible함

## 상태와 검토 흐름

### `link_status`

- `resolved`: 최종 연결됨
- `ambiguous`: 복수 후보 남음
- `not_found`: 충분히 강한 후보 없음
- `rejected`: 기존 링크를 폐기함

### `review_status`

- `auto_accepted`: 자동 규칙으로 승인됨
- `needs_review`: 사람이 봐야 함
- `human_accepted`: 사람이 승인함
- `human_rejected`: 사람이 반려함

### 운영 원칙

- `ambiguous`는 절대 억지로 하나를 고르지 않는다.
- 사람 검토가 개입한 경우 근거를 `decision_note`에 남긴다.
- 자동 링크라도 `matcher_version`, `nec_snapshot_id`, `source_snapshot_id`를 저장한다.

## 운영 및 배포 권장안

### 배치 실행 원칙

- 라이브 NEC API를 즉석 호출해서 매번 실시간 링크하기보다, NEC snapshot을 확보한 뒤 배치로 링크한다.
- 동일한 입력 snapshot과 동일한 matcher version이면 동일한 결과가 나와야 한다.

### 배포 원칙

- 공개 배포물은 `krpoltext_enriched` 하나를 기준으로 한다.
- package와 API는 enriched artifact를 기본으로 읽게 한다.
- raw 원본은 필요하면 archive/provenance 용도로만 별도 보존한다.
- `krpoltext_nec_link`, `krpoltext_nec_link_candidate`는 내부 관리용으로 유지하고 공개 기본 아티팩트로는 배포하지 않는다.
- 공개 CSV와 Parquet를 모두 제공한다면 반드시 동일 스키마를 유지한다.

### 문서화 권장 문구

- `huboid is not native to krpoltext and is assigned only through audited linkage to NEC candidate records.`
- `Unresolved or ambiguous links remain null in krpoltext_enriched.huboid until reviewed.`
- `The package and API expose the enriched campaign_booklet artifact; the native source snapshot is retained only for provenance and reproducibility.`

## 품질 관리 체크리스트

- `resolved`인데 `huboid`가 null이면 오류
- `human_accepted`인데 `decision_note`가 비어 있으면 경고
- `ambiguous`인데 후보군 테이블 row가 없으면 오류
- 동일한 `krpoltext_code`가 서로 다른 `resolved huboid`로 중복 승인되면 오류
- `matcher_version` 또는 snapshot 정보가 비어 있으면 재현성 경고

## Upstream 관점에서 있으면 좋은 것

향후 `krpoltext` 또는 관련 API가 아래 값을 직접 제공하면 연결 안정성이 크게 올라간다.

- NEC 후보자 식별자 `huboid` 또는 `cnddtId`
- 정확한 NEC 선거 식별자 `sg_id`, `sg_typecode`
- 문자열이 아닌 canonical district identifier
- row-level metadata endpoint
- metadata-only artifact와 안정적인 schema endpoint

## 최종 권고

현재 목적에 가장 잘 맞는 실무적 결론은 다음과 같다.

1. `krpoltext` 원본에는 `huboid`를 직접 박지 않는다.
2. `code` 기준의 링크 테이블을 만든다.
3. package/API와 공개 배포는 enriched artifact 하나를 기준으로 한다.
4. `huboid`는 linked NEC identifier로 문서화하고, `code`는 계속 row identifier로 유지한다.
5. ambiguous한 row는 반드시 `null`로 남긴다.
6. raw 원본은 필요하면 archive/provenance 용도로만 유지한다.
7. 장기적으로는 `candidate_master_id` 중심 구조로 확장할 수 있게 설계한다.
