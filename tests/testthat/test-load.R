test_that("load_campaign_booklet returns non-empty data.table", {
  skip_if_not_installed("data.table")
  skip_if(
    system.file("extdata", "sk_election_campaign_booklet_v2022.csv",
                package = "krpoltext") == "",
    message = "Campaign booklet CSV not bundled; skipping load test."
  )

  cb <- load_campaign_booklet(cache = FALSE)
  expect_s3_class(cb, "data.table")
  expect_gt(nrow(cb), 0L)
  expect_true("text" %in% names(cb))
  expect_true("party" %in% names(cb))
  expect_true("date" %in% names(cb))
})

test_that("load_party_statements returns non-empty data.table", {
  skip_if_not_installed("data.table")
  skip_if(
    system.file("extdata", "sk_party_statements_v2022.csv",
                package = "krpoltext") == "",
    message = "Party statements CSV not bundled; skipping load test."
  )

  ps <- load_party_statements(cache = FALSE)
  expect_s3_class(ps, "data.table")
  expect_gt(nrow(ps), 0L)
  expect_true("text" %in% names(ps))
  expect_true("year" %in% names(ps))
})

test_that("load functions reject invalid arguments", {
  expect_error(load_campaign_booklet(path = 123))
  expect_error(load_campaign_booklet(path = "/nonexistent/file.csv"))
})
