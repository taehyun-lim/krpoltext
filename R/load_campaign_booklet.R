#' Load the South Korean Election Campaign Booklet corpus
#'
#' Loads the election campaign booklet dataset (2000--2022) as a `data.table`.
#' The dataset contains manifesto booklets from 49,678 individual candidates
#' across presidential, National Assembly, and local elections.
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
#' | `date` | Election date |
#' | `name` | Candidate name |
#' | `region` | Region (province/metropolitan city) |
#' | `district` | Electoral district |
#' | `office_id` | Office type identifier |
#' | `office` | Office type (e.g., `national_assembly`) |
#' | `party` | Party name (Korean) |
#' | `party_eng` | Party name (English) |
#' | `result` | Election result |
#' | `sex` | Sex of the candidate |
#' | `age` | Age at the time of election |
#' | `text` | Full text of the campaign booklet |
#' | `filtered` | Filtered/preprocessed text indicator |
#'
#' See `data_dictionary.md` for the complete column reference, and
#' the Data Descriptor (Tables 4--8) for detailed variable mappings.
#'
#' @export
#' @examples
#' \dontrun{
#' # Load with default caching
#' cb <- load_campaign_booklet()
#'
#' # Load from a specific file
#' cb <- load_campaign_booklet(path = "path/to/my_data.csv")
#'
#' # Force refresh the cache
#' cb <- load_campaign_booklet(refresh = TRUE)
#' }
load_campaign_booklet <- function(path = NULL, cache = TRUE, refresh = FALSE) {
  stopifnot(is.logical(cache), length(cache) == 1L)
  stopifnot(is.logical(refresh), length(refresh) == 1L)
  if (!is.null(path) && !is.character(path)) {
    stop("`path` must be NULL or a character string.", call. = FALSE)
  }

  read_with_cache(
    csv_filename = "sk_election_campaign_booklet_v2022.csv",
    path = path,
    cache = cache,
    refresh = refresh
  )
}
