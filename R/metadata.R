#' Retrieve dataset metadata
#'
#' Returns a list of metadata about the specified corpus, including its name,
#' description, time coverage, column names, observation count, and citation
#' information.
#'
#' @param dataset Character; which dataset to describe. One of
#'   `"campaign_booklet"` or `"party_statements"`.
#'
#' @return A named list with elements:
#' \describe{
#'   \item{name}{Human-readable dataset name.}
#'   \item{description}{Brief description.}
#'   \item{time_coverage}{Temporal coverage (YYYY-YYYY).}
#'   \item{columns}{Character vector of column names.}
#'   \item{n_candidates_or_entries}{Number of unique candidates or entries
#'     as reported in the Data Descriptor.}
#'   \item{source_url}{OSF repository URL.}
#'   \item{paper_doi}{DOI of the Data Descriptor in \emph{Scientific Data}.}
#'   \item{citation}{Suggested citation string.}
#' }
#'
#' @export
#' @examples
#' metadata("campaign_booklet")
#' metadata("party_statements")
metadata <- function(dataset = c("campaign_booklet", "party_statements")) {
  dataset <- match.arg(dataset)

  paper_citation <- paste(
    "Lim, T.H. (2025). South Korean Election Campaign Booklet and",
    "Party Statements Corpora. Scientific Data, 12, 1030.",
    "https://doi.org/10.1038/s41597-025-05220-4"
  )

  meta <- list(
    campaign_booklet = list(
      name = "South Korean Election Campaign Booklets",
      description = paste(
        "Official campaign booklets (manifesto booklets) filed by 49,678",
        "individual candidates in South Korean presidential, National Assembly,",
        "and local elections from 2000 to 2022. Text extracted via OCR and",
        "parsed using the khaiii Korean morphological analyzer."
      ),
      time_coverage = "2000-2022",
      columns = c(
        "date", "name", "region", "district", "office_id", "office",
        "giho", "party", "party_eng", "result", "sex", "birthday", "age",
        "job_id", "job", "job_name", "job_name_eng", "job_code",
        "edu_id", "edu", "edu_name", "edu_name_eng", "edu_code",
        "career1", "career2", "pages", "code", "sex_code",
        "result_code", "text", "filtered"
      ),
      n_candidates_or_entries = 49678L,
      source_url = "https://osf.io/rct9y/",
      paper_doi = "10.1038/s41597-025-05220-4",
      citation = paper_citation
    ),
    party_statements = list(
      name = "South Korean Party Statements",
      description = paste(
        "Official statements from party spokespersons and minutes from",
        "daily leadership meetings of South Korea's two major parties",
        "(Conservative and Progressive), covering 2003 to 2022.",
        "82,723 total entries (35,115 conservative + 42,335 progressive).",
        "Parsed using the khaiii Korean morphological analyzer."
      ),
      time_coverage = "2003-2022",
      columns = c(
        "no", "year", "ymd", "title", "text", "filtered",
        "partisan", "conservative", "id"
      ),
      n_candidates_or_entries = 82723L,
      source_url = "https://osf.io/rct9y/",
      paper_doi = "10.1038/s41597-025-05220-4",
      citation = paper_citation
    )
  )

  meta[[dataset]]
}
