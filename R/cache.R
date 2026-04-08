#' Get the cache directory path
#'
#' Returns the path to the krpoltext cache directory. Creates it if it does not
#' exist.
#'
#' @param create Logical; if `TRUE`, create the directory when missing.
#' @return A character string with the cache directory path.
#' @noRd
cache_dir <- function(create = TRUE) {
  d <- .krpoltext_env$cache_dir
  if (isTRUE(create) && !dir.exists(d)) {
    dir.create(d, recursive = TRUE, showWarnings = FALSE)
  }
  d
}

#' Build a cache key for a dataset artifact
#' @noRd
cache_key <- function(dataset, format = c("parquet", "csv"), data_version = NULL) {
  dataset <- .dataset_key(dataset)
  format <- match.arg(format)
  data_version <- .resolve_data_version(dataset, data_version)

  paste(dataset, data_version, format, sep = "__")
}

#' Build cache file path for a dataset artifact
#' @noRd
cache_path <- function(dataset,
                       format = c("parquet", "csv"),
                       data_version = NULL,
                       create_dir = TRUE) {
  file.path(
    cache_dir(create = create_dir),
    paste0(cache_key(dataset, format = format, data_version = data_version), ".rds")
  )
}

#' Get the legacy CSV cache path
#' @noRd
.legacy_cache_path <- function(dataset, data_version = NULL, create_dir = FALSE) {
  file.path(
    cache_dir(create = create_dir),
    paste0(.legacy_cache_basename(dataset, data_version), ".rds")
  )
}

#' Find a bundled artifact path
#' @noRd
.bundled_artifact_path <- function(file) {
  system.file("extdata", file, package = "krpoltext")
}

#' Emit load notes once before returning a fallback
#' @noRd
.emit_load_notes <- function(notes) {
  notes <- unique(stats::na.omit(notes))
  if (length(notes) > 0L) {
    message(paste(notes, collapse = "\n"))
  }
}

#' Infer source format from a local path when possible
#' @noRd
.path_format <- function(path, format = c("parquet", "csv")) {
  format <- match.arg(format)
  ext <- tolower(tools::file_ext(path))

  if (!ext %in% c("csv", "parquet")) {
    return(format)
  }

  if (!identical(ext, format)) {
    message(
      "Local file extension suggests format '", ext,
      "'; using that instead of requested '", format, "'."
    )
  }

  ext
}

#' Check whether Parquet reading is available
#' @noRd
.can_read_parquet <- function() {
  requireNamespace("arrow", quietly = TRUE)
}

#' Read a dataset source file into memory
#' @noRd
.read_source_file <- function(path, format = c("parquet", "csv")) {
  format <- match.arg(format)

  if (!file.exists(path)) {
    stop("File not found: ", path, call. = FALSE)
  }

  switch(
    format,
    csv = data.table::fread(path, encoding = "UTF-8", showProgress = FALSE),
    parquet = {
      if (!.can_read_parquet()) {
        stop(
          "Package 'arrow' is required to read Parquet files.\n",
          "Install it with: install.packages(\"arrow\")",
          call. = FALSE
        )
      }

      data.table::as.data.table(arrow::read_parquet(path, as_data_frame = TRUE))
    }
  )
}

#' Download a single artifact to a temporary file
#' @noRd
.download_artifact <- function(spec, quiet = FALSE) {
  ext <- switch(spec$format, parquet = ".parquet", ".csv")
  tmp_path <- tempfile(fileext = ext)

  tryCatch(
    utils::download.file(
      url = spec$url,
      destfile = tmp_path,
      mode = "wb",
      quiet = quiet
    ),
    error = function(e) {
      stop(
        "Download failed for '", spec$dataset, "' (", spec$format, ").\n",
        "URL: ", spec$url, "\n",
        "Error: ", conditionMessage(e), "\n",
        "Download manually: https://osf.io/rct9y/\n",
        "Data Descriptor: https://doi.org/10.1038/s41597-025-05220-4",
        call. = FALSE
      )
    }
  )

  if (!is.null(spec$sha256)) {
    actual_sha <- .sha256sum(tmp_path)
    if (!is.null(actual_sha) && !identical(actual_sha, spec$sha256)) {
      warning(
        "SHA-256 mismatch for '", spec$dataset, "' (", spec$format, ")!\n",
        "Expected: ", spec$sha256, "\n",
        "Got:      ", actual_sha,
        call. = FALSE
      )
    }
  }

  tmp_path
}

#' Abort managed downloads in non-interactive sessions
#' @noRd
.abort_noninteractive_download <- function(dataset, format) {
  stop(
    "Managed downloads are disabled in non-interactive sessions.\n",
    "Dataset: '", dataset, "' (", format, ").\n",
    "To proceed, either:\n",
    "  1. run the loader or download_data() interactively,\n",
    "  2. provide a local CSV or Parquet file via path=, or\n",
    "  3. populate the cache in advance.\n",
    "Manual download: https://osf.io/rct9y/",
    call. = FALSE
  )
}

