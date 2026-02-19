# Download krpoltext datasets from OSF

Downloads the CSV data files from the OSF repository and caches them
locally as RDS files for fast subsequent loading. On first use the
function asks for interactive consent before starting the download.

## Usage

``` r
download_data(dataset = "all", force = FALSE, quiet = FALSE)
```

## Arguments

- dataset:

  Character vector of datasets to download. Valid values are
  `"campaign_booklet"`, `"party_statements"`, or `"all"` (default).

- force:

  Logical; if `TRUE`, re-download even if cached files exist. Defaults
  to `FALSE`.

- quiet:

  Logical; if `TRUE`, suppress progress messages. Defaults to `FALSE`.

## Value

Invisibly, a character vector of paths to the cached RDS files.

## Details

Downloaded CSV files are read with
[`data.table::fread()`](https://rdrr.io/pkg/data.table/man/fread.html),
then saved as compressed RDS in the user's cache directory
(`tools::R_user_dir("krpoltext", "cache")`). The original CSV is not
kept on disk; only the RDS cache is stored.

File integrity is verified via SHA-256 checksums published with the OSF
release.

## Examples

``` r
if (FALSE) { # \dontrun{
# Download everything (asks for consent interactively)
download_data()

# Download only party statements
download_data("party_statements")

# Force re-download
download_data("all", force = TRUE)
} # }
```
