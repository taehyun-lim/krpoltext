# Load the South Korean Party Statements corpus

Loads the party statements dataset (2003–2022) as a `data.table`. The
dataset contains 83,201 official statements from party spokespersons and
leadership meeting minutes from South Korea's two major political
parties.

## Usage

``` r
load_party_statements(
  path = NULL,
  format = c("parquet", "csv"),
  cache = TRUE,
  refresh = FALSE,
  data_version = NULL
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

## Value

A
[data.table::data.table](https://rdrr.io/pkg/data.table/man/data.table.html)
with the following columns:

|                |                                      |
|----------------|--------------------------------------|
| Column         | Description                          |
| `no`           | Row number / identifier              |
| `year`         | Year of the statement                |
| `ymd`          | Full date (YYYY-MM-DD)               |
| `title`        | Title of the statement               |
| `text`         | Full text of the statement           |
| `filtered`     | Filtered/preprocessed text indicator |
| `partisan`     | Party affiliation label              |
| `conservative` | Conservative party indicator         |
| `id`           | Unique document identifier           |

See `data_dictionary.md` for the complete column reference, and the Data
Descriptor (Table 9) for yearly entry counts by party.

## Details

For full methodology and variable descriptions, see the Data Descriptor:
Lim, T.H. (2025). *Scientific Data*, 12, 1030.
[doi:10.1038/s41597-025-05220-4](https://doi.org/10.1038/s41597-025-05220-4)

## Examples

``` r
path <- tempfile(fileext = ".csv")
data.table::fwrite(
  data.table::data.table(
    year = 2020L,
    id = "ps-1",
    text = "statement text"
  ),
  path
)

ps <- load_party_statements(path = path, cache = FALSE)
#> Local file extension suggests format 'csv'; using that instead of requested 'parquet'.
ps
#>     year     id           text
#>    <int> <char>         <char>
#> 1:  2020   ps-1 statement text
```
