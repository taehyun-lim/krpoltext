# Load the South Korean Election Campaign Booklet corpus

Loads the election campaign booklet dataset (2000–2022) as a
`data.table`. `campaign_booklet` is available in two public variants:

## Usage

``` r
load_campaign_booklet(
  path = NULL,
  format = c("parquet", "csv"),
  cache = TRUE,
  refresh = FALSE,
  data_version = NULL,
  variant = NULL
)
```

## Arguments

- path:

  Character; path to a local CSV or Parquet file. If `NULL` (default), a
  managed artifact is used. If a managed download would be required, it
  is only attempted in an interactive session.

- format:

  Character; requested storage format. Defaults to preferring
  `"parquet"` and falling back to `"csv"` when necessary.

- cache:

  Logical; if `TRUE` (default), the data is cached as an RDS file in the
  user's cache directory for faster subsequent loads.

- refresh:

  Logical; if `TRUE`, any existing cache is ignored and the source CSV
  is re-read. Defaults to `FALSE`.

- data_version:

  Character or `NULL`; the data artifact version to load. Defaults to
  the latest available version.

- variant:

  Character or `NULL`; which public `campaign_booklet` variant to load.
  Defaults to `"original"`. Use `"enriched"` to load the NEC-linked
  variant.

## Value

A
[data.table::data.table](https://rdrr.io/pkg/data.table/man/data.table.html).

See `data_dictionary.md` for the complete column reference. `original`
returns the historical corpus fields only. `enriched` keeps the same
document-row universe and adds conservative NEC linkage metadata.
Because some original rows have missing `code` values, row identity
should not be inferred from `code` alone.

## Details

- `original`: the original krpoltext corpus artifact

- `enriched`: the same document-row universe plus conservative NEC
  linkage fields such as `huboid`, `sg_id`, `sg_typecode`,
  `link_status`, `matcher_version`, and `nec_snapshot_id`

The default is `variant = "original"`. Use `variant = "enriched"` for
NEC-aligned workflows such as `kr-elections-mcp`.

For full methodology and variable descriptions, see the Data Descriptor:
Lim, T.H. (2025). *Scientific Data*, 12, 1030.
[doi:10.1038/s41597-025-05220-4](https://doi.org/10.1038/s41597-025-05220-4)

## Examples

``` r
path <- tempfile(fileext = ".csv")
data.table::fwrite(
  data.table::data.table(
    date = "2020-04-15",
    party = "Example Party",
    text = "campaign text"
  ),
  path
)

cb <- load_campaign_booklet(path = path, cache = FALSE)
#> Local file extension suggests format 'csv'; using that instead of requested 'parquet'.
cb
#>          date         party          text
#>        <IDat>        <char>        <char>
#> 1: 2020-04-15 Example Party campaign text
```
