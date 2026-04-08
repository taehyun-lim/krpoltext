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

  list(
    campaign_booklet = list(
      name = "South Korean Election Campaign Booklets",
      description = paste(
        "Official campaign booklets (manifesto booklets) filed by 49,678",
        "individual candidates in South Korean presidential, National Assembly,",
        "and local elections from 2000 to 2022. Text extracted via OCR and",
        "parsed using the khaiii Korean morphological analyzer."
      ),
      short_description = paste(
        "Official campaign booklets from 49,678 candidates in presidential,",
        "National Assembly, and local elections (2000-2022)."
      ),
      time_coverage = "2000-2022",
      data_version = "v2022",
      n_candidates_or_entries = 49678L,
      source_url = "https://osf.io/rct9y/",
      paper_doi = "10.1038/s41597-025-05220-4",
      license = "CC BY-NC-ND 4.0",
      citation = paper_citation,
      osf_citation = osf_citation,
      identifier_columns = "code",
      text_columns = c("text", "filtered"),
      columns = list(
        .column_spec("date", "character", "Election date (YYYY-MM-DD)"),
        .column_spec("name", "character", "Candidate name (Korean)"),
        .column_spec("region", "character", "Metropolitan region (province or metropolitan city)"),
        .column_spec("district", "character", "Electoral district"),
        .column_spec(
          "office_id",
          "integer",
          paste(
            "Office type identifier (1=president, 2=national_assembly,",
            "3=edu_superintendent, 4=metro_head, 5=metro_assembly,",
            "6=basic_head, 7=basic_assembly)"
          )
        ),
        .column_spec(
          "office",
          "character",
          paste(
            "Office type label (president, national_assembly,",
            "edu_superintendent, metro_head, metro_assembly,",
            "basic_head, basic_assembly)"
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
        .column_spec("code", "character", "Unique document identifier", identifier = TRUE),
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
      ),
      notes = list(
        missing_values = paste(
          "2,283 candidates lack a booklet; 151 are missing biographical",
          "information. 23 booklets were unprocessable."
        ),
        identifiers = paste(
          "'code' uniquely identifies each document. 'job_id' and 'edu_id'",
          "vary across election years; use 'job_code' and 'edu_code' for",
          "cross-year analysis."
        ),
        text_processing = paste(
          "All text is UTF-8 encoded Korean. 'text' contains the full",
          "original text; 'filtered' contains the morphologically parsed version."
        )
      ),
      extras = list(
        office_mapping = list(
          list(office_id = 1L, office = "president", description = "Presidential election"),
          list(office_id = 2L, office = "national_assembly", description = "National Assembly election"),
          list(office_id = 3L, office = "edu_superintendent", description = "Education superintendent"),
          list(office_id = 4L, office = "metro_head", description = "Metropolitan city mayor / provincial governor"),
          list(office_id = 5L, office = "metro_assembly", description = "Metropolitan assembly member"),
          list(office_id = 6L, office = "basic_head", description = "Basic local government head"),
          list(office_id = 7L, office = "basic_assembly", description = "Basic assembly member")
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
.dataset_spec <- function(dataset) {
  dataset <- match.arg(dataset, choices = names(.dataset_catalog()))
  .dataset_catalog()[[dataset]]
}

#' Column names for a dataset
#' @noRd
.dataset_columns <- function(dataset) {
  vapply(.dataset_spec(dataset)$columns, `[[`, character(1), "name")
}

#' Formats the package can understand for a dataset version
#' @noRd
.supported_formats <- function(dataset, data_version = NULL) {
  dataset <- .dataset_key(dataset)
  data_version <- .resolve_data_version(dataset, data_version)
  names(.artifact_registry()[[dataset]]$artifacts[[data_version]])
}

#' Formats with managed downloadable artifacts
#' @noRd
.managed_formats <- function(dataset, data_version = NULL) {
  dataset <- .dataset_key(dataset)
  data_version <- .resolve_data_version(dataset, data_version)
  artifacts <- .artifact_registry()[[dataset]]$artifacts[[data_version]]
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
