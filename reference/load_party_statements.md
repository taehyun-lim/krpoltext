# Load the South Korean Party Statements corpus

Loads the party statements dataset (2003–2022) as a `data.table`. The
dataset contains 82,723 official statements from party spokespersons and
leadership meeting minutes from South Korea's two major political
parties.

## Usage

``` r
load_party_statements(path = NULL, cache = TRUE, refresh = FALSE)
```

## Arguments

- path:

  Character; path to a local CSV file. If `NULL` (default), the bundled
  dataset is used.

- cache:

  Logical; if `TRUE` (default), the data is cached as an RDS file in the
  user's cache directory for faster subsequent loads.

- refresh:

  Logical; if `TRUE`, any existing cache is ignored and the source CSV
  is re-read. Defaults to `FALSE`.

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
if (FALSE) { # \dontrun{
# Load with default caching
ps <- load_party_statements()

# Force refresh
ps <- load_party_statements(refresh = TRUE)
} # }
```
