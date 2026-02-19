#' Download krpoltext datasets from OSF
#'
#' Downloads the CSV data files from the OSF repository and caches them locally
#' as RDS files for fast subsequent loading. On first use the function asks for
#' interactive consent before starting the download.
#'
#' @param dataset Character vector of datasets to download. Valid values are
#'   `"campaign_booklet"`, `"party_statements"`, or `"all"` (default).
#' @param force Logical; if `TRUE`, re-download even if cached files exist.
#'   Defaults to `FALSE`.
#' @param quiet Logical; if `TRUE`, suppress progress messages. Defaults to
#'   `FALSE`.
#'
#' @return Invisibly, a character vector of paths to the cached RDS files.
#'
#' @details
#' Downloaded CSV files are read with [data.table::fread()], then saved as
#' compressed RDS in the user's cache directory
#' (`tools::R_user_dir("krpoltext", "cache")`). The original CSV is not kept
#' on disk; only the RDS cache is stored.
#'
#' File integrity is verified via SHA-256 checksums published with the OSF
#' release.
#'
#' @export
#' @examples
#' \dontrun{
#' # Download everything (asks for consent interactively)
#' download_data()
#'
#' # Download only party statements
#' download_data("party_statements")
#'
#' # Force re-download
#' download_data("all", force = TRUE)
#' }
download_data <- function(dataset = "all", force = FALSE, quiet = FALSE) {
  valid <- c("campaign_booklet", "party_statements")
  if (identical(dataset, "all")) dataset <- valid

  bad <- setdiff(dataset, valid)
  if (length(bad) > 0) {
    stop(
      "Unknown dataset(s): ", paste(bad, collapse = ", "), "\n",
      "Valid options: ", paste(valid, collapse = ", "), ", or \"all\"",
      call. = FALSE
    )
  }

  registry <- .data_registry()
  results <- character()

  for (ds in dataset) {
    info <- registry[[ds]]
    rds_path <- cache_path(info$rds_name)

    if (!force && file.exists(rds_path)) {
      if (!quiet) message("'", ds, "' already cached at: ", rds_path)
      results <- c(results, rds_path)
      next
    }

    if (interactive()) {
      size_mb <- round(info$size_bytes / 1e6)
      answer <- readline(paste0(
        "Download '", ds, "' (", size_mb, " MB) from OSF? [y/N] "
      ))
      if (!tolower(trimws(answer)) %in% c("y", "yes")) {
        if (!quiet) message("Skipping '", ds, "'.")
        next
      }
    }

    rds_path <- .download_one(ds, info, quiet = quiet)
    results <- c(results, rds_path)
  }

  invisible(results)
}

#' Registry of available datasets with URLs and checksums
#' @noRd
.data_registry <- function() {
  list(
    campaign_booklet = list(
      url       = "https://osf.io/download/6ybj8/",
      csv_name  = "sk_election_campaign_booklet_v2022.csv",
      rds_name  = "sk_election_campaign_booklet_v2022",
      sha256    = "6ce6f40f5358829b167109d9ca9195e5089d2c6d05a61ad1c1925e424f55021d",
      size_bytes = 756245336
    ),
    party_statements = list(
      url       = "https://osf.io/download/8u2ah/",
      csv_name  = "sk_party_statements_v2022.csv",
      rds_name  = "sk_party_statements_v2022",
      sha256    = "60874e7c44d851c9cfc0892d70f6ef9ff9fb3993a5324963297ca4eabd4868e4",
      size_bytes = 740785920
    )
  )
}

#' Download a single dataset, verify checksum, cache as RDS
#' @noRd
.download_one <- function(dataset_name, info, quiet = FALSE) {
  tmp_csv <- tempfile(fileext = ".csv")
  on.exit(unlink(tmp_csv), add = TRUE)

  if (!quiet) message("Downloading '", dataset_name, "' from OSF...")

  tryCatch(
    utils::download.file(
      url      = info$url,
      destfile = tmp_csv,
      mode     = "wb",
      quiet    = quiet
    ),
    error = function(e) {
      stop(
        "Download failed for '", dataset_name, "'.\n",
        "URL: ", info$url, "\n",
        "Error: ", conditionMessage(e), "\n",
        "Download manually: https://osf.io/rct9y/\n",
        "Data Descriptor: https://doi.org/10.1038/s41597-025-05220-4",
        call. = FALSE
      )
    }
  )

  if (!quiet) message("Verifying checksum...")
  actual_sha <- .sha256sum(tmp_csv)
  if (!is.null(actual_sha) && !identical(actual_sha, info$sha256)) {
    warning(
      "SHA-256 mismatch for '", dataset_name, "'!\n",
      "Expected: ", info$sha256, "\n",
      "Got:      ", actual_sha, "\n",
      "The file may be corrupted or updated. Proceeding anyway.",
      call. = FALSE
    )
  }

  if (!quiet) message("Reading CSV and caching as RDS...")
  dt <- data.table::fread(tmp_csv, encoding = "UTF-8", showProgress = !quiet)
  rds_path <- save_cache(dt, info$rds_name)

  if (!quiet) {
    message(
      "Done! '", dataset_name, "' cached at: ", rds_path, "\n",
      "  Rows: ", format(nrow(dt), big.mark = ","), "\n",
      "  Columns: ", ncol(dt)
    )
  }

  rds_path
}

#' Compute SHA-256 of a file (returns NULL if digest not available)
#' @noRd
.sha256sum <- function(path) {
  if (requireNamespace("digest", quietly = TRUE)) {
    return(digest::digest(file = path, algo = "sha256"))
  }
  tryCatch({
    output <- system2("shasum", args = c("-a", "256", path), stdout = TRUE)
    sub("\\s.*$", "", output[1])
  }, error = function(e) NULL)
}
