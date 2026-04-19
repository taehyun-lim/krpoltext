#' Dataset artifact registry
#' @noRd
.artifact_registry <- function() {
  list(
    campaign_booklet = list(
      latest_version = "v2022",
      default_variant = "original",
      variants = c("original", "enriched"),
      artifacts = list(
        v2022 = list(
          original = list(
            csv = list(
              file = "sk_election_campaign_booklet_v2022.csv",
              url = "https://osf.io/download/6ybj8/",
              sha256 = "6ce6f40f5358829b167109d9ca9195e5089d2c6d05a61ad1c1925e424f55021d",
              size_bytes = 756245336
            ),
            parquet = list(
              file = "sk_election_campaign_booklet_v2022.parquet",
              url = "https://osf.io/download/pxg2k/",
              sha256 = "a291a887d157963cffcffbe2c1ad60333222dd479bf4b01e90cec3a28d5c19a6",
              size_bytes = 406524268
            )
          ),
          enriched = list(
            csv = list(
              file = "sk_election_campaign_booklet_enriched_v2022.csv",
              url = "https://osf.io/download/69e3eec5352dbdd881fd8d7b/",
              sha256 = "08779d4c27a02635c7bf08a332170ac0a5bf1295e825e3b29061c62f95598586",
              size_bytes = 760045361
            ),
            parquet = list(
              file = "sk_election_campaign_booklet_enriched_v2022.parquet",
              url = "https://osf.io/download/69e3ee72a0e06b0928fd8ae2/",
              sha256 = "d8901cd2cebef30116f8865847727bb10855478ee556bc0dcfb5a04e838ad8f4",
              size_bytes = 406231949
            )
          )
        )
      )
    ),
    party_statements = list(
      latest_version = "v2022",
      artifacts = list(
        v2022 = list(
          csv = list(
            file = "sk_party_statements_v2022.csv",
            url = "https://osf.io/download/8u2ah/",
            sha256 = "60874e7c44d851c9cfc0892d70f6ef9ff9fb3993a5324963297ca4eabd4868e4",
            size_bytes = 740785920
          ),
          parquet = list(
            file = "sk_party_statements_v2022.parquet",
            url = "https://osf.io/download/8cjxu/",
            sha256 = "cee8a49adbe90f96ee4e2b45b6d84c433e5eb9ebb4849cfc979f6a19c57378ea",
            size_bytes = 393216464
          )
        )
      )
    )
  )
}

#' Resolve dataset key
#' @noRd
.dataset_key <- function(dataset) {
  match.arg(dataset, choices = names(.artifact_registry()))
}

#' Resolve data version
#' @noRd
.resolve_data_version <- function(dataset, data_version = NULL) {
  dataset <- .dataset_key(dataset)
  registry <- .artifact_registry()[[dataset]]

  if (is.null(data_version)) {
    return(registry$latest_version)
  }

  if (!is.character(data_version) || length(data_version) != 1L || !nzchar(data_version)) {
    stop("`data_version` must be NULL or a non-empty character string.", call. = FALSE)
  }

  if (!data_version %in% names(registry$artifacts)) {
    stop(
      "Unknown data_version '", data_version, "' for dataset '", dataset, "'.",
      call. = FALSE
    )
  }

  data_version
}

#' Available variants for a dataset version
#' @noRd
.available_variants <- function(dataset, data_version = NULL) {
  dataset <- .dataset_key(dataset)
  data_version <- .resolve_data_version(dataset, data_version)
  registry <- .artifact_registry()[[dataset]]

  if (is.null(registry$variants)) {
    return(character())
  }

  registry$variants
}

#' Resolve dataset variant
#' @noRd
.resolve_variant <- function(dataset, data_version = NULL, variant = NULL) {
  dataset <- .dataset_key(dataset)
  data_version <- .resolve_data_version(dataset, data_version)
  registry <- .artifact_registry()[[dataset]]
  available <- .available_variants(dataset, data_version = data_version)

  if (length(available) == 0L) {
    if (!is.null(variant)) {
      stop("Dataset '", dataset, "' does not define variants.", call. = FALSE)
    }
    return(NULL)
  }

  if (is.null(variant)) {
    if (!is.null(registry$default_variant) && nzchar(registry$default_variant)) {
      return(registry$default_variant)
    }
    return(available[[1]])
  }

  if (!is.character(variant) || length(variant) != 1L || !nzchar(variant)) {
    stop("`variant` must be NULL or a non-empty character string.", call. = FALSE)
  }

  if (!variant %in% available) {
    stop(
      "Unknown variant '", variant, "' for dataset '", dataset, "'.",
      call. = FALSE
    )
  }

  variant
}

#' Get artifact metadata for a dataset/format/version or variant
#' @noRd
.artifact_spec <- function(dataset,
                           format = c("parquet", "csv"),
                           data_version = NULL,
                           variant = NULL) {
  dataset <- .dataset_key(dataset)
  format <- match.arg(format)
  data_version <- .resolve_data_version(dataset, data_version)
  variant <- .resolve_variant(dataset, data_version = data_version, variant = variant)

  artifact_root <- .artifact_registry()[[dataset]]$artifacts[[data_version]]
  spec <- if (is.null(variant)) {
    artifact_root[[format]]
  } else {
    artifact_root[[variant]][[format]]
  }

  spec$dataset <- dataset
  spec$format <- format
  spec$data_version <- data_version
  spec$variant <- variant
  spec
}

#' Legacy CSV cache basename
#' @noRd
.legacy_cache_basename <- function(dataset, data_version = NULL, variant = NULL) {
  .artifact_spec(
    dataset,
    format = "csv",
    data_version = data_version,
    variant = variant
  )$file |>
    tools::file_path_sans_ext()
}
