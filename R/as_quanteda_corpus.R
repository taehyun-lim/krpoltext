#' Convert a krpoltext data.table to a quanteda corpus
#'
#' Creates a [quanteda::corpus()] object from a `data.table` loaded by
#' [load_campaign_booklet()] or [load_party_statements()]. The `text` column
#' is used as the document text; all other columns become document-level
#' variables (docvars).
#'
#' @param x A `data.table` (or `data.frame`) with at least a `text` column.
#' @param text_field Character; name of the column containing document text.
#'   Defaults to `"text"`.
#' @param docid_field Character or `NULL`; name of the column to use as
#'   document IDs. If `NULL`, row numbers are used.
#' @param ... Additional arguments passed to [quanteda::corpus()].
#'
#' @return A `quanteda` corpus object.
#'
#' @export
#' @examples
#' \dontrun{
#' ps <- load_party_statements()
#' corp <- as_quanteda_corpus(ps)
#'
#' # Use a subset
#' ps_2020 <- get_docs("party_statements", year = 2020)
#' corp_2020 <- as_quanteda_corpus(ps_2020, docid_field = "id")
#' }
as_quanteda_corpus <- function(x,
                               text_field = "text",
                               docid_field = NULL,
                               ...) {
  if (!requireNamespace("quanteda", quietly = TRUE)) {
    stop(
      "Package 'quanteda' is required for as_quanteda_corpus().\n",
      "Install it with: install.packages(\"quanteda\")",
      call. = FALSE
    )
  }

  if (!is.data.frame(x)) {
    stop("`x` must be a data.frame or data.table.", call. = FALSE)
  }

  if (!text_field %in% names(x)) {
    stop(
      "Column '", text_field, "' not found in the data.\n",
      "Available columns: ", paste(names(x), collapse = ", "),
      call. = FALSE
    )
  }

  df <- as.data.frame(x)

  args <- list(x = df, text_field = text_field, ...)
  if (!is.null(docid_field)) {
    if (!docid_field %in% names(df)) {
      stop("docid_field '", docid_field, "' not found in the data.", call. = FALSE)
    }
    args$docid_field <- docid_field
  }

  do.call(quanteda::corpus, args)
}
