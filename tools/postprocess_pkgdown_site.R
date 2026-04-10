#!/usr/bin/env Rscript
#
# Normalize pkgdown landing pages after the site build.
# - Keep a stable README.html -> index.html redirect for legacy links.
# - Keep English and index aligned by using index.html as the only English page.
# - Remove the source banner and sidebar/TOC from README_kr.html.

args <- commandArgs(trailingOnly = TRUE)
site_dir <- if (length(args) >= 1) args[[1]] else "docs"

if (!requireNamespace("xml2", quietly = TRUE)) {
  stop("Package 'xml2' is required.", call. = FALSE)
}

index_path <- file.path(site_dir, "index.html")
readme_kr_path <- file.path(site_dir, "README_kr.html")
redirect_path <- file.path(site_dir, "README.html")

if (!file.exists(index_path)) {
  stop("Missing pkgdown home page: ", index_path, call. = FALSE)
}
if (!file.exists(readme_kr_path)) {
  stop("Missing Korean landing page: ", readme_kr_path, call. = FALSE)
}

read_doc <- function(path) {
  xml2::read_html(path, encoding = "UTF-8")
}

write_doc <- function(doc, path) {
  xml2::write_html(doc, path, options = "format")
  message("Updated ", path)
}

ensure_readme_redirect <- function(path) {
  lines <- c(
    "<!DOCTYPE html>",
    "<html lang=\"en\">",
    "<head>",
    "  <meta charset=\"utf-8\">",
    "  <meta http-equiv=\"refresh\" content=\"0; url=index.html\">",
    "  <link rel=\"canonical\" href=\"index.html\">",
    "  <title>Redirecting to krpoltext</title>",
    "</head>",
    "<body>",
    "  <p>Redirecting to <a href=\"index.html\">krpoltext</a>.</p>",
    "</body>",
    "</html>"
  )

  writeLines(lines, path, useBytes = TRUE)
  message("Updated ", path)
}

index_doc <- read_doc(index_path)
kr_doc <- read_doc(readme_kr_path)

index_asides <- xml2::xml_find_all(index_doc, ".//aside")
index_main <- xml2::xml_find_first(index_doc, ".//main[@id='main']")

if (length(index_asides) > 0) {
  xml2::xml_remove(index_asides, free = TRUE)
}

if (!inherits(index_main, "xml_missing")) {
  xml2::xml_set_attr(index_main, "class", "col-md-12")
}

# Remove the Korean source banner.
xml2::xml_remove(
  xml2::xml_find_all(kr_doc, ".//small[contains(@class, 'dont-index')]"),
  free = TRUE
)

kr_asides <- xml2::xml_find_all(kr_doc, ".//aside")
kr_main <- xml2::xml_find_first(kr_doc, ".//main[@id='main']")

if (length(kr_asides) > 0) {
  xml2::xml_remove(kr_asides, free = TRUE)
}

if (!inherits(kr_main, "xml_missing")) {
  xml2::xml_set_attr(kr_main, "class", "col-md-12")
}

write_doc(index_doc, index_path)
write_doc(kr_doc, readme_kr_path)
ensure_readme_redirect(redirect_path)
