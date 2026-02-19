# Quick Start: 5-Minute Guide to krpoltext

The **krpoltext** package provides access to two Korean political text
corpora described in:

> Lim, T.H. (2025). South Korean Election Campaign Booklet and Party
> Statements Corpora. *Scientific Data*, 12, 1030.
> <https://doi.org/10.1038/s41597-025-05220-4>

## Installation

``` r
# install.packages("remotes")
remotes::install_github("taehyun-lim/krpoltext")
```

## Load a Dataset

Data is automatically downloaded from [OSF](https://osf.io/rct9y/) on
first use and cached locally as RDS.

``` r
library(krpoltext)

# Load the party statements corpus (~741 MB download on first use)
ps <- load_party_statements()
ps
```

## Explore Metadata

``` r
meta <- metadata("party_statements")
meta$name
meta$time_coverage
meta$n_candidates_or_entries
meta$columns
```

## Filter Documents

[`get_docs()`](https://taehyun-lim.github.io/krpoltext/reference/get_docs.md)
dynamically filters on any column that exists in the dataset.

``` r
# Statements from 2020
docs_2020 <- get_docs("party_statements", year = 2020, .data = ps)
nrow(docs_2020)

# Conservative party statements from 2018-2022
conservative_recent <- get_docs(
  "party_statements",
  year = 2018:2022,
  conservative = 1,
  .data = ps
)
nrow(conservative_recent)
```

## Quick Summary

``` r
table(ps$year)
table(ps$partisan)
```

## Campaign Booklets

``` r
cb <- load_campaign_booklet()

# National Assembly candidates only
assembly <- get_docs("campaign_booklet", office = "national_assembly", .data = cb)
nrow(assembly)

# Filter by party
table(assembly$party_eng)
```

## Next Steps

- See
  [`vignette("replication-pipeline")`](https://taehyun-lim.github.io/krpoltext/articles/replication-pipeline.md)
  for a full text analysis workflow with **quanteda**.
- See the [Data Descriptor](https://doi.org/10.1038/s41597-025-05220-4)
  for variable definitions, technical validation, and example use cases.
