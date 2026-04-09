# Load the South Korean Election Campaign Booklet corpus

Loads the election campaign booklet dataset (2000–2022) as a
`data.table`. The dataset contains manifesto booklets from 49,678
individual candidates across presidential, National Assembly, and local
elections.

## Usage

``` r
load_campaign_booklet(
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

|             |                                         |
|-------------|-----------------------------------------|
| Column      | Description                             |
| `date`      | Election date                           |
| `name`      | Candidate name                          |
| `region`    | Region (province/metropolitan city)     |
| `district`  | Electoral district                      |
| `office_id` | Office type identifier                  |
| `office`    | Office type (e.g., `national_assembly`) |
| `party`     | Party name (Korean)                     |
| `party_eng` | Party name (English)                    |
| `result`    | Election result                         |
| `sex`       | Sex of the candidate                    |
| `age`       | Age at the time of election             |
| `text`      | Full text of the campaign booklet       |
| `filtered`  | Filtered/preprocessed text indicator    |

See `data_dictionary.md` for the complete column reference, and the Data
Descriptor (Tables 4–8) for detailed variable mappings.

## Details

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
