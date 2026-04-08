#' Retrieve dataset metadata
#'
#' Returns package-facing metadata for one of the bundled corpora, including
#' column names, versions, identifier fields, and available storage formats.
#'
#' @param dataset Character; which dataset to describe. One of
#'   `"campaign_booklet"` or `"party_statements"`.
#'
#' @return A named list with dataset metadata.
#' @export
#'
#' @examples
#' metadata("campaign_booklet")
#' metadata("party_statements")
metadata <- function(dataset = c("campaign_booklet", "party_statements")) {
  dataset <- match.arg(dataset)
  spec <- .dataset_spec(dataset)

  list(
    name = spec$name,
    description = spec$description,
    time_coverage = spec$time_coverage,
    columns = .dataset_columns(dataset),
    n_candidates_or_entries = spec$n_candidates_or_entries,
    data_version = spec$data_version,
    package_version = .package_version_string(),
    identifier_columns = spec$identifier_columns,
    text_columns = spec$text_columns,
    supported_formats = .supported_formats(dataset, data_version = spec$data_version),
    managed_formats = .managed_formats(dataset, data_version = spec$data_version),
    source_url = spec$source_url,
    paper_doi = spec$paper_doi,
    license = spec$license,
    citation = spec$citation,
    osf_citation = spec$osf_citation,
    notes = spec$notes
  )
}

#' Retrieve dataset schema
#'
#' Returns the column-level schema definition used by `krpoltext` for a given
#' dataset, including column types, descriptions, artifact metadata, and
#' dataset-specific extras such as office mappings.
#'
#' @param dataset Character; which dataset to describe. One of
#'   `"campaign_booklet"` or `"party_statements"`.
#'
#' @return A named list describing the dataset schema.
#' @export
#'
#' @examples
#' schema("campaign_booklet")
#' schema("party_statements")
schema <- function(dataset = c("campaign_booklet", "party_statements")) {
  dataset <- match.arg(dataset)
  spec <- .dataset_spec(dataset)
  data_version <- spec$data_version
  artifacts <- .artifact_registry()[[dataset]]$artifacts[[data_version]]

  artifact_specs <- lapply(names(artifacts), function(format_name) {
    artifact <- artifacts[[format_name]]
    list(
      format = format_name,
      file = artifact$file,
      download_url = artifact$url,
      sha256 = artifact$sha256,
      size_bytes = artifact$size_bytes,
      managed = !is.null(artifact$url) && nzchar(artifact$url)
    )
  })
  names(artifact_specs) <- names(artifacts)

  list(
    dataset = dataset,
    name = spec$name,
    description = spec$description,
    time_coverage = spec$time_coverage,
    data_version = data_version,
    package_version = .package_version_string(),
    identifier_columns = spec$identifier_columns,
    text_columns = spec$text_columns,
    supported_formats = .supported_formats(dataset, data_version = data_version),
    managed_formats = .managed_formats(dataset, data_version = data_version),
    artifacts = artifact_specs,
    columns = spec$columns,
    notes = spec$notes,
    extras = spec$extras
  )
}
