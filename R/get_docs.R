#' Query documents from a krpoltext corpus
#'
#' Filters rows from either the campaign booklet or party statements corpus
#' based on column values. Only filters on columns that actually exist in the
#' chosen dataset; unknown column names are silently ignored with a message.
#'
#' @param dataset Character; one of `"campaign_booklet"` or
#'   `"party_statements"`.
#' @param ... Named filtering arguments. Each name must correspond to a column
#'   in the dataset. Values can be:
#'   - A single value: exact match (e.g., `year = 2020`)
#'   - A vector: match any (e.g., `year = 2018:2022`)
#'   - For date/year ranges, supply a numeric or character vector.
#' @param .data Optional; a pre-loaded `data.table` to filter instead of
#'   loading from disk. Useful to avoid repeated I/O.
#'
#' @return A `data.table` subset of the requested corpus.
#'
#' @details
#' The function dynamically checks which columns exist in the data and applies
#' filters only for matching column names. If a filter name does not match any
#' column, it is ignored and a message is printed.
#'
#' For the **campaign_booklet** dataset, useful filter columns include:
#' `party`, `party_eng`, `office`, `region`, `district`, `date`, `sex`,
#' `result`, `name`.
#'
#' For the **party_statements** dataset, useful filter columns include:
#' `year`, `partisan`, `conservative`.
#'
#' @export
#' @examples
#' \dontrun{
#' # Get all party statements from 2020
#' docs_2020 <- get_docs("party_statements", year = 2020)
#'
#' # Get campaign booklets for a specific party
#' saenuri <- get_docs("campaign_booklet", party_eng = "Saenuri Party")
#'
#' # Combine multiple filters
#' subset <- get_docs("party_statements", year = 2018:2022, conservative = 1)
#'
#' # Filter a pre-loaded dataset
#' ps <- load_party_statements()
#' docs <- get_docs("party_statements", year = 2020, .data = ps)
#' }
get_docs <- function(dataset = c("campaign_booklet", "party_statements"),
                     ...,
                     .data = NULL) {
  dataset <- match.arg(dataset)
  filters <- list(...)

  if (is.null(.data)) {
    .data <- switch(dataset,
      campaign_booklet = load_campaign_booklet(),
      party_statements = load_party_statements()
    )
  }

  if (!inherits(.data, "data.table")) {
    .data <- data.table::as.data.table(.data)
  }

  if (length(filters) == 0L) return(.data)

  available_cols <- names(.data)
  used <- character()

  for (col_name in names(filters)) {
    if (col_name %in% available_cols) {
      vals <- filters[[col_name]]
      .data <- .data[get(col_name) %in% vals]
      used <- c(used, col_name)
    } else {
      message(
        "Filter '", col_name, "' ignored: column not found in '",
        dataset, "' dataset.\n",
        "Available columns: ", paste(available_cols, collapse = ", ")
      )
    }
  }

  .data
}
