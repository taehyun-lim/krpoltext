#' Query documents from a krpoltext corpus
#'
#' Loads a dataset if needed, applies named filters, and optionally selects a
#' subset of columns.
#'
#' @param dataset Character; one of `"campaign_booklet"` or
#'   `"party_statements"`.
#' @param ... Named filtering arguments. Values can be scalars or vectors.
#' @param .data Optional pre-loaded data. If `NULL`, the requested dataset is
#'   loaded with the package defaults.
#' @param .select Optional character vector of columns to keep.
#' @param .strict Logical; if `TRUE`, invalid filter or selection columns
#'   raise an error. If `FALSE` (default), invalid names are ignored with a
#'   message.
#'
#' @return A `data.table` subset of the requested corpus.
#' @export
#'
#' @examples
#' dt <- data.table::data.table(
#'   year = c(2020L, 2021L),
#'   title = c("A", "B"),
#'   text = c("first", "second"),
#'   conservative = c(1L, 0L),
#'   id = c("ps-1", "ps-2")
#' )
#'
#' get_docs("party_statements", year = 2020, .data = dt)
#' get_docs(
#'   "party_statements",
#'   conservative = 1,
#'   .select = c("year", "title"),
#'   .data = dt
#' )
get_docs <- function(dataset = c("campaign_booklet", "party_statements"),
                     ...,
                     .data = NULL,
                     .select = NULL,
                     .strict = FALSE) {
  dataset <- match.arg(dataset)
  filters <- list(...)

  if (is.null(.data)) {
    .data <- switch(dataset,
      campaign_booklet = load_campaign_booklet(),
      party_statements = load_party_statements()
    )
  }

  .data <- .as_krpoltext_table(.data)
  available_cols <- names(.data)
  expected_cols <- .dataset_columns(dataset)

  if (length(filters) > 0L) {
    .validate_named_filters(filters)
    .validate_requested_columns(
      requested = names(filters),
      available = available_cols,
      expected = expected_cols,
      context = "filter",
      strict = .strict
    )
    .data <- .apply_filters(.data, filters[names(filters) %in% available_cols])
  }

  if (!is.null(.select)) {
    .data <- .select_vars_impl(
      .data = .data,
      vars = .select,
      .strict = .strict,
      .expected = expected_cols
    )
  }

  .data
}

#' Filter an in-memory table using named column filters
#'
#' @param .data A data frame or `data.table`.
#' @param ... Named filtering arguments. Values can be scalars or vectors.
#' @param .strict Logical; if `TRUE` (default), invalid filter columns raise an
#'   error. If `FALSE`, they are ignored with a message.
#'
#' @return A filtered `data.table`.
#' @export
#'
#' @examples
#' dt <- data.table::data.table(year = 2020:2022, text = letters[1:3])
#' filter_docs(dt, year = 2021)
filter_docs <- function(.data, ..., .strict = TRUE) {
  filters <- list(...)
  .data <- .as_krpoltext_table(.data)

  if (length(filters) == 0L) {
    return(.data)
  }

  .validate_named_filters(filters)
  .validate_requested_columns(
    requested = names(filters),
    available = names(.data),
    expected = names(.data),
    context = "filter",
    strict = .strict
  )

  .apply_filters(.data, filters[names(filters) %in% names(.data)])
}

#' Select columns from an in-memory table
#'
#' @param .data A data frame or `data.table`.
#' @param vars Character vector of columns to keep.
#' @param .strict Logical; if `TRUE` (default), invalid selection columns raise
#'   an error. If `FALSE`, they are ignored with a message.
#'
#' @return A `data.table` containing only the requested columns.
#' @export
#'
#' @examples
#' dt <- data.table::data.table(year = 2020:2022, text = letters[1:3])
#' select_vars(dt, c("year", "text"))
select_vars <- function(.data, vars, .strict = TRUE) {
  .select_vars_impl(.data = .data, vars = vars, .strict = .strict)
}

#' Select columns implementation
#' @noRd
.select_vars_impl <- function(.data, vars, .strict = TRUE, .expected = NULL) {
  .data <- .as_krpoltext_table(.data)

  if (is.null(vars)) {
    return(.data)
  }

  if (!is.character(vars)) {
    stop("`vars` must be a character vector.", call. = FALSE)
  }

  vars <- unique(vars[!is.na(vars)])
  available <- names(.data)
  expected <- if (is.null(.expected)) available else .expected

  .validate_requested_columns(
    requested = vars,
    available = available,
    expected = expected,
    context = "selection",
    strict = .strict
  )

  vars <- vars[vars %in% available]
  data.table::as.data.table(.data[, vars, drop = FALSE])
}

#' Ensure table input is a data.table
#' @noRd
.as_krpoltext_table <- function(.data) {
  if (!inherits(.data, "data.table")) {
    return(data.table::as.data.table(.data))
  }

  .data
}

#' Validate filter names
#' @noRd
.validate_named_filters <- function(filters) {
  nm <- names(filters)
  if (is.null(nm) || any(!nzchar(nm))) {
    stop("All filters supplied to `...` must be named.", call. = FALSE)
  }
}

#' Handle invalid column names
#' @noRd
.validate_requested_columns <- function(requested,
                                        available,
                                        expected,
                                        context = c("filter", "selection"),
                                        strict = TRUE) {
  context <- match.arg(context)
  requested <- unique(requested)
  available <- unique(available)
  expected <- unique(expected)
  invalid <- setdiff(requested, available)

  if (length(invalid) == 0L) {
    return(invisible(NULL))
  }

  label <- switch(
    context,
    filter = if (length(invalid) == 1L) "filter" else "filters",
    selection = if (length(invalid) == 1L) "selected column" else "selected columns"
  )
  message_text <- paste0(
    "Unknown ", label, ": ", paste(invalid, collapse = ", "), ". ",
    "Available columns: ", paste(available, collapse = ", ")
  )

  expected_only <- setdiff(invalid, expected)
  if (length(expected_only) > 0L) {
    message_text <- paste0(
      message_text,
      ". Also not defined in the canonical schema: ",
      paste(expected_only, collapse = ", ")
    )
  }

  if (isTRUE(strict)) {
    stop(message_text, call. = FALSE)
  }

  message(message_text)
  invisible(NULL)
}

#' Apply named filters
#' @noRd
.apply_filters <- function(.data, filters) {
  if (length(filters) == 0L) {
    return(.data)
  }

  for (col_name in names(filters)) {
    values <- filters[[col_name]]
    .data <- .data[.data[[col_name]] %in% values, ]
  }

  .data
}