#' Read data with caching and format fallback support
#'
#' Internal workhorse that handles path / cache / refresh logic for the public
#' load functions while supporting both CSV and Parquet inputs.
#'
#' @param dataset Dataset key.
#' @param path User-supplied path override (`NULL` = use managed artifacts).
#' @param cache Logical; if `TRUE`, save to / read from cache.
#' @param refresh Logical; if `TRUE`, ignore cache and re-read from source.
#' @param format Requested storage format.
#' @param data_version Data artifact version.
#' @return A `data.table`.
#' @noRd
read_with_cache <- function(dataset,
                            path = NULL,
                            cache = TRUE,
                            refresh = FALSE,
                            format = c("parquet", "csv"),
                            data_version = NULL) {
  stopifnot(is.logical(cache), length(cache) == 1L)
  stopifnot(is.logical(refresh), length(refresh) == 1L)

  dataset <- .dataset_key(dataset)
  format <- match.arg(format)
  data_version <- .resolve_data_version(dataset, data_version)

  if (!is.null(path) && !is.character(path)) {
    stop("`path` must be NULL or a character string.", call. = FALSE)
  }

  if (!is.null(path)) {
    path_format <- .path_format(path, format = format)
    dt <- .read_source_file(path, format = path_format)
    if (cache) save_cache(dt, dataset, format = path_format, data_version = data_version)
    return(dt)
  }

  candidate_formats <- unique(c(format, if (identical(format, "parquet")) "csv"))
  notes <- character()

  for (candidate in candidate_formats) {
    if (candidate == "parquet" && !.can_read_parquet()) {
      notes <- c(notes, "Package 'arrow' is not installed; falling back to CSV.")
      next
    }

    cp <- cache_path(
      dataset,
      format = candidate,
      data_version = data_version,
      create_dir = FALSE
    )
    if (cache && !refresh && file.exists(cp)) {
      if (candidate != format) .emit_load_notes(notes)
      return(readRDS(cp))
    }

    if (cache && !refresh && candidate == "csv") {
      legacy_cp <- .legacy_cache_path(dataset, data_version = data_version, create_dir = FALSE)
      if (file.exists(legacy_cp)) {
        if (candidate != format) .emit_load_notes(notes)
        return(readRDS(legacy_cp))
      }
    }

    spec <- .artifact_spec(dataset, format = candidate, data_version = data_version)
    bundled <- .bundled_artifact_path(spec$file)
    if (nzchar(bundled)) {
      dt <- .read_source_file(bundled, format = candidate)
      if (cache) save_cache(dt, dataset, format = candidate, data_version = data_version)
      if (candidate != format) .emit_load_notes(notes)
      return(dt)
    }

    if (!is.null(spec$url)) {
      if (!interactive()) {
        if (!identical(candidate, tail(candidate_formats, 1L))) {
          notes <- c(
            notes,
            paste0(
              "Managed ", candidate,
              " download is disabled in non-interactive sessions; trying the next available format."
            )
          )
          next
        }

        .abort_noninteractive_download(dataset = dataset, format = candidate)
      }

      if (!refresh) {
        message(
          "Data not found locally. Attempting to download from OSF...\n",
          "Run download_data(\"", dataset, "\") to manage downloads explicitly."
        )
      }

      artifact_path <- .download_artifact(spec, quiet = FALSE)
      on.exit(unlink(artifact_path), add = TRUE)

      dt <- .read_source_file(artifact_path, format = candidate)
      if (cache) save_cache(dt, dataset, format = candidate, data_version = data_version)
      if (candidate != format) .emit_load_notes(notes)
      return(dt)
    }

    if (candidate == "parquet") {
      notes <- c(
        notes,
        paste0(
          "Parquet artifact for '", dataset, "' (", data_version,
          ") is not available; falling back to CSV."
        )
      )
    }
  }

  stop(
    "Dataset '", dataset, "' with format '", format, "' is not available.\n",
    "Options:\n",
    "  1. download_data() to download CSV data from OSF\n",
    "  2. Provide a path= argument pointing to a local CSV or Parquet file\n",
    "  3. Download manually: https://osf.io/rct9y/\n",
    "See the Data Descriptor: https://doi.org/10.1038/s41597-025-05220-4",
    call. = FALSE
  )
}

#' Save a data.table to the cache
#' @noRd
save_cache <- function(dt, dataset, format = c("parquet", "csv"), data_version = NULL) {
  cp <- cache_path(dataset, format = format, data_version = data_version, create_dir = TRUE)
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
#' if (interactive()) {
#'   clear_cache("all")
#' }
clear_cache <- function(dataset = "all") {
  valid <- names(.artifact_registry())
  if (identical(dataset, "all")) dataset <- valid

  bad <- setdiff(dataset, valid)
  if (length(bad) > 0) {
    stop(
      "Unknown dataset(s): ", paste(bad, collapse = ", "), "\n",
      "Valid options: ", paste(valid, collapse = ", "),
      call. = FALSE
    )
  }

  removed <- character()
  cache_root <- cache_dir(create = FALSE)
  if (!dir.exists(cache_root)) {
    return(invisible(removed))
  }

  for (ds in dataset) {
    pattern <- paste0("^", ds, "__.*\\.rds$")
    cache_files <- list.files(cache_root, pattern = pattern, full.names = TRUE)
    legacy_cp <- .legacy_cache_path(ds, create_dir = FALSE)
    cache_files <- unique(c(cache_files, legacy_cp))

    for (cp in cache_files) {
      if (file.exists(cp)) {
        file.remove(cp)
        removed <- c(removed, cp)
      }
    }
  }

  invisible(removed)
}
