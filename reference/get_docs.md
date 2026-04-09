# Query documents from a krpoltext corpus

Loads a dataset if needed, applies named filters, and optionally selects
a subset of columns.

## Usage

``` r
get_docs(
  dataset = c("campaign_booklet", "party_statements"),
  ...,
  .data = NULL,
  .select = NULL,
  .strict = FALSE
)
```

## Arguments

- dataset:

  Character; one of `"campaign_booklet"` or `"party_statements"`.

- ...:

  Named filtering arguments. Values can be scalars or vectors.

- .data:

  Optional pre-loaded data. If `NULL`, the requested dataset is loaded
  with the package defaults.

- .select:

  Optional character vector of columns to keep.

- .strict:

  Logical; if `TRUE`, invalid filter or selection columns raise an
  error. If `FALSE` (default), invalid names are ignored with a message.

## Value

A `data.table` subset of the requested corpus.

## Examples

``` r
dt <- data.table::data.table(
  year = c(2020L, 2021L),
  title = c("A", "B"),
  text = c("first", "second"),
  conservative = c(1L, 0L),
  id = c("ps-1", "ps-2")
)

get_docs("party_statements", year = 2020, .data = dt)
#>     year  title   text conservative     id
#>    <int> <char> <char>        <int> <char>
#> 1:  2020      A  first            1   ps-1
get_docs(
  "party_statements",
  conservative = 1,
  .select = c("year", "title"),
  .data = dt
)
#>     year  title
#>    <int> <char>
#> 1:  2020      A
```
