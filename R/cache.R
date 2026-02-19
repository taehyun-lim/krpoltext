#' Get the cache directory path
#'
#' Returns the path to the krpoltext cache directory. Creates it if it does not
#' exist.
#'
#' @return A character string with the cache directory path.
#' @noRd
cache_dir <- function() {
  d <- .krpoltext_env$cache_dir
  if (!dir.exists(d)) dir.create(d, recursive = TRUE, showWarnings = FALSE)
  d
}

#' Build cache file path for a dataset
#' @param dataset_name Base name of the CSV file (without extension).
#' @return Full path to the cached RDS file.
#' @noRd
cache_path <- function(dataset_name) {
  file.path(cache_dir(), paste0(dataset_name, ".rds"))
}

#' Read data with caching support
#'
#' Internal workhorse that handles the path / cache / refresh logic shared by
#' both public load functions.
#'
#' @param csv_filename CSV file name inside `inst/extdata`.
#' @param path User-supplied path override (`NULL` = use bundled data).
#' @param cache Logical; if `TRUE`, save to / read from cache.
#' @param refresh Logical; if `TRUE`, ignore cache and re-read from source.
#' @return A `data.table`.
#' @noRd
read_with_cache <- function(csv_filename, path, cache, refresh) {
  dataset_name <- tools::file_path_sans_ext(csv_filename)

  if (!is.null(path)) {
    if (!file.exists(path)) {
      stop("File not found: ", path, call. = FALSE)
    }
    dt <- data.table::fread(path, encoding = "UTF-8", showProgress = FALSE)
    if (cache) save_cache(dt, dataset_name)
    return(dt)
  }

  cp <- cache_path(dataset_name)
  if (cache && !refresh && file.exists(cp)) {
    return(readRDS(cp))
  }

  bundled <- system.file("extdata", csv_filename, package = "krpoltext")
  if (bundled != "") {
    dt <- data.table::fread(bundled, encoding = "UTF-8", showProgress = FALSE)
    if (cache) save_cache(dt, dataset_name)
    return(dt)
  }

  ds_key <- .csv_to_dataset_key(csv_filename)
  if (!is.null(ds_key)) {
    message(
      "Data not found locally. Attempting to download from OSF...\n",
      "Run download_data(\"", ds_key, "\") to manage downloads explicitly."
    )
    download_data(ds_key, force = refresh)

    cp <- cache_path(dataset_name)
    if (file.exists(cp)) return(readRDS(cp))
  }

  stop(
    "Dataset '", csv_filename, "' not found.\n",
    "Options:\n",
    "  1. download_data() to download from OSF\n",
    "  2. Provide a path= argument pointing to the CSV file\n",
    "  3. Download manually: https://osf.io/rct9y/\n",
    "See the Data Descriptor: https://doi.org/10.1038/s41597-025-05220-4",
    call. = FALSE
  )
}

#' Map CSV filename to dataset key
#' @noRd
.csv_to_dataset_key <- function(csv_filename) {
  map <- c(
    "sk_election_campaign_booklet_v2022.csv" = "campaign_booklet",
    "sk_party_statements_v2022.csv"          = "party_statements"
  )
  unname(map[csv_filename])
}

#' Save data.table to cache as RDS
#' @noRd
save_cache <- function(dt, dataset_name) {
  cp <- cache_path(dataset_name)
  saveRDS(dt, cp)
  invisible(cp)
}

#' Clear cached datasets
#'
#' Removes cached RDS files created by [load_campaign_booklet()] and
#' [load_party_statements()].
#'
#' @param dataset Character vector of dataset names to clear, or `"all"` to
#'   clear everything. Valid names: `"campaign_booklet"`,
#'   `"party_statements"`.
#' @return Invisibly, a character vector of removed file paths.
#' @export
#' @examples
#' \dontrun{
#' clear_cache("all")
#' }
clear_cache <- function(dataset = "all") {
  valid <- c("campaign_booklet", "party_statements")
  if (identical(dataset, "all")) dataset <- valid

  bad <- setdiff(dataset, valid)
  if (length(bad) > 0) {
    stop(
      "Unknown dataset(s): ", paste(bad, collapse = ", "), "\n",
      "Valid options: ", paste(valid, collapse = ", "),
      call. = FALSE
    )
  }

  file_map <- c(
    campaign_booklet = "sk_election_campaign_booklet_v2022",
    party_statements = "sk_party_statements_v2022"
  )

  removed <- character()
  for (ds in dataset) {
    cp <- cache_path(file_map[[ds]])
    if (file.exists(cp)) {
      file.remove(cp)
      removed <- c(removed, cp)
    }
  }
  invisible(removed)
}
