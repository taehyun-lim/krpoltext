#' Retrieve dataset metadata
#'
#' Returns package-facing metadata for one of the bundled corpora, including
#' column names, versions, identifier fields, and available storage formats.
#'
#' @param dataset Character; which dataset to describe. One of
#'   `"campaign_booklet"` or `"party_statements"`.
#' @param variant Character or `NULL`; optional dataset variant. For
#'   `campaign_booklet`, defaults to `"original"` and may also be set to
#'   `"enriched"`. Other datasets do not define variants.
#'
#' @return A named list with dataset metadata.
#' @export
#'
#' @examples
#' metadata("campaign_booklet")
#' metadata("campaign_booklet", variant = "enriched")
#' metadata("party_statements")
metadata <- function(dataset = c("campaign_booklet", "party_statements"), variant = NULL) {
  dataset <- match.arg(dataset)
  spec <- .dataset_spec(dataset, variant = variant)
  variant <- spec$variant

  list(
    name = spec$name,
    description = spec$description,
    time_coverage = spec$time_coverage,
    columns = .dataset_columns(dataset, variant = variant),
    n_candidates_or_entries = spec$n_candidates_or_entries,
    data_version = spec$data_version,
    package_version = .package_version_string(),
    variant = variant,
    default_variant = spec$default_variant,
    available_variants = spec$available_variants,
    variant_description = spec$variant_description,
    recommended_use = spec$recommended_use,
    identifier_columns = spec$identifier_columns,
    text_columns = spec$text_columns,
    supported_formats = .supported_formats(
      dataset,
      data_version = spec$data_version,
      variant = variant
    ),
    managed_formats = .managed_formats(
      dataset,
      data_version = spec$data_version,
      variant = variant
    ),
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
#' @param variant Character or `NULL`; optional dataset variant. For
#'   `campaign_booklet`, defaults to `"original"` and may also be set to
#'   `"enriched"`. Other datasets do not define variants.
#'
#' @return A named list describing the dataset schema.
#' @export
#'
#' @examples
#' schema("campaign_booklet")
#' schema("campaign_booklet", variant = "enriched")
#' schema("party_statements")
schema <- function(dataset = c("campaign_booklet", "party_statements"), variant = NULL) {
  dataset <- match.arg(dataset)
  spec <- .dataset_spec(dataset, variant = variant)
  data_version <- spec$data_version
  variant <- spec$variant
  artifact_root <- .artifact_registry()[[dataset]]$artifacts[[data_version]]
  artifacts <- if (is.null(variant)) artifact_root else artifact_root[[variant]]

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
    variant = variant,
    default_variant = spec$default_variant,
    available_variants = spec$available_variants,
    variant_description = spec$variant_description,
    recommended_use = spec$recommended_use,
    identifier_columns = spec$identifier_columns,
    text_columns = spec$text_columns,
    supported_formats = .supported_formats(dataset, data_version = data_version, variant = variant),
    managed_formats = .managed_formats(dataset, data_version = data_version, variant = variant),
    artifacts = artifact_specs,
    columns = spec$columns,
    notes = spec$notes,
    extras = spec$extras
  )
}
