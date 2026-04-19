# krpoltext-NEC 후보자 링크 작업용 프롬프트

아래 프롬프트는 다른 모델, 협업자, 또는 미래의 작업 세션에 그대로 전달할 수 있도록 작성한 handoff prompt다. 먼저 다음 두 문서를 읽게 한 뒤 작업을 요청하는 용도다.

- `docs/nec_candidate_linkage_design_kr.md`
- `docs/nec_candidate_linkage_erd_kr.md`

## 복사용 프롬프트

```text
다음 두 문서를 먼저 읽어 주세요.

1. docs/nec_candidate_linkage_design_kr.md
2. docs/nec_candidate_linkage_erd_kr.md

문서 내용을 바탕으로, `krpoltext`의 campaign_booklet 데이터에 NEC 후보자 식별자 `huboid`를 안전하게 연결하는 구현 계획 또는 리뷰를 도와주세요.

배경:
- `krpoltext` 원본 데이터에는 `huboid`가 없습니다.
- `krpoltext`의 안정적인 row key는 `code`입니다.
- NEC 쪽의 안정적인 후보자 자연키는 `(sg_id, sg_typecode, huboid)`입니다.
- 목표는 원본을 오염시키지 않으면서, `code` 기준 링크 레이어를 통해 검증된 `huboid`를 enriched artifact에 제공하는 것입니다.
- package와 API는 최종적으로 enriched artifact를 기본으로 제공하고, raw 원본은 필요하면 archive/provenance 용도로만 유지할 계획입니다.

반드시 지켜야 할 제약:
- `krpoltext` 원본 row를 덮어쓰지 말 것
- `code`를 후보자 ID로 승격하지 말 것
- `huboid`는 native field가 아니라 audited linkage 결과로 다룰 것
- ambiguous한 매치는 자동 확정하지 말고 `null` 또는 review queue로 남길 것
- 이름은 단독 식별키로 사용하지 말 것
- 가능하면 `matcher_version`, `nec_snapshot_id`, `source_snapshot_id` 같은 재현성 필드를 유지할 것
- 공개 CSV와 공개 Parquet를 둘 다 제공한다면 동일 스키마를 유지할 것

원하는 출력 형식:
1. 제안하는 구현 범위 요약
2. 필요한 테이블/파일/뷰 목록
3. 매칭 파이프라인 단계별 설명
4. 자동 확정 규칙과 human review 규칙
5. 테스트 전략
6. 데이터 품질 체크리스트
7. 남아 있는 리스크와 오픈 이슈

상황에 따라 둘 중 하나로 답해 주세요.
- 구현 전 검토라면: 설계의 약점, 누락된 edge case, 더 나은 대안을 중심으로 리뷰
- 구현 단계라면: 파일별 변경 계획, 함수 책임 분리, 테스트 계획까지 포함한 실행안

추가로 확인해 주었으면 하는 포인트:
- package/API의 canonical public artifact를 `campaign_booklet` enriched 하나로 둘 때 생길 장단점
- raw 원본을 archive/provenance 용도로만 둘 경우 필요한 최소 메타데이터
- `candidacy_master`를 지금 도입할지, 아니면 Phase 2로 미룰지
- `giho`, `birthday`, `edu`, `career`를 어떤 순서와 강도로 scoring에 반영할지
- same-name collision을 어떤 기준에서 `ambiguous`로 유지할지
- `code` 기준 링크 테이블의 유니크 제약과 상태 전이 규칙이 충분한지
- 공개 스키마에서 `huboid`를 어떤 문구로 설명해야 raw/native identifier로 오해되지 않을지

가능하면 최종 답변은 한국어로 작성해 주세요.
```

## 사용 메모

- 구현을 바로 시킬 때는 프롬프트 마지막에 "구체적인 파일 단위 변경안까지 작성해 달라"를 추가하면 된다.
- 리뷰만 받고 싶으면 "코드는 쓰지 말고 설계 리뷰만 해 달라"를 추가하면 된다.
- 외부 협업자에게 넘길 때는 현재 데이터 스냅샷 위치와 NEC snapshot 위치를 추가로 적어 주면 더 정확한 답을 받기 쉽다.
