#' Dataset artifact registry
#' @noRd
.artifact_registry <- function() {
  list(
    campaign_booklet = list(
      latest_version = "v2022",
      artifacts = list(
        v2022 = list(
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

#' Get artifact metadata for dataset/format/version
#' @noRd
.artifact_spec <- function(dataset, format = c("parquet", "csv"), data_version = NULL) {
  dataset <- .dataset_key(dataset)
  format <- match.arg(format)
  data_version <- .resolve_data_version(dataset, data_version)

  spec <- .artifact_registry()[[dataset]]$artifacts[[data_version]][[format]]
  spec$dataset <- dataset
  spec$format <- format
  spec$data_version <- data_version
  spec
}

#' Legacy CSV cache basename
#' @noRd
.legacy_cache_basename <- function(dataset, data_version = NULL) {
  .artifact_spec(dataset, format = "csv", data_version = data_version)$file |>
    tools::file_path_sans_ext()
}
