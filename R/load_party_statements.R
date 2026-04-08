#' Load the South Korean Party Statements corpus
#'
#' Loads the party statements dataset (2003--2022) as a `data.table`. The
#' dataset contains 83,201 official statements from party spokespersons and
#' leadership meeting minutes from South Korea's two major political parties.
#'
#' For full methodology and variable descriptions, see the Data Descriptor:
#' Lim, T.H. (2025). *Scientific Data*, 12, 1030.
#' \doi{10.1038/s41597-025-05220-4}
#'
#' @param path Character; path to a local CSV or Parquet file. If `NULL`
#'   (default), a managed artifact is used. If a managed download would be
#'   required, it is only attempted in an interactive session.
#' @param format Character; requested storage format. Defaults to preferring
#'   `"parquet"` and falling back to `"csv"` when necessary.
#' @param cache Logical; if `TRUE` (default), the data is cached as an RDS file
#'   in the user's cache directory for faster subsequent loads.
#' @param refresh Logical; if `TRUE`, any existing cache is ignored and the
#'   source CSV is re-read. Defaults to `FALSE`.
#' @param data_version Character or `NULL`; the data artifact version to load.
#'   Defaults to the latest available version.
#'
#' @return A [data.table::data.table] with the following columns:
#'
#' | Column | Description |
#' |--------|-------------|
#' | `no` | Row number / identifier |
#' | `year` | Year of the statement |
#' | `ymd` | Full date (YYYY-MM-DD) |
#' | `title` | Title of the statement |
#' | `text` | Full text of the statement |
#' | `filtered` | Filtered/preprocessed text indicator |
#' | `partisan` | Party affiliation label |
#' | `conservative` | Conservative party indicator |
#' | `id` | Unique document identifier |
#'
#' See `data_dictionary.md` for the complete column reference, and
#' the Data Descriptor (Table 9) for yearly entry counts by party.
#'
#' @export
#' @examples
#' path <- tempfile(fileext = ".csv")
#' data.table::fwrite(
#'   data.table::data.table(
#'     year = 2020L,
#'     id = "ps-1",
#'     text = "statement text"
#'   ),
#'   path
#' )
#'
#' ps <- load_party_statements(path = path, cache = FALSE)
#' ps
load_party_statements <- function(path = NULL,
                                  format = c("parquet", "csv"),
                                  cache = TRUE,
                                  refresh = FALSE,
                                  data_version = NULL) {
  read_with_cache(
    dataset = "party_statements",
    path = path,
    cache = cache,
    refresh = refresh,
    format = format,
    data_version = data_version
  )
}
