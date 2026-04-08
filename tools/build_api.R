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
} else if (requireNamespace("devtools", quietly = TRUE)) {
  devtools::load_all(".", quiet = TRUE, export_all = FALSE)
} else {
  source("R/registry.R")
  source("R/catalog.R")
  source("R/metadata.R")
}

pkg_version <- read.dcf("DESCRIPTION", fields = "Version")[[1]]

# ---------------------------------------------------------------------------
# index.json
# ---------------------------------------------------------------------------

registry <- krpoltext:::.artifact_registry()
datasets <- names(registry)

resource_rows <- unlist(lapply(datasets, function(dataset) {
  meta <- krpoltext::metadata(dataset)
  formats <- krpoltext:::.supported_formats(dataset, data_version = meta$data_version)

  lapply(formats, function(format_name) {
    artifact <- krpoltext:::.artifact_spec(
      dataset,
      format = format_name,
      data_version = meta$data_version
    )

    list(
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
      schema_url = paste0("data/schema/", dataset, ".json"),
      license = meta$license
    )
  })
}), recursive = FALSE)

resources <- resource_rows

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
  resources = resources
)

jsonlite::write_json(
  index,
  file.path(out_dir, "index.json"),
  pretty = TRUE,
  auto_unbox = TRUE
)
message("Wrote ", file.path(out_dir, "index.json"))

# ---------------------------------------------------------------------------
# metadata.json
# ---------------------------------------------------------------------------

build_meta_entry <- function(dataset) {
  meta <- krpoltext::metadata(dataset)
  artifact <- krpoltext:::.artifact_spec(dataset, format = "csv", data_version = meta$data_version)
  download_urls <- stats::setNames(
    lapply(meta$managed_formats, function(format_name) {
      krpoltext:::.artifact_spec(
        dataset,
        format = format_name,
        data_version = meta$data_version
      )$url
    }),
    meta$managed_formats
  )

  list(
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
  )
}

metadata_out <- stats::setNames(
  lapply(datasets, build_meta_entry),
  datasets
)

jsonlite::write_json(
  metadata_out,
  file.path(out_dir, "metadata.json"),
  pretty = TRUE,
  auto_unbox = TRUE
)
message("Wrote ", file.path(out_dir, "metadata.json"))

# ---------------------------------------------------------------------------
# schema/*.json
# ---------------------------------------------------------------------------

for (dataset in datasets) {
  schema_out <- krpoltext::schema(dataset)
  dest <- file.path(out_dir, "schema", paste0(dataset, ".json"))
  jsonlite::write_json(
    schema_out,
    dest,
    pretty = TRUE,
    auto_unbox = TRUE,
    null = "null"
  )
  message("Wrote ", dest)
}

message("Static API files generated successfully in: ", out_dir)
