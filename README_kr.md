# krpoltext

<!-- badges: start -->
[![R-CMD-check](https://github.com/taehyun-lim/krpoltext/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/taehyun-lim/krpoltext/actions/workflows/R-CMD-check.yaml)
[![License: MIT](https://img.shields.io/badge/code-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![License: CC BY-NC-ND 4.0](https://img.shields.io/badge/data-CC%20BY--NC--ND%204.0-lightgrey.svg)](https://creativecommons.org/licenses/by-nc-nd/4.0/)
[![DOI](https://img.shields.io/badge/DOI-10.1038%2Fs41597--025--05220--4-blue)](https://doi.org/10.1038/s41597-025-05220-4)
[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.18704319.svg)](https://doi.org/10.5281/zenodo.18704319)
<!-- badges: end -->

[English](README.md) | 한국어

**krpoltext**는 다음 논문에서 소개된 두 개의 대규모 한국 정치 텍스트 코퍼스에 R에서 손쉽게 접근할 수 있도록 돕는 패키지입니다.

> Lim, T.H. (2025). South Korean Election Campaign Booklet and Party
> Statements Corpora. *Scientific Data*, 12, 1030.
> <https://doi.org/10.1038/s41597-025-05220-4>

| 코퍼스 | 기간 | 후보자 / 문서 수 | 설명 |
|--------|------|------------------|------|
| **선거공보 코퍼스** | 2000–2022 | 49,678 candidates | 대통령선거, 국회의원선거, 지방선거 후보자의 선거공보 텍스트 |
| **정당 성명 코퍼스** | 2003–2022 | 83,201 statements | 양대 정당의 공식 성명과 지도부 회의 발언문 |

데이터는 [Open Science Framework](https://osf.io/rct9y/)에 호스팅되어 있으며
(DOI: [10.17605/OSF.IO/RCT9Y](https://doi.org/10.17605/OSF.IO/RCT9Y)),
관리형 아티팩트가 필요할 경우 대화형 세션에서 처음 사용할 때 자동으로
다운로드됩니다. 비대화형 세션에서는 로컬 파일 경로나 미리 채워둔 cache를
사용해야 합니다.

## 릴리스 노트

최근 패키지 변경 사항은 아래에서 확인할 수 있습니다.

- [NEWS.md](NEWS.md)
- GitHub Releases: <https://github.com/taehyun-lim/krpoltext/releases>

## 설치

```r
# install.packages("remotes")
remotes::install_github("taehyun-lim/krpoltext")
```

## 빠른 시작

```r
library(krpoltext)

# 관리형 Parquet 아티팩트를 명시적으로 사용
ps <- load_party_statements(format = "parquet")
cb <- load_campaign_booklet(format = "parquet")

# 메타데이터 확인
metadata("party_statements")
schema("party_statements")

# 문서 필터링
docs_2020 <- get_docs("party_statements", year = 2020)
conservative <- get_docs("party_statements", year = 2018:2022, conservative = 1)
strict_subset <- get_docs(
  "party_statements",
  year = 2020,
  .select = c("year", "title", "text"),
  .strict = TRUE
)

# 선거공보 데이터에서 선거 종류와 정당 기준으로 필터링
assembly <- get_docs("campaign_booklet", office = "national_assembly", .data = cb)
```

## 데이터 다운로드

관리형 아티팩트는 현재 OSF에서 CSV와 Parquet 두 형식으로 제공됩니다.
`load_*()` helper는 관리형 Parquet 아티팩트를 사용할 수 있지만,
`download_data()`는 여전히 CSV prefetch helper입니다. 로컬 CSV나 Parquet
파일 경로를 직접 넘길 수도 있습니다.

```r
# 관리형 Parquet를 명시적으로 사용
ps <- load_party_statements(format = "parquet")
cb <- load_campaign_booklet(format = "parquet")

# 또는 CSV를 명시적으로 사용
ps <- load_party_statements(format = "csv")
cb <- load_campaign_booklet(format = "csv")

# 두 데이터셋의 CSV cache를 미리 받아두기
download_data()

# 로컬 파일 경로를 직접 지정할 수도 있음
ps <- load_party_statements(path = "~/Downloads/sk_party_statements_v2022.csv")
ps <- load_party_statements(path = "~/Downloads/sk_party_statements_v2022.parquet")
```

데이터는 `tools::R_user_dir("krpoltext", "cache")`에 압축 RDS 형태로 캐시되며,
SHA-256 체크섬으로 검증됩니다. 이후 로딩은 대체로 약 2초 내외로 끝납니다.

## quanteda 연동

```r
library(quanteda)

corp <- as_quanteda_corpus(ps, docid_field = "id")
toks <- tokens(corp, remove_punct = TRUE)
dfm_obj <- dfm(toks)
topfeatures(dfm_obj, 20)
```

## 주요 함수

| 함수 | 설명 |
|------|------|
| `load_campaign_booklet()` | 선거공보 코퍼스 로드 |
| `load_party_statements()` | 정당 성명 코퍼스 로드 |
| `metadata()` | 데이터셋 메타데이터와 버전 확인 |
| `schema()` | 컬럼 단위 스키마와 아티팩트 메타데이터 확인 |
| `get_docs()` | 문서를 필터링하고 필요 컬럼만 선택 |
| `filter_docs()` | 메모리 데이터에 strict 필터 적용 |
| `select_vars()` | 메모리 데이터에서 컬럼 선택 |
| `as_quanteda_corpus()` | `quanteda` 코퍼스로 변환 |
| `download_data()` | OSF에서 데이터 다운로드 |
| `clear_cache()` | 캐시된 데이터 삭제 |

## 정적 데이터 API

데이터셋 metadata와 다운로드 링크는 GitHub Pages를 통해 정적 JSON API로도 제공됩니다.
별도의 서버가 필요하지 않습니다.

| 엔드포인트 | 설명 |
|------------|------|
| [`/data/index.json`](https://taehyun-lim.github.io/krpoltext/data/index.json) | 파일, 버전, SHA-256, 다운로드 URL이 담긴 리소스 인덱스 |
| [`/data/metadata.json`](https://taehyun-lim.github.io/krpoltext/data/metadata.json) | 데이터셋 설명과 인용 정보 |
| [`/data/schema/campaign_booklet.json`](https://taehyun-lim.github.io/krpoltext/data/schema/campaign_booklet.json) | 선거공보 컬럼 스키마 |
| [`/data/schema/party_statements.json`](https://taehyun-lim.github.io/krpoltext/data/schema/party_statements.json) | 정당 성명 컬럼 스키마 |

API 안내와 대체 URL:
<https://taehyun-lim.github.io/krpoltext/data-api.html>

GitHub Pages에서 일시적으로 `404`가 뜰 경우, 같은 리소스 인덱스를 아래 raw
URL에서도 받을 수 있습니다.
<https://raw.githubusercontent.com/taehyun-lim/krpoltext/gh-pages/data/index.json>

**R** 패키지 설치 없이 사용:

```r
api <- "https://taehyun-lim.github.io/krpoltext/data/metadata.json"
meta <- jsonlite::fromJSON(api)
url <- meta$party_statements$download_urls$csv
tmp <- tempfile(fileext = ".csv")
download.file(url, tmp, mode = "wb")
dt <- data.table::fread(tmp, encoding = "UTF-8")
```

**Python**:

```python
import requests, pandas as pd
meta = requests.get("https://taehyun-lim.github.io/krpoltext/data/metadata.json").json()
url = meta["party_statements"]["download_urls"]["csv"]
df = pd.read_csv(url)
```

함수 문서: <https://taehyun-lim.github.io/krpoltext/reference/index.html>

가이드와 예제: <https://taehyun-lim.github.io/krpoltext/articles/index.html>

## 인용

학술 작업에서 데이터를 사용할 경우, 먼저 Data Descriptor 논문을 인용해 주세요.

> Lim, T.H. (2025). South Korean Election Campaign Booklet and Party
> Statements Corpora. *Scientific Data*, 12, 1030.
> <https://doi.org/10.1038/s41597-025-05220-4>

그리고 데이터 저장소도 함께 인용하는 것을 권장합니다.

> Lim, T.H. (2024). South Korean Election Campaign Booklet Corpus and
> Party Statements Corpus. OSF.
> <https://doi.org/10.17605/OSF.IO/RCT9Y>

R 패키지 자체를 인용할 때는 다음 형식을 사용할 수 있습니다.

> Lim, T.H. (2026). *krpoltext: Korean Political Text Corpora for R*. R
> package version 0.2.0, <https://github.com/taehyun-lim/krpoltext>

현재 패키지 citation은 R에서 아래처럼 확인할 수도 있습니다.

```r
citation("krpoltext")
```

## 라이선스

- **패키지 코드**: [MIT License](LICENSE.md)
- **데이터**: [CC BY-NC-ND 4.0](LICENSE-DATA.md) — 자세한 조건은 [OSF 프로젝트](https://osf.io/rct9y/)와 [Data Descriptor](https://doi.org/10.1038/s41597-025-05220-4)를 참고하세요.

## 링크

- Data Descriptor: <https://doi.org/10.1038/s41597-025-05220-4>
- OSF 저장소: <https://osf.io/rct9y/>
- Zenodo 아카이브: <https://doi.org/10.5281/zenodo.18704319>
- 릴리스 노트: <https://github.com/taehyun-lim/krpoltext/blob/main/NEWS.md>
- GitHub Releases: <https://github.com/taehyun-lim/krpoltext/releases>
- GitHub: <https://github.com/taehyun-lim/krpoltext>
- Issues: <https://github.com/taehyun-lim/krpoltext/issues>

