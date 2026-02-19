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
#   - R/download.R  (.data_registry)
#   - R/metadata.R  (metadata)
#   - DESCRIPTION   (package version)
#
# Schema files (pkgdown/extra/data/schema/) are maintained manually
# because column-level descriptions require human curation.
# This script copies them into the output directory alongside the
# generated files.

args <- commandArgs(trailingOnly = TRUE)
out_dir <- if (length(args) >= 1) args[1] else "docs/data"
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(file.path(out_dir, "schema"), recursive = TRUE, showWarnings = FALSE)

devtools::load_all(".", quiet = TRUE)

pkg_version <- read.dcf("DESCRIPTION", fields = "Version")[[1]]

# ---------------------------------------------------------------------------
# index.json
# ---------------------------------------------------------------------------

registry <- krpoltext:::.data_registry()
meta_cb  <- krpoltext::metadata("campaign_booklet")
meta_ps  <- krpoltext::metadata("party_statements")

resources <- list(
  list(
    name          = "campaign_booklet",
    file          = registry$campaign_booklet$csv_name,
    version       = "v2022",
    format        = "csv",
    encoding      = "UTF-8",
    size_bytes    = registry$campaign_booklet$size_bytes,
    sha256        = registry$campaign_booklet$sha256,
    download_url  = registry$campaign_booklet$url,
    n_rows        = meta_cb$n_candidates_or_entries,
    n_cols        = length(meta_cb$columns),
    description   = meta_cb$description,
    time_coverage = meta_cb$time_coverage,
    schema_url    = "data/schema/campaign_booklet.json",
    license       = "CC BY-NC-ND 4.0"
  ),
  list(
    name          = "party_statements",
    file          = registry$party_statements$csv_name,
    version       = "v2022",
    format        = "csv",
    encoding      = "UTF-8",
    size_bytes    = registry$party_statements$size_bytes,
    sha256        = registry$party_statements$sha256,
    download_url  = registry$party_statements$url,
    n_rows        = meta_ps$n_candidates_or_entries,
    n_cols        = length(meta_ps$columns),
    description   = meta_ps$description,
    time_coverage = meta_ps$time_coverage,
    schema_url    = "data/schema/party_statements.json",
    license       = "CC BY-NC-ND 4.0"
  )
)

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

paper_citation <- paste(
  "Lim, T.H. (2025). South Korean Election Campaign Booklet and",
  "Party Statements Corpora. Scientific Data, 12, 1030.",
  "https://doi.org/10.1038/s41597-025-05220-4"
)
osf_citation <- paste(
  "Lim, T.H. (2024). South Korean Election Campaign Booklet Corpus and",
  "Party Statements Corpus. OSF.",
  "https://doi.org/10.17605/OSF.IO/RCT9Y"
)

build_meta_entry <- function(m, reg) {
  list(
    name          = m$name,
    description   = m$description,
    time_coverage = m$time_coverage,
    n_entries     = m$n_candidates_or_entries,
    n_columns     = length(m$columns),
    version       = "v2022",
    last_updated  = "2025-03-20",
    source_url    = m$source_url,
    download_url  = reg$url,
    paper_doi     = m$paper_doi,
    license       = "CC BY-NC-ND 4.0",
    citation      = paper_citation,
    osf_citation  = osf_citation
  )
}

metadata_out <- list(
  campaign_booklet  = build_meta_entry(meta_cb, registry$campaign_booklet),
  party_statements  = build_meta_entry(meta_ps, registry$party_statements)
)

jsonlite::write_json(
  metadata_out,
  file.path(out_dir, "metadata.json"),
  pretty = TRUE,
  auto_unbox = TRUE
)
message("Wrote ", file.path(out_dir, "metadata.json"))

# ---------------------------------------------------------------------------
# Copy schema files into output directory
# ---------------------------------------------------------------------------

schema_src <- "pkgdown/extra/data/schema"
if (dir.exists(schema_src)) {
  schema_files <- list.files(schema_src, full.names = TRUE)
  for (f in schema_files) {
    dest <- file.path(out_dir, "schema", basename(f))
    file.copy(f, dest, overwrite = TRUE)
    message("Copied ", f, " -> ", dest)
  }
}

message("Static API files generated successfully in: ", out_dir)
