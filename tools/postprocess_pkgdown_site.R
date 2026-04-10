#!/usr/bin/env Rscript
#
# Normalize pkgdown landing pages after the site build.
# - Keep a stable README.html -> index.html redirect for legacy links.
# - Reinsert the dev-status badges at the top of the English home page.
# - Remove the source banner from README_kr.html.
# - Replace the Korean page TOC-only sidebar with the same metadata blocks
#   used on the English home page, then append the Korean page TOC.

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

html_fragment <- function(html) {
  xml2::xml_find_first(
    xml2::read_html(
      paste0("<!DOCTYPE html><html><body>", html, "</body></html>"),
      encoding = "UTF-8"
    ),
    ".//body/*"
  )
}

replace_children <- function(node, html_nodes) {
  children <- xml2::xml_children(node)
  if (length(children) > 0) {
    xml2::xml_remove(children, free = TRUE)
  }

  for (html in html_nodes) {
    xml2::xml_add_child(node, html_fragment(html))
  }
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

# Reinsert badges at the top of the English home page.
xml2::xml_remove(
  xml2::xml_find_all(index_doc, ".//main//p[contains(@class, 'pkgdown-badges')]"),
  free = TRUE
)

dev_badges <- xml2::xml_find_all(
  index_doc,
  ".//aside//*[contains(@class, 'dev-status')]//ul/li/a"
)

lang_switch <- xml2::xml_find_first(
  index_doc,
  ".//main//p[a[contains(@href, 'README_kr')]]"
)

if (length(dev_badges) > 0 && !inherits(lang_switch, "xml_missing")) {
  badges_html <- paste(as.character(dev_badges), collapse = "\n")
  badge_block <- html_fragment(
    paste0("<p class=\"pkgdown-badges\">", badges_html, "</p>")
  )
  xml2::xml_add_sibling(lang_switch, badge_block, .where = "before")
}

# Remove the Korean source banner.
xml2::xml_remove(
  xml2::xml_find_all(kr_doc, ".//small[contains(@class, 'dont-index')]"),
  free = TRUE
)

# Replace the Korean sidebar with the English metadata blocks plus the Korean TOC.
home_sidebar_sections <- xml2::xml_find_all(index_doc, ".//main/following-sibling::aside[1]/*")
home_sidebar_html <- as.character(
  home_sidebar_sections[
    !grepl("id=\"toc\"", as.character(home_sidebar_sections), fixed = TRUE)
  ]
)

kr_aside <- xml2::xml_find_first(kr_doc, ".//main/following-sibling::aside[1]")
kr_toc <- xml2::xml_find_first(kr_doc, ".//main/following-sibling::aside[1]//nav[@id='toc']")

if (!inherits(kr_aside, "xml_missing")) {
  sections <- home_sidebar_html
  if (!inherits(kr_toc, "xml_missing")) {
    sections <- c(sections, as.character(kr_toc))
  }
  replace_children(kr_aside, sections)
}

write_doc(index_doc, index_path)
write_doc(kr_doc, readme_kr_path)
ensure_readme_redirect(redirect_path)
