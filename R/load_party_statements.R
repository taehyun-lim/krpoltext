#' Load the South Korean Party Statements corpus
#'
#' Loads the party statements dataset (2003--2022) as a `data.table`. The
#' dataset contains 82,723 official statements from party spokespersons and
#' leadership meeting minutes from South Korea's two major political parties.
#'
#' For full methodology and variable descriptions, see the Data Descriptor:
#' Lim, T.H. (2025). *Scientific Data*, 12, 1030.
#' \doi{10.1038/s41597-025-05220-4}
#'
#' @param path Character; path to a local CSV file. If `NULL` (default), the
#'   bundled dataset is used.
#' @param cache Logical; if `TRUE` (default), the data is cached as an RDS file
#'   in the user's cache directory for faster subsequent loads.
#' @param refresh Logical; if `TRUE`, any existing cache is ignored and the
#'   source CSV is re-read. Defaults to `FALSE`.
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
#' \dontrun{
#' # Load with default caching
#' ps <- load_party_statements()
#'
#' # Force refresh
#' ps <- load_party_statements(refresh = TRUE)
#' }
load_party_statements <- function(path = NULL, cache = TRUE, refresh = FALSE) {
  stopifnot(is.logical(cache), length(cache) == 1L)
  stopifnot(is.logical(refresh), length(refresh) == 1L)
  if (!is.null(path) && !is.character(path)) {
    stop("`path` must be NULL or a character string.", call. = FALSE)
  }

  read_with_cache(
    csv_filename = "sk_party_statements_v2022.csv",
    path = path,
    cache = cache,
    refresh = refresh
  )
}
