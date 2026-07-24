#' Dataset catalog helpers
#' @noRd
.column_spec <- function(name, type, description, identifier = FALSE) {
  spec <- list(
    name = name,
    type = type,
    description = description
  )

  if (isTRUE(identifier)) {
    spec$identifier <- TRUE
  }

  spec
}

#' Dataset catalog
#' @noRd
.dataset_catalog <- function() {
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

  office_mapping <- list(
    list(office_id = 1L, office = "president", description = "Presidential election"),
    list(office_id = 2L, office = "national_assembly", description = "National Assembly election"),
    list(office_id = 3L, office = "metro_head", description = "Metropolitan city mayor / provincial governor"),
    list(office_id = 4L, office = "basic_head", description = "Basic local government head"),
    list(office_id = 5L, office = "metro_assembly", description = "Metropolitan assembly member"),
    list(office_id = 6L, office = "basic_assembly", description = "Basic assembly member"),
    list(office_id = 11L, office = "education_superintendent", description = "Education superintendent")
  )

  campaign_original_columns <- list(
    .column_spec("date", "character", "Election date (YYYY-MM-DD)"),
    .column_spec("name", "character", "Candidate name (Korean)"),
    .column_spec("region", "character", "Metropolitan region (province or metropolitan city)"),
    .column_spec("district", "character", "Electoral district"),
    .column_spec(
      "office_id",
      "integer",
      paste(
        "Office type identifier (1=president, 2=national_assembly,",
        "3=metro_head, 4=basic_head, 5=metro_assembly,",
        "6=basic_assembly, 11=education_superintendent)"
      )
    ),
    .column_spec(
      "office",
      "character",
      paste(
        "Office type label (president, national_assembly,",
        "metro_head, basic_head, metro_assembly, basic_assembly,",
        "education_superintendent)"
      )
    ),
    .column_spec("giho", "integer", "Candidate ballot number"),
    .column_spec("party", "character", "Political party name (Korean)"),
    .column_spec(
      "party_eng",
      "character",
      "Political party name (English); transliteration if no official English name"
    ),
    .column_spec("result", "character", "Election result in Korean"),
    .column_spec("sex", "character", "Sex in Korean"),
    .column_spec("birthday", "character", "Date of birth (YYYY-MM-DD)"),
    .column_spec("age", "integer", "Age at the time of the election"),
    .column_spec("job_id", "integer", "Original NEC job category identifier (varies across years)"),
    .column_spec("job", "character", "Standardized job category (Korean)"),
    .column_spec("job_name", "character", "Job title (Korean)"),
    .column_spec("job_name_eng", "character", "Job title (English)"),
    .column_spec("job_code", "integer", "Standardized job code consistent across years"),
    .column_spec("edu_id", "integer", "Original NEC education level identifier (varies across years)"),
    .column_spec("edu", "character", "Education description (Korean, free-text from NEC)"),
    .column_spec("edu_name", "character", "Standardized education level label (Korean)"),
    .column_spec("edu_name_eng", "character", "Standardized education level label (English)"),
    .column_spec("edu_code", "integer", "Standardized education code consistent across years"),
    .column_spec("career1", "character", "Career description 1"),
    .column_spec("career2", "character", "Career description 2"),
    .column_spec("pages", "integer", "Number of pages in the booklet"),
    .column_spec("code", "character", "krpoltext document row identifier", identifier = TRUE),
    .column_spec("sex_code", "integer", "Sex code: 1 = male, 0 = female"),
    .column_spec("result_code", "integer", "Result code: 1 = elected, 0 = not elected"),
    .column_spec("text", "character", "Full OCR-extracted text of the campaign booklet"),
    .column_spec(
      "filtered",
      "character",
      paste(
        "Parsed text after morphological analysis; Korean-only,",
        "numbers, foreign characters, and symbols removed"
      )
    )
  )

  campaign_enriched_columns <- append(
    campaign_original_columns[1:27],
    list(
      .column_spec(
        "huboid",
        "character",
        paste(
          "Linked NEC candidate identifier used for conservative",
          "kr-elections-mcp alignment; unresolved rows remain NA"
        )
      ),
      .column_spec(
        "sg_id",
        "character",
        "Linked NEC election identifier used for NEC-aligned workflows"
      ),
      .column_spec(
        "sg_typecode",
        "character",
        "Linked NEC election type identifier used for NEC-aligned workflows"
      ),
      .column_spec(
        "link_status",
        "character",
        "Linkage status for NEC alignment (resolved, ambiguous, not_found, rejected)"
      ),
      .column_spec(
        "matcher_version",
        "character",
        "Version of the linkage pipeline used to assign NEC fields"
      ),
      .column_spec(
        "nec_snapshot_id",
        "character",
        "Identifier of the NEC snapshot used to assign NEC fields"
      )
    )
  )
  campaign_enriched_columns <- append(campaign_enriched_columns, campaign_original_columns[28:31])

  campaign_family_description <- paste(
    "Official campaign booklets (manifesto booklets) filed by 49,678",
    "individual candidates in South Korean presidential, National Assembly,",
    "and local elections from 2000 to 2022. The dataset is distributed in",
    "two public variants: the original corpus artifact and an enriched",
    "artifact with conservative NEC linkage fields for integration workflows."
  )

  campaign_shared_notes <- list(
    missing_values = paste(
      "2,283 rows have no booklet code or text because a booklet was not",
      "available. 151 are missing biographical information. 23 booklets were",
      "unprocessable."
    ),
    text_processing = paste(
      "All text is UTF-8 encoded Korean. 'text' contains the full",
      "original text; 'filtered' contains the morphologically parsed version."
    )
  )

  list(
    campaign_booklet = list(
      name = "South Korean Election Campaign Booklets",
      description = campaign_family_description,
      short_description = paste(
        "Official campaign booklets from 49,678 candidates in presidential,",
        "National Assembly, and local elections (2000-2022), available in",
        "original and enriched variants."
      ),
      time_coverage = "2000-2022",
      data_version = "v2022",
      n_candidates_or_entries = 49678L,
      source_url = "https://osf.io/rct9y/",
      paper_doi = "10.1038/s41597-025-05220-4",
      license = "CC BY-NC-ND 4.0",
      citation = paper_citation,
      osf_citation = osf_citation,
      default_variant = "original",
      variants = list(
        original = list(
          variant = "original",
          variant_description = paste(
            "The original krpoltext campaign booklet corpus artifact."
          ),
          description = paste(
            "Original krpoltext campaign booklet corpus artifact covering",
            "49,678 document rows from South Korean presidential, National",
            "Assembly, and local elections, 2000-2022."
          ),
          recommended_use = "General corpus analysis and backward-compatible workflows.",
          identifier_columns = "code",
          text_columns = c("text", "filtered"),
          columns = campaign_original_columns,
          notes = c(
            campaign_shared_notes,
            list(
              identifiers = paste(
                "'code' is the krpoltext document row identifier, but some",
                "original rows have missing code values, so row identity should",
                "not be inferred from code alone. 'job_id' and 'edu_id' vary",
                "across election years; use 'job_code' and 'edu_code' for",
                "cross-year analysis."
              ),
              provenance = paste(
                "The original variant is the source corpus artifact distributed",
                "without NEC linkage fields."
              )
            )
          ),
          extras = list(
            office_mapping = office_mapping,
            row_universe = "Original campaign_booklet CSV source artifact."
          )
        ),
        enriched = list(
          variant = "enriched",
          variant_description = paste(
            "The same document-row universe as the original CSV source, plus",
            "conservative NEC linkage fields for integration workflows."
          ),
          description = paste(
            "Enriched campaign booklet artifact using the same document-row",
            "universe as the original CSV source, with conservative NEC",
            "linkage fields such as 'huboid', 'sg_id', and 'sg_typecode'",
            "added to improve interoperability with kr-elections-mcp and",
            "related NEC-aligned workflows."
          ),
          recommended_use = "NEC-aligned workflows, kr-elections-mcp, and linkage-aware joins.",
          identifier_columns = "code",
          text_columns = c("text", "filtered"),
          columns = campaign_enriched_columns,
          notes = c(
            campaign_shared_notes,
            list(
              identifiers = paste(
                "'code' is the krpoltext document row identifier, but some",
                "rows have missing code values, so row identity should not be",
                "inferred from code alone. 'huboid' is a linked NEC identifier,",
                "not a native krpoltext identifier. Rows with",
                "'link_status == \"resolved\"' are expected to have a non-null",
                "'huboid'. 'sg_id' and 'sg_typecode' describe the NEC-aligned",
                "election scope attached to the row. 'job_id' and 'edu_id'",
                "vary across election years; use 'job_code' and 'edu_code' for",
                "cross-year analysis."
              ),
              provenance = paste(
                "The enriched variant is a row-preserving transformation of",
                "the original campaign_booklet CSV source. It adds conservative",
                "NEC linkage metadata to improve interoperability with",
                "kr-elections-mcp and related NEC-aligned workflows."
              ),
              artifact_transition = paste(
                "When the enriched campaign_booklet artifact is rebuilt or",
                "republished, update registry checksums, sizes, and URLs in",
                "lockstep with this schema."
              )
            )
          ),
          extras = list(
            office_mapping = office_mapping,
            row_universe = paste(
              "Same document-row universe as the original campaign_booklet",
              "CSV source; some rows have missing code values."
            ),
            linkage_fields = list(
              list(name = "huboid", role = "linked_nec_candidate_identifier", nullable = TRUE),
              list(name = "sg_id", role = "linked_nec_election_identifier", nullable = TRUE),
              list(name = "sg_typecode", role = "linked_nec_election_type_identifier", nullable = TRUE),
              list(name = "link_status", role = "linkage_status", nullable = FALSE),
              list(name = "matcher_version", role = "linkage_provenance", nullable = TRUE),
              list(name = "nec_snapshot_id", role = "linkage_provenance", nullable = TRUE)
            )
          )
        )
      )
    ),
    party_statements = list(
      name = "South Korean Party Statements",
      description = paste(
        "Official statements from party spokespersons and minutes from",
        "daily leadership meetings of South Korea's two major parties",
        "(Conservative and Progressive), covering 2003 to 2022.",
        "83,201 total entries (35,115 conservative + 48,086 progressive).",
        "Parsed using the khaiii Korean morphological analyzer."
      ),
      short_description = paste(
        "Official statements from party spokespersons and leadership meetings",
        "of South Korea's two major parties (2003-2022)."
      ),
      time_coverage = "2003-2022",
      data_version = "v2022",
      n_candidates_or_entries = 83201L,
      source_url = "https://osf.io/rct9y/",
      paper_doi = "10.1038/s41597-025-05220-4",
      license = "CC BY-NC-ND 4.0",
      citation = paper_citation,
      osf_citation = osf_citation,
      identifier_columns = "id",
      text_columns = c("text", "filtered"),
      columns = list(
        .column_spec("no", "integer", "Sequential entry number within each party"),
        .column_spec("year", "integer", "Year the statement was posted"),
        .column_spec("ymd", "character", "Full date (YYYY-MM-DD)"),
        .column_spec("title", "character", "Title of the statement"),
        .column_spec("text", "character", "Full text of the statement"),
        .column_spec("filtered", "character", "Parsed text after morphological analysis; Korean-only"),
        .column_spec("partisan", "character", "Party affiliation: Progressive / Conservative"),
        .column_spec("conservative", "integer", "Binary indicator: 1 = Conservative Party, 0 = Progressive Party"),
        .column_spec("id", "character", "Unique document identifier (party prefix + entry number)", identifier = TRUE)
      ),
      notes = list(
        missing_values = "Some fields may contain NA or empty strings.",
        party_names = paste(
          "Both parties have undergone frequent name changes. The 'partisan'",
          "column uses stable ideological labels rather than party names."
        ),
        text_processing = paste(
          "All text is UTF-8 encoded Korean. 'text' contains the full",
          "original text; 'filtered' contains the morphologically parsed version."
        )
      ),
      extras = list()
    )
  )
}

