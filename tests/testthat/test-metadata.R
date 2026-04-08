test_that("metadata returns dataset-level package-facing information", {
  m_cb <- metadata("campaign_booklet")

  expect_type(m_cb, "list")
  expect_true(all(c(
    "name", "description", "time_coverage", "columns",
    "n_candidates_or_entries", "data_version", "identifier_columns",
    "text_columns", "supported_formats", "managed_formats",
    "source_url", "paper_doi", "license", "citation", "notes"
  ) %in% names(m_cb)))
  expect_type(m_cb$columns, "character")
  expect_type(m_cb$n_candidates_or_entries, "integer")
  expect_match(m_cb$data_version, "^v")
  expect_match(m_cb$source_url, "osf\\.io")
  expect_match(m_cb$paper_doi, "10\\.1038")
  expect_true("code" %in% m_cb$identifier_columns)
  expect_true(all(c("csv", "parquet") %in% m_cb$supported_formats))
  expect_true(all(c("csv", "parquet") %in% m_cb$managed_formats))

  m_ps <- metadata("party_statements")
  expect_true("year" %in% m_ps$columns)
  expect_equal(m_ps$n_candidates_or_entries, 83201L)
  expect_true("id" %in% m_ps$identifier_columns)
})

test_that("schema returns column definitions aligned with metadata", {
  s_cb <- schema("campaign_booklet")
  m_cb <- metadata("campaign_booklet")

  expect_type(s_cb, "list")
  expect_true(all(c(
    "dataset", "name", "description", "time_coverage", "data_version",
    "identifier_columns", "text_columns", "supported_formats",
    "managed_formats", "artifacts", "columns", "notes", "extras"
  ) %in% names(s_cb)))
  expect_equal(
    vapply(s_cb$columns, `[[`, character(1), "name"),
    m_cb$columns
  )
  expect_true(all(vapply(s_cb$columns, function(x) all(c("name", "type", "description") %in% names(x)), logical(1))))
  expect_true("office_mapping" %in% names(s_cb$extras))

  s_ps <- schema("party_statements")
  expect_equal(s_ps$dataset, "party_statements")
  expect_equal(
    vapply(s_ps$columns, `[[`, character(1), "name"),
    metadata("party_statements")$columns
  )
  expect_true(all(c("csv", "parquet") %in% names(s_ps$artifacts)))
  expect_true(isTRUE(s_ps$artifacts$csv$managed))
  expect_true(isTRUE(s_ps$artifacts$parquet$managed))
})

test_that("metadata and schema reject invalid dataset names", {
  expect_error(metadata("invalid_dataset"))
  expect_error(schema("invalid_dataset"))
})
