#!/usr/bin/env Rscript
#
# Regenerate Static API JSON files from R package metadata.
#
# Usage (from repo root):
#   Rscript tools/build_api.R [output_dir]
#
# Arguments:
#   output_dir  Directory to write JSON files into (default: "docs/data").
#               In CI, call after pkgdown build so docs/ already exists.
#               Locally, pass "pkgdown/extra/data" to update the committed copies.
#
# Reads from:
#   - R/registry.R  (.artifact_registry)
#   - R/metadata.R  (metadata, schema)
#   - DESCRIPTION   (package version)

args <- commandArgs(trailingOnly = TRUE)
out_dir <- if (length(args) >= 1) args[1] else "docs/data"
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(file.path(out_dir, "schema"), recursive = TRUE, showWarnings = FALSE)

if (requireNamespace("pkgload", quietly = TRUE)) {
  pkgload::load_all(".", quiet = TRUE, export_all = FALSE)
  pkg_env <- asNamespace("krpoltext")
} else if (requireNamespace("devtools", quietly = TRUE)) {
  devtools::load_all(".", quiet = TRUE, export_all = FALSE)
  pkg_env <- asNamespace("krpoltext")
} else {
  source("R/registry.R")
  source("R/catalog.R")
  source("R/metadata.R")
  pkg_env <- globalenv()
}

pkg_version <- read.dcf("DESCRIPTION", fields = "Version")[[1]]

pkg_fun <- function(name) {
  get(name, envir = pkg_env, inherits = FALSE)
}

schema_filename <- function(dataset, variant = NULL) {
  if (identical(dataset, "campaign_booklet") && identical(variant, "enriched")) {
    return("campaign_booklet_enriched.json")
  }

  paste0(dataset, ".json")
}

dataset_variants <- function(dataset) {
  variants <- pkg_fun(".available_variants")(dataset)
  if (length(variants) == 0L) {
    return(list(NULL))
  }

  as.list(variants)
}

# ---------------------------------------------------------------------------
# index.json
# ---------------------------------------------------------------------------

registry <- pkg_fun(".artifact_registry")()
datasets <- names(registry)

resource_rows <- list()
for (dataset in datasets) {
  for (variant_name in dataset_variants(dataset)) {
    meta <- pkg_fun("metadata")(dataset, variant = variant_name)
    formats <- pkg_fun(".supported_formats")(
      dataset,
      data_version = meta$data_version,
      variant = meta$variant
    )

    for (format_name in formats) {
      artifact <- pkg_fun(".artifact_spec")(
        dataset,
        format = format_name,
        data_version = meta$data_version,
        variant = meta$variant
      )

      resource <- list(
        name = dataset,
        file = artifact$file,
        version = meta$data_version,
        format = format_name,
        encoding = "UTF-8",
        size_bytes = artifact$size_bytes,
        sha256 = artifact$sha256,
        download_url = artifact$url,
        managed = !is.null(artifact$url) && nzchar(artifact$url),
        n_rows = meta$n_candidates_or_entries,
        n_cols = length(meta$columns),
        description = meta$description,
        time_coverage = meta$time_coverage,
        schema_url = paste0("data/schema/", schema_filename(dataset, meta$variant)),
        license = meta$license
      )

      if (!is.null(meta$variant)) {
        resource$variant <- meta$variant
        resource$default_for_package <- identical(meta$variant, meta$default_variant)
        resource$recommended_for <- meta$recommended_use
      }

      resource_rows[[length(resource_rows) + 1L]] <- resource
    }
  }
}

index <- list(
  api_version  = "1.0",
  base_url     = "https://taehyun-lim.github.io/krpoltext",
  generated_at = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
  package      = list(
    name      = "krpoltext",
    version   = pkg_version,
    github    = "https://github.com/taehyun-lim/krpoltext",
    paper_doi = "10.1038/s41597-025-05220-4"
  ),
  resources = resource_rows
)

jsonlite::write_json(
  index,
  file.path(out_dir, "index.json"),
  pretty = TRUE,
  auto_unbox = TRUE,
  null = "null"
)
message("Wrote ", file.path(out_dir, "index.json"))

# ---------------------------------------------------------------------------
# metadata.json
# ---------------------------------------------------------------------------