#' Resolve dataset catalog entry
#' @noRd
.dataset_spec <- function(dataset, variant = NULL) {
  dataset <- match.arg(dataset, choices = names(.dataset_catalog()))
  catalog_entry <- .dataset_catalog()[[dataset]]

  if (is.null(catalog_entry$variants)) {
    if (!is.null(variant)) {
      stop("Dataset '", dataset, "' does not define variants.", call. = FALSE)
    }
    catalog_entry$variant <- NULL
    catalog_entry$default_variant <- NULL
    catalog_entry$available_variants <- character()
    return(catalog_entry)
  }

  selected_variant <- .resolve_variant(
    dataset,
    data_version = catalog_entry$data_version,
    variant = variant
  )
  variant_entry <- catalog_entry$variants[[selected_variant]]
  base_entry <- catalog_entry[setdiff(names(catalog_entry), "variants")]
  merged_entry <- utils::modifyList(base_entry, variant_entry, keep.null = TRUE)

  c(merged_entry, list(available_variants = names(catalog_entry$variants)))
}

#' Column names for a dataset
#' @noRd
.dataset_columns <- function(dataset, variant = NULL) {
  vapply(.dataset_spec(dataset, variant = variant)$columns, `[[`, character(1), "name")
}

#' Formats the package can understand for a dataset version or variant
#' @noRd
.supported_formats <- function(dataset, data_version = NULL, variant = NULL) {
  dataset <- .dataset_key(dataset)
  data_version <- .resolve_data_version(dataset, data_version)
  variant <- .resolve_variant(dataset, data_version = data_version, variant = variant)
  artifact_root <- .artifact_registry()[[dataset]]$artifacts[[data_version]]

  if (is.null(variant)) {
    return(names(artifact_root))
  }

  names(artifact_root[[variant]])
}

#' Formats with managed downloadable artifacts
#' @noRd
.managed_formats <- function(dataset, data_version = NULL, variant = NULL) {
  dataset <- .dataset_key(dataset)
  data_version <- .resolve_data_version(dataset, data_version)
  variant <- .resolve_variant(dataset, data_version = data_version, variant = variant)
  artifact_root <- .artifact_registry()[[dataset]]$artifacts[[data_version]]
  artifacts <- if (is.null(variant)) artifact_root else artifact_root[[variant]]

  names(Filter(function(x) !is.null(x$url) && nzchar(x$url), artifacts))
}

#' Package version helper
#' @noRd
.package_version_string <- function() {
  tryCatch(
    as.character(utils::packageVersion("krpoltext")),
    error = function(e) NA_character_
  )
}
