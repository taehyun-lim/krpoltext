#!/usr/bin/env Rscript
#
# Normalize pkgdown landing pages after the site build.
# - Keep a stable README.html -> index.html redirect for legacy links.
# - Keep English and index aligned by using index.html as the only English page.
# - Remove the source banner from README_kr.html.
# - Keep the top badge block aligned across English and Korean pages.
# - Normalize both sidebars to the same block order.
# - Normalize TOC heading text to "Table of Contents".

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

content_section <- function(doc) {
  main <- xml2::xml_find_first(doc, ".//main[@id='main']")
  if (inherits(main, "xml_missing")) {
    return(main)
  }

  direct_sections <- xml2::xml_find_all(
    main,
    "./*[contains(concat(' ', normalize-space(@class), ' '), ' section ')]"
  )

  if (length(direct_sections) >= 1) {
    return(direct_sections[[1]])
  }

  xml2::xml_find_first(main, ".//*[contains(concat(' ', normalize-space(@class), ' '), ' section ')]")
}

badge_block_html <- function(doc) {
  badge_links <- xml2::xml_find_all(doc, ".//div[contains(@class, 'dev-status')]//a")

  if (length(badge_links) == 0) {
    return(character())
  }

  badge_hrefs <- xml2::xml_attr(badge_links, "href")
  badge_links <- badge_links[!duplicated(badge_hrefs)]

  paste0("<p>", paste(as.character(badge_links), collapse = " "), "</p>")
}

normalize_top_badges <- function(doc, badge_html) {
  if (!length(badge_html)) {
    return(invisible(NULL))
  }

  section <- content_section(doc)
  if (inherits(section, "xml_missing")) {
    return(invisible(NULL))
  }

  existing_badges <- xml2::xml_find_all(section, "./p[.//img]")
  if (length(existing_badges) > 0) {
    xml2::xml_remove(existing_badges, free = TRUE)
  }

  first_paragraph <- xml2::xml_find_first(section, "./p")

  if (!inherits(first_paragraph, "xml_missing")) {
    xml2::xml_add_sibling(first_paragraph, html_fragment(badge_html), .where = "before")
  } else {
    xml2::xml_add_child(section, html_fragment(badge_html))
  }
}

reorder_sidebar <- function(doc) {
  aside <- xml2::xml_find_first(doc, ".//aside")
  if (inherits(aside, "xml_missing")) {
    return(invisible(NULL))
  }

  panels <- xml2::xml_find_all(aside, "./div")
  if (length(panels) == 0) {
    return(invisible(NULL))
  }

  order <- c("links", "license", "citation", "developers", "dev-status", "table-of-contents")
  panel_classes <- vapply(
    panels,
    function(panel) xml2::xml_attr(panel, "class", default = ""),
    character(1)
  )

  ordered_html <- character()
  used <- rep(FALSE, length(panels))

  for (panel_name in order) {
    matches <- grepl(
      paste0("(^|\\s)", panel_name, "(\\s|$)"),
      panel_classes
    )

    if (any(matches)) {
      first_match <- which(matches)[[1]]
      ordered_html <- c(ordered_html, as.character(panels[[first_match]]))
      used[[first_match]] <- TRUE
    }
  }

  matched_known_panel <- vapply(
    panel_classes,
    function(class_name) any(vapply(
      order,
      function(panel_name) grepl(paste0("(^|\\s)", panel_name, "(\\s|$)"), class_name),
      logical(1)
    )),
    logical(1)
  )
  leftovers <- !used & !matched_known_panel

  if (any(leftovers)) {
    ordered_html <- c(ordered_html, as.character(panels[leftovers]))
  }

  replace_children(aside, ordered_html)
}

set_toc_title <- function(doc) {
  toc_titles <- xml2::xml_find_all(
    doc,
    ".//div[contains(@class, 'table-of-contents')]/h2 | .//nav[@id='toc']/h2"
  )

  if (length(toc_titles) > 0) {
    for (toc_title in toc_titles) {
      xml2::xml_set_text(toc_title, "Table of Contents")
    }
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
badge_html <- badge_block_html(index_doc)
if (!length(badge_html)) {
  badge_html <- badge_block_html(kr_doc)
}

index_main <- xml2::xml_find_first(index_doc, ".//main[@id='main']")
index_aside <- xml2::xml_find_first(index_doc, ".//aside")

if (!inherits(index_main, "xml_missing")) {
  xml2::xml_set_attr(index_main, "class", "col-md-9")
}

# Remove the Korean source banner.
xml2::xml_remove(
  xml2::xml_find_all(kr_doc, ".//small[contains(@class, 'dont-index')]"),
  free = TRUE
)

kr_main <- xml2::xml_find_first(kr_doc, ".//main[@id='main']")
kr_aside <- xml2::xml_find_first(kr_doc, ".//aside")

if (!inherits(kr_main, "xml_missing")) {
  xml2::xml_set_attr(kr_main, "class", "col-md-9")
}

if (!inherits(kr_aside, "xml_missing")) {
  xml2::xml_set_attr(kr_aside, "class", "col-md-3")
}

if (!inherits(index_aside, "xml_missing") && !inherits(kr_aside, "xml_missing")) {
  replace_children(kr_aside, as.character(xml2::xml_children(index_aside)))
}

normalize_top_badges(index_doc, badge_html)
normalize_top_badges(kr_doc, badge_html)
reorder_sidebar(index_doc)
reorder_sidebar(kr_doc)
set_toc_title(index_doc)
set_toc_title(kr_doc)

write_doc(index_doc, index_path)
write_doc(kr_doc, readme_kr_path)
ensure_readme_redirect(redirect_path)
