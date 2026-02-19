test_that("metadata returns a list with expected structure", {
  m_cb <- metadata("campaign_booklet")
  expect_type(m_cb, "list")
  expect_true(all(c("name", "description", "time_coverage", "columns",
                     "n_candidates_or_entries", "source_url", "paper_doi",
                     "citation") %in% names(m_cb)))
  expect_type(m_cb$columns, "character")
  expect_type(m_cb$n_candidates_or_entries, "integer")
  expect_match(m_cb$source_url, "osf\\.io")
  expect_match(m_cb$paper_doi, "10\\.1038")

  m_ps <- metadata("party_statements")
  expect_type(m_ps, "list")
  expect_true("year" %in% m_ps$columns)
  expect_equal(m_ps$n_candidates_or_entries, 82723L)
})

test_that("metadata rejects invalid dataset name", {
  expect_error(metadata("invalid_dataset"))
})
