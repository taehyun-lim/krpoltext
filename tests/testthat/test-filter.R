test_that("get_docs filters party_statements by year", {
  skip_if_not_installed("data.table")
  skip_if(
    system.file("extdata", "sk_party_statements_v2022.csv",
                package = "krpoltext") == "",
    message = "Party statements CSV not bundled; skipping filter test."
  )

  ps <- load_party_statements(cache = FALSE)
  subset <- get_docs("party_statements", year = 2020, .data = ps)

  expect_s3_class(subset, "data.table")
  expect_lte(nrow(subset), nrow(ps))
  if (nrow(subset) > 0) {
    expect_true(all(subset$year == 2020))
  }
})

test_that("get_docs with non-existent column prints message and returns data", {
  skip_if_not_installed("data.table")

  dummy <- data.table::data.table(
    year = 2020:2022,
    text = c("a", "b", "c")
  )

  expect_message(
    result <- get_docs("party_statements", nonexistent_col = "x", .data = dummy),
    "ignored"
  )
  expect_equal(nrow(result), 3L)
})

test_that("get_docs returns full data when no filters supplied", {
  skip_if_not_installed("data.table")

  dummy <- data.table::data.table(year = 2020:2022, text = letters[1:3])
  result <- get_docs("party_statements", .data = dummy)
  expect_equal(nrow(result), 3L)
})
