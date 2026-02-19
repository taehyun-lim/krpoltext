# Query documents from a krpoltext corpus

Filters rows from either the campaign booklet or party statements corpus
based on column values. Only filters on columns that actually exist in
the chosen dataset; unknown column names are silently ignored with a
message.

## Usage

``` r
get_docs(
  dataset = c("campaign_booklet", "party_statements"),
  ...,
  .data = NULL
)
```

## Arguments

- dataset:

  Character; one of `"campaign_booklet"` or `"party_statements"`.

- ...:

  Named filtering arguments. Each name must correspond to a column in
  the dataset. Values can be:

  - A single value: exact match (e.g., `year = 2020`)

  - A vector: match any (e.g., `year = 2018:2022`)

  - For date/year ranges, supply a numeric or character vector.

- .data:

  Optional; a pre-loaded `data.table` to filter instead of loading from
  disk. Useful to avoid repeated I/O.

## Value

A `data.table` subset of the requested corpus.

## Details

The function dynamically checks which columns exist in the data and
applies filters only for matching column names. If a filter name does
not match any column, it is ignored and a message is printed.

For the **campaign_booklet** dataset, useful filter columns include:
`party`, `party_eng`, `office`, `region`, `district`, `date`, `sex`,
`result`, `name`.

For the **party_statements** dataset, useful filter columns include:
`year`, `partisan`, `conservative`.

## Examples

``` r
if (FALSE) { # \dontrun{
# Get all party statements from 2020
docs_2020 <- get_docs("party_statements", year = 2020)

# Get campaign booklets for a specific party
saenuri <- get_docs("campaign_booklet", party_eng = "Saenuri Party")

# Combine multiple filters
subset <- get_docs("party_statements", year = 2018:2022, conservative = 1)

# Filter a pre-loaded dataset
ps <- load_party_statements()
docs <- get_docs("party_statements", year = 2020, .data = ps)
} # }
```
