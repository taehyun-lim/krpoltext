# krpoltext

English \|
[한국어](https://taehyun-lim.github.io/krpoltext/README_kr.html)

**krpoltext** provides convenient R access to two large-scale Korean
political text corpora described in:

> Lim, T.H. (2025). South Korean Election Campaign Booklet and Party
> Statements Corpora. *Scientific Data*, 12, 1030.
> <https://doi.org/10.1038/s41597-025-05220-4>

| Corpus                         | Period    | Candidates / Entries | Description                                                                                |
|--------------------------------|-----------|----------------------|--------------------------------------------------------------------------------------------|
| **Election Campaign Booklets** | 2000–2022 | 49,678 candidates    | Manifesto booklets from candidates in presidential, National Assembly, and local elections |
| **Party Statements**           | 2003–2022 | 83,201 statements    | Official statements and leadership meeting minutes from the two major parties              |

Data is hosted on the [Open Science Framework](https://osf.io/rct9y/)
(DOI: [10.17605/OSF.IO/RCT9Y](https://doi.org/10.17605/OSF.IO/RCT9Y)).
If a managed artifact is needed, it is downloaded automatically on first
use in interactive sessions; non-interactive sessions should use a local
file path or a pre-populated cache.

## Release Notes

Recent package changes are summarized in:

- [NEWS.md](https://taehyun-lim.github.io/krpoltext/NEWS.md)
- GitHub Releases: <https://github.com/taehyun-lim/krpoltext/releases>

## Installation

``` r
# install.packages("remotes")
remotes::install_github("taehyun-lim/krpoltext")
```

## Quick Start

``` r
library(krpoltext)

# Load datasets from managed Parquet artifacts when available
ps <- load_party_statements(format = "parquet")
cb <- load_campaign_booklet(format = "parquet")

# Explore metadata
metadata("party_statements")
schema("party_statements")

# Filter documents
docs_2020 <- get_docs("party_statements", year = 2020)
conservative <- get_docs("party_statements", year = 2018:2022, conservative = 1)
strict_subset <- get_docs(
  "party_statements",
  year = 2020,
  .select = c("year", "title", "text"),
  .strict = TRUE
)

# Campaign booklets: filter by office and party
assembly <- get_docs("campaign_booklet", office = "national_assembly", .data = cb)
```

## Data Download

Managed artifacts are available from OSF in both CSV and Parquet
formats. The `load_*()` helpers can use managed Parquet artifacts, while
[`download_data()`](https://taehyun-lim.github.io/krpoltext/reference/download_data.md)
remains a CSV-prefetch helper. You can also point the loaders at local
CSV or Parquet files:

``` r
# Use managed Parquet explicitly (also the default preference)
ps <- load_party_statements(format = "parquet")
cb <- load_campaign_booklet(format = "parquet")

# Or use CSV explicitly
ps <- load_party_statements(format = "csv")
cb <- load_campaign_booklet(format = "csv")

# Prefetch CSV caches for both datasets
download_data()

# Provide a local file path instead
ps <- load_party_statements(path = "~/Downloads/sk_party_statements_v2022.csv")
ps <- load_party_statements(path = "~/Downloads/sk_party_statements_v2022.parquet")
```

Data is cached as compressed RDS in
`tools::R_user_dir("krpoltext", "cache")` and verified via SHA-256
checksums. Subsequent loads take ~2 seconds.

## Integration with quanteda

``` r
library(quanteda)

corp <- as_quanteda_corpus(ps, docid_field = "id")
toks <- tokens(corp, remove_punct = TRUE)
dfm_obj <- dfm(toks)
topfeatures(dfm_obj, 20)
```

## Functions

| Function                                                                                                | Description                                    |
|---------------------------------------------------------------------------------------------------------|------------------------------------------------|
| [`load_campaign_booklet()`](https://taehyun-lim.github.io/krpoltext/reference/load_campaign_booklet.md) | Load the campaign booklet corpus               |
| [`load_party_statements()`](https://taehyun-lim.github.io/krpoltext/reference/load_party_statements.md) | Load the party statements corpus               |
| [`metadata()`](https://taehyun-lim.github.io/krpoltext/reference/metadata.md)                           | Dataset metadata (columns, versions, citation) |
| [`schema()`](https://taehyun-lim.github.io/krpoltext/reference/schema.md)                               | Column-level schema and artifact metadata      |
| [`get_docs()`](https://taehyun-lim.github.io/krpoltext/reference/get_docs.md)                           | Filter documents and optionally select columns |
| [`filter_docs()`](https://taehyun-lim.github.io/krpoltext/reference/filter_docs.md)                     | Apply strict filters to an in-memory table     |
| [`select_vars()`](https://taehyun-lim.github.io/krpoltext/reference/select_vars.md)                     | Select columns from an in-memory table         |
| [`as_quanteda_corpus()`](https://taehyun-lim.github.io/krpoltext/reference/as_quanteda_corpus.md)       | Convert to a quanteda corpus object            |
| [`download_data()`](https://taehyun-lim.github.io/krpoltext/reference/download_data.md)                 | Download datasets from OSF                     |
| [`clear_cache()`](https://taehyun-lim.github.io/krpoltext/reference/clear_cache.md)                     | Remove cached data files                       |

## Static Data API

Dataset metadata and download links are available as a static JSON API
via GitHub Pages, with no server required:

| Endpoint                                                                                                          | Description                                              |
|-------------------------------------------------------------------------------------------------------------------|----------------------------------------------------------|
| [`/data/index.json`](https://taehyun-lim.github.io/krpoltext/data/index.json)                                     | Resource index (files, versions, SHA-256, download URLs) |
| [`/data/metadata.json`](https://taehyun-lim.github.io/krpoltext/data/metadata.json)                               | Dataset descriptions and citation info                   |
| [`/data/schema/campaign_booklet.json`](https://taehyun-lim.github.io/krpoltext/data/schema/campaign_booklet.json) | Column schema for campaign booklets                      |
| [`/data/schema/party_statements.json`](https://taehyun-lim.github.io/krpoltext/data/schema/party_statements.json) | Column schema for party statements                       |

API overview and fallback URLs:
<https://taehyun-lim.github.io/krpoltext/data-api.html>

If GitHub Pages temporarily returns `404`, the same resource index is
also available here:
<https://raw.githubusercontent.com/taehyun-lim/krpoltext/gh-pages/data/index.json>

**R** (without installing the package):

``` r
api <- "https://taehyun-lim.github.io/krpoltext/data/metadata.json"
meta <- jsonlite::fromJSON(api)
url <- meta$party_statements$download_urls$csv
tmp <- tempfile(fileext = ".csv")
download.file(url, tmp, mode = "wb")
dt <- data.table::fread(tmp, encoding = "UTF-8")
```

**Python**:

``` python
import requests, pandas as pd
meta = requests.get("https://taehyun-lim.github.io/krpoltext/data/metadata.json").json()
url = meta["party_statements"]["download_urls"]["csv"]
df = pd.read_csv(url)
```

Function reference:
<https://taehyun-lim.github.io/krpoltext/reference/index.html>

Guides and examples:
<https://taehyun-lim.github.io/krpoltext/articles/index.html>

## Citation

If you use this data in academic work, please cite the Data Descriptor
paper:

> Lim, T.H. (2025). South Korean Election Campaign Booklet and Party
> Statements Corpora. *Scientific Data*, 12, 1030.
> <https://doi.org/10.1038/s41597-025-05220-4>

And the data repository:

> Lim, T.H. (2024). South Korean Election Campaign Booklet Corpus and
> Party Statements Corpus. OSF. <https://doi.org/10.17605/OSF.IO/RCT9Y>

For the R package itself, cite:

> Lim, T.H. (2026). *krpoltext: Korean Political Text Corpora for R*. R
> package version 0.2.0. Zenodo.
> <https://doi.org/10.5281/zenodo.18704318>

You can also retrieve the current package citation in R:

``` r
citation("krpoltext")
```

## License

- **Package code**: [MIT
  License](https://taehyun-lim.github.io/krpoltext/LICENSE.md)
- **Data**: [CC BY-NC-ND
  4.0](https://taehyun-lim.github.io/krpoltext/LICENSE-DATA.md) — see
  the [OSF project](https://osf.io/rct9y/) and the [Data
  Descriptor](https://doi.org/10.1038/s41597-025-05220-4) for full
  terms.

## Links

- Data Descriptor: <https://doi.org/10.1038/s41597-025-05220-4>
- OSF Repository: <https://osf.io/rct9y/>
- Zenodo Concept DOI: <https://doi.org/10.5281/zenodo.18704318>
- Release Notes:
  <https://github.com/taehyun-lim/krpoltext/blob/main/NEWS.md>
- GitHub Releases: <https://github.com/taehyun-lim/krpoltext/releases>
- GitHub: <https://github.com/taehyun-lim/krpoltext>
- Issues: <https://github.com/taehyun-lim/krpoltext/issues>