build_meta_entry <- function(dataset) {
  catalog_entry <- pkg_fun(".dataset_catalog")()[[dataset]]
  variants <- names(catalog_entry$variants %||% list())

  if (length(variants) == 0L) {
    meta <- pkg_fun("metadata")(dataset)
    artifact <- pkg_fun(".artifact_spec")(
      dataset,
      format = "csv",
      data_version = meta$data_version
    )
    download_urls <- stats::setNames(
      lapply(meta$managed_formats, function(format_name) {
        pkg_fun(".artifact_spec")(
          dataset,
          format = format_name,
          data_version = meta$data_version
        )$url
      }),
      meta$managed_formats
    )

    return(list(
      name = meta$name,
      description = meta$description,
      time_coverage = meta$time_coverage,
      n_entries = meta$n_candidates_or_entries,
      n_columns = length(meta$columns),
      version = meta$data_version,
      package_version = meta$package_version,
      supported_formats = meta$supported_formats,
      managed_formats = meta$managed_formats,
      source_url = meta$source_url,
      download_url = artifact$url,
      download_urls = download_urls,
      paper_doi = meta$paper_doi,
      license = meta$license,
      citation = meta$citation,
      osf_citation = meta$osf_citation,
      notes = meta$notes
    ))
  }

  variant_entries <- stats::setNames(
    lapply(variants, function(variant_name) {
      meta <- pkg_fun("metadata")(dataset, variant = variant_name)
      managed_urls <- stats::setNames(
        lapply(meta$supported_formats, function(format_name) {
          pkg_fun(".artifact_spec")(
            dataset,
            format = format_name,
            data_version = meta$data_version,
            variant = variant_name
          )$url
        }),
        meta$supported_formats
      )
      csv_artifact <- pkg_fun(".artifact_spec")(
        dataset,
        format = "csv",
        data_version = meta$data_version,
        variant = variant_name
      )

      list(
        variant = meta$variant,
        description = meta$description,
        variant_description = meta$variant_description,
        recommended_use = meta$recommended_use,
        n_columns = length(meta$columns),
        supported_formats = meta$supported_formats,
        managed_formats = meta$managed_formats,
        download_url = csv_artifact$url,
        download_urls = managed_urls,
        schema_url = paste0("data/schema/", schema_filename(dataset, meta$variant)),
        notes = meta$notes
      )
    }),
    variants
  )

  list(
    name = catalog_entry$name,
    description = catalog_entry$description,
    time_coverage = catalog_entry$time_coverage,
    n_entries = catalog_entry$n_candidates_or_entries,
    version = catalog_entry$data_version,
    package_version = pkg_version,
    default_variant = catalog_entry$default_variant,
    available_variants = variants,
    source_url = catalog_entry$source_url,
    paper_doi = catalog_entry$paper_doi,
    license = catalog_entry$license,
    citation = catalog_entry$citation,
    osf_citation = catalog_entry$osf_citation,
    variants = variant_entries
  )
}

`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

metadata_out <- stats::setNames(
  lapply(datasets, build_meta_entry),
  datasets
)

jsonlite::write_json(
  metadata_out,
  file.path(out_dir, "metadata.json"),
  pretty = TRUE,
  auto_unbox = TRUE,
  null = "null"
)
message("Wrote ", file.path(out_dir, "metadata.json"))

# ---------------------------------------------------------------------------
# schema/*.json
# ---------------------------------------------------------------------------

for (dataset in datasets) {
  variants <- pkg_fun(".available_variants")(dataset)

  if (length(variants) == 0L) {
    schema_out <- pkg_fun("schema")(dataset)
    dest <- file.path(out_dir, "schema", schema_filename(dataset))
    jsonlite::write_json(
      schema_out,
      dest,
      pretty = TRUE,
      auto_unbox = TRUE,
      null = "null"
    )
    message("Wrote ", dest)
    next
  }

  for (variant_name in variants) {
    schema_out <- pkg_fun("schema")(dataset, variant = variant_name)
    dest <- file.path(out_dir, "schema", schema_filename(dataset, variant_name))
    jsonlite::write_json(
      schema_out,
      dest,
      pretty = TRUE,
      auto_unbox = TRUE,
      null = "null"
    )
    message("Wrote ", dest)
  }
}

message("Static API files generated successfully in: ", out_dir)
