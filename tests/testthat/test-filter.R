test_that("get_docs filters rows from in-memory data", {
  skip_if_not_installed("data.table")

  dummy <- data.table::data.table(
    year = c(2020L, 2021L, 2020L),
    conservative = c(1L, 0L, 1L),
    text = c("a", "b", "c")
  )

  result <- get_docs("party_statements", year = 2020L, .data = dummy)

  expect_s3_class(result, "data.table")
  expect_equal(nrow(result), 2L)
  expect_true(all(result$year == 2020L))
})

test_that("get_docs keeps backward-compatible non-strict filter behavior", {
  skip_if_not_installed("data.table")

  dummy <- data.table::data.table(
    year = 2020:2022,
    text = c("a", "b", "c")
  )

  expect_message(
    result <- get_docs("party_statements", nonexistent_col = "x", .data = dummy),
    "Unknown filter"
  )
  expect_equal(nrow(result), 3L)
})

test_that("get_docs supports strict mode and column selection", {
  skip_if_not_installed("data.table")

  dummy <- data.table::data.table(
    year = c(2020L, 2021L, 2020L),
    title = c("x", "y", "z"),
    text = c("a", "b", "c")
  )

  expect_error(
    get_docs("party_statements", nope = "x", .data = dummy, .strict = TRUE),
    "Unknown filter"
  )

  selected <- get_docs(
    "party_statements",
    year = 2020L,
    .data = dummy,
    .select = c("year", "text"),
    .strict = TRUE
  )

  expect_equal(names(selected), c("year", "text"))
  expect_equal(nrow(selected), 2L)
})

test_that("select_vars handles strict and non-strict selection", {
  skip_if_not_installed("data.table")

  dummy <- data.table::data.table(
    year = 2020:2022,
    title = letters[1:3],
    text = LETTERS[1:3]
  )

  expect_equal(names(select_vars(dummy, c("title", "text"))), c("title", "text"))

  expect_message(
    result <- select_vars(dummy, c("title", "missing"), .strict = FALSE),
    "Unknown selected column"
  )
  expect_equal(names(result), "title")

  expect_error(
    select_vars(dummy, c("title", "missing"), .strict = TRUE),
    "Unknown selected column"
  )
})

test_that("filter_docs validates named filters in strict and non-strict modes", {
  skip_if_not_installed("data.table")

  dummy <- data.table::data.table(
    year = c(2020L, 2021L, 2020L),
    text = c("a", "b", "c")
  )

  filtered <- filter_docs(dummy, year = 2020L)
  expect_equal(nrow(filtered), 2L)

  expect_error(
    filter_docs(dummy, missing = "x", .strict = TRUE),
    "Unknown filter"
  )

  expect_message(
    result <- filter_docs(dummy, missing = "x", .strict = FALSE),
    "Unknown filter"
  )
  expect_equal(nrow(result), 3L)
})

test_that("filter_docs rejects unnamed filters and select_vars checks vars type", {
  skip_if_not_installed("data.table")

  dummy <- data.table::data.table(year = 2020:2022, text = letters[1:3])

  expect_error(
    filter_docs(dummy, 2020L),
    "must be named"
  )

  expect_error(
    select_vars(dummy, 1:2),
    "`vars` must be a character vector"
  )
})
