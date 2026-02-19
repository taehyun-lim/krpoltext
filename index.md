# krpoltext

**krpoltext** provides convenient R access to two large-scale Korean
political text corpora described in:

> Lim, T.H. (2025). South Korean Election Campaign Booklet and Party
> Statements Corpora. *Scientific Data*, 12, 1030.
> <https://doi.org/10.1038/s41597-025-05220-4>

| Corpus                         | Period    | Candidates / Entries | Description                                                                                |
|--------------------------------|-----------|----------------------|--------------------------------------------------------------------------------------------|
| **Election Campaign Booklets** | 2000–2022 | 49,678 candidates    | Manifesto booklets from candidates in presidential, National Assembly, and local elections |
| **Party Statements**           | 2003–2022 | 82,723 statements    | Official statements and leadership meeting minutes from the two major parties              |

Data is hosted on the [Open Science Framework](https://osf.io/rct9y/)
(DOI: [10.17605/OSF.IO/RCT9Y](https://doi.org/10.17605/OSF.IO/RCT9Y))
and **automatically downloaded** on first use.

## Installation

``` r
# install.packages("remotes")
remotes::install_github("taehyun-lim/krpoltext")
```

## Quick Start

``` r
library(krpoltext)

# Load a dataset (auto-downloads from OSF on first use, then cached)
ps <- load_party_statements()
cb <- load_campaign_booklet()

# Explore metadata
metadata("party_statements")

# Filter documents
docs_2020 <- get_docs("party_statements", year = 2020)
conservative <- get_docs("party_statements", year = 2018:2022, conservative = 1)

# Campaign booklets: filter by office and party
assembly <- get_docs("campaign_booklet", office = "national_assembly", .data = cb)
```

## Data Download

The CSV files (~1.5 GB total) are downloaded from OSF on first load:

``` r
# Auto-download: asks for consent interactively
ps <- load_party_statements()

# Or download all datasets at once
download_data()

# Provide a local file path instead
ps <- load_party_statements(path = "~/Downloads/sk_party_statements_v2022.csv")
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

| Function                                                                                                | Description                                  |
|---------------------------------------------------------------------------------------------------------|----------------------------------------------|
| [`load_campaign_booklet()`](https://taehyun-lim.github.io/krpoltext/reference/load_campaign_booklet.md) | Load the campaign booklet corpus             |
| [`load_party_statements()`](https://taehyun-lim.github.io/krpoltext/reference/load_party_statements.md) | Load the party statements corpus             |
| [`metadata()`](https://taehyun-lim.github.io/krpoltext/reference/metadata.md)                           | Dataset metadata (columns, counts, citation) |
| [`get_docs()`](https://taehyun-lim.github.io/krpoltext/reference/get_docs.md)                           | Filter documents by any column               |
| [`as_quanteda_corpus()`](https://taehyun-lim.github.io/krpoltext/reference/as_quanteda_corpus.md)       | Convert to a quanteda corpus object          |
| [`download_data()`](https://taehyun-lim.github.io/krpoltext/reference/download_data.md)                 | Download datasets from OSF                   |
| [`clear_cache()`](https://taehyun-lim.github.io/krpoltext/reference/clear_cache.md)                     | Remove cached data files                     |

## Citation

If you use this data in academic work, please cite the Data Descriptor
paper:

> Lim, T.H. (2025). South Korean Election Campaign Booklet and Party
> Statements Corpora. *Scientific Data*, 12, 1030.
> <https://doi.org/10.1038/s41597-025-05220-4>

And the data repository:

> Lim, T.H. (2024). South Korean Election Campaign Booklet Corpus and
> Party Statements Corpus. OSF. <https://doi.org/10.17605/OSF.IO/RCT9Y>

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
- GitHub: <https://github.com/taehyun-lim/krpoltext>
- Issues: <https://github.com/taehyun-lim/krpoltext/issues>
