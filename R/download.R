#' Download krpoltext datasets from OSF
#'
#' Downloads the CSV data files from the OSF repository and caches them locally
#' as RDS files for fast subsequent loading. On first use the function asks for
#' interactive consent before starting the download. In non-interactive
#' sessions, uncached downloads are refused with an informative error.
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
#' if (interactive()) {
#'   # Download everything (asks for consent interactively)
#'   download_data()
#'
#'   # Download only party statements
#'   download_data("party_statements")
#'
#'   # Force re-download
#'   download_data("all", force = TRUE)
#' }
download_data <- function(dataset = "all", force = FALSE, quiet = FALSE) {
  valid <- names(.artifact_registry())
  if (identical(dataset, "all")) dataset <- valid

  bad <- setdiff(dataset, valid)
  if (length(bad) > 0) {
    stop(
      "Unknown dataset(s): ", paste(bad, collapse = ", "), "\n",
      "Valid options: ", paste(valid, collapse = ", "), ", or \"all\"",
      call. = FALSE
    )
  }

  results <- character()

  for (ds in dataset) {
    spec <- .artifact_spec(ds, format = "csv")
    rds_path <- cache_path(
      ds,
      format = "csv",
      data_version = spec$data_version,
      create_dir = FALSE
    )

    if (!force && file.exists(rds_path)) {
      if (!quiet) message("'", ds, "' already cached at: ", rds_path)
      results <- c(results, rds_path)
      next
    }

    if (!.is_interactive_session()) {
      stop(
        "Managed downloads are disabled in non-interactive sessions.\n",
        "Dataset: '", ds, "'.\n",
        "To proceed, either:\n",
        "  1. run download_data() interactively,\n",
        "  2. provide a local file via path= to load_*(), or\n",
        "  3. populate the cache in advance.\n",
        "See https://osf.io/rct9y/ for manual downloads.",
        call. = FALSE
      )
    }

    answer <- readline(.download_prompt(ds, spec))
    if (!tolower(trimws(answer)) %in% c("y", "yes")) {
      if (!quiet) message("Skipping '", ds, "'.")
      next
    }

    rds_path <- .download_one(ds, spec, quiet = quiet)
    results <- c(results, rds_path)
  }

  invisible(results)
}

#' Format variant text for prompts
#' @noRd
.prompt_variant_text <- function(variant = NULL) {
  if (is.null(variant)) {
    return("")
  }

  paste0(" (variant: ", variant, ")")
}

#' Build the interactive prompt used by load_* helpers
#' @noRd
.managed_load_prompt <- function(dataset, spec) {
  size_mb <- round(spec$size_bytes / 1e6)

  paste0(
    "'", dataset, "' is a large dataset. Download ",
    .format_label(spec$format), .prompt_variant_text(spec$variant),
    " artifact (", size_mb, " MB) from OSF? [y/N] "
  )
}

#' Build the interactive prompt used by download_data()
#' @noRd
.download_prompt <- function(dataset, spec) {
  size_mb <- round(spec$size_bytes / 1e6)

  paste0(
    "Download '", dataset, "' ", .format_label(spec$format),
    .prompt_variant_text(spec$variant),
    " artifact (", size_mb, " MB) from OSF? [y/N] "
  )
}

#' Download a single dataset, verify checksum, cache as RDS
#' @noRd
.download_one <- function(dataset_name, spec, quiet = FALSE) {
  if (!quiet) {
    message(
      "Downloading '", dataset_name, "' ",
      .format_label(spec$format), " artifact from OSF..."
    )
  }
  tmp_path <- .download_artifact(spec, quiet = quiet)
  on.exit(unlink(tmp_path), add = TRUE)

  if (!quiet) {
    message(
      "Reading ", .format_label(spec$format),
      " and caching as RDS..."
    )
  }
  dt <- .read_source_file(tmp_path, format = spec$format)
  rds_path <- save_cache(
    dt,
    dataset_name,
    format = spec$format,
    data_version = spec$data_version
  )

  if (!quiet) {
    message(
      "Done! '", dataset_name, "' cached at: ", rds_path, "\n",
      "  Rows: ", format(nrow(dt), big.mark = ","), "\n",
      "  Columns: ", ncol(dt)
    )
  }

  rds_path
}

#' Compute SHA-256 of a file
#' @noRd
.sha256sum <- function(path) {
  digest::digest(file = path, algo = "sha256")
}
