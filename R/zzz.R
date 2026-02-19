#' krpoltext: Korean Political Text Corpora for Reproducible Research
#'
#' Provides easy access to two large-scale Korean political text corpora:
#' the South Korean Election Campaign Booklet Corpus (49,678 candidates,
#' 2000-2022) and the South Korean Party Statements Corpus (82,723
#' statements, 2003-2022).
#'
#' @section Data Descriptor:
#' Lim, T.H. (2025). South Korean Election Campaign Booklet and Party
#' Statements Corpora. *Scientific Data*, 12, 1030.
#' \doi{10.1038/s41597-025-05220-4}
#'
#' @section Data Repository:
#' \url{https://osf.io/rct9y/} (DOI: 10.17605/OSF.IO/RCT9Y)
#'
#' @docType package
#' @name krpoltext-package
#' @keywords internal
"_PACKAGE"

.krpoltext_env <- new.env(parent = emptyenv())

.onLoad <- function(libname, pkgname) {
  .krpoltext_env$cache_dir <- tools::R_user_dir("krpoltext", which = "cache")
  .krpoltext_env$data_loaded <- list()
  invisible()
}
