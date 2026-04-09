test_that("load functions can read local CSV files", {
  skip_if_not_installed("data.table")

  booklet_path <- tempfile(fileext = ".csv")
  booklet_dt <- data.table::data.table(
    date = "2020-04-15",
    party = "Example Party",
    text = "campaign text"
  )
  data.table::fwrite(booklet_dt, booklet_path)

  cb <- load_campaign_booklet(path = booklet_path, format = "csv", cache = FALSE)
  expect_s3_class(cb, "data.table")
  expect_equal(nrow(cb), 1L)
  expect_true(all(c("date", "party", "text") %in% names(cb)))

  statements_path <- tempfile(fileext = ".csv")
  statements_dt <- data.table::data.table(
    year = 2020L,
    id = "ps-1",
    text = "statement text"
  )
  data.table::fwrite(statements_dt, statements_path)

  ps <- load_party_statements(path = statements_path, format = "csv", cache = FALSE)
  expect_s3_class(ps, "data.table")
  expect_equal(nrow(ps), 1L)
  expect_true(all(c("year", "id", "text") %in% names(ps)))
})

test_that("local file paths can infer format from extension", {
  skip_if_not_installed("data.table")

  csv_path <- tempfile(fileext = ".csv")
  dt <- data.table::data.table(year = 2020L, id = "ps-1", text = "statement text")
  data.table::fwrite(dt, csv_path)

  expect_message(
    ps <- load_party_statements(path = csv_path, cache = FALSE),
    "Local file extension suggests format 'csv'"
  )
  expect_s3_class(ps, "data.table")
  expect_equal(nrow(ps), 1L)
})

test_that("load functions can read local Parquet files when arrow is installed", {
  skip_if_not_installed("data.table")
  skip_if_not_installed("arrow")

  booklet_path <- tempfile(fileext = ".parquet")
  booklet_dt <- data.table::data.table(
    date = "2020-04-15",
    party = "Example Party",
    text = "campaign text"
  )
  arrow::write_parquet(as.data.frame(booklet_dt), booklet_path)

  cb <- load_campaign_booklet(path = booklet_path, format = "parquet", cache = FALSE)
  expect_s3_class(cb, "data.table")
  expect_equal(nrow(cb), 1L)
  expect_true(all(c("date", "party", "text") %in% names(cb)))

  statements_path <- tempfile(fileext = ".parquet")
  statements_dt <- data.table::data.table(
    year = 2020L,
    id = "ps-1",
    text = "statement text"
  )
  arrow::write_parquet(as.data.frame(statements_dt), statements_path)

  ps <- load_party_statements(path = statements_path, format = "parquet", cache = FALSE)
  expect_s3_class(ps, "data.table")
  expect_equal(nrow(ps), 1L)
  expect_true(all(c("year", "id", "text") %in% names(ps)))
})

test_that("parquet requests can fall back to CSV artifacts", {
  skip_if_not_installed("data.table")

  fallback_dt <- data.table::data.table(
    year = 2020L,
    id = "ps-1",
    text = "statement text"
  )
  cache_env <- krpoltext:::.krpoltext_env
  old_dir <- cache_env$cache_dir
  test_cache <- file.path(tempdir(), "krpoltext_parquet_fallback")
  cache_env$cache_dir <- test_cache

  on.exit({
    unlink(test_cache, recursive = TRUE)
    cache_env$cache_dir <- old_dir
  })

  dir.create(test_cache, recursive = TRUE, showWarnings = FALSE)
  saveRDS(
    fallback_dt,
    krpoltext:::cache_path("party_statements", format = "csv", data_version = "v2022")
  )

  testthat::local_mocked_bindings(
    .can_read_parquet = function() FALSE,
    .env = asNamespace("krpoltext")
  )

  expect_message(
    ps <- load_party_statements(format = "parquet", cache = TRUE, refresh = FALSE),
    "falling back to CSV"
  )
  expect_s3_class(ps, "data.table")
  expect_equal(nrow(ps), 1L)
  expect_equal(ps$id[[1]], "ps-1")
})

test_that("non-interactive parquet requests can use cached CSV artifacts", {
  skip_if_not_installed("data.table")

  fallback_dt <- data.table::data.table(
    year = 2020L,
    id = "ps-1",
    text = "statement text"
  )
  cache_env <- krpoltext:::.krpoltext_env
  old_dir <- cache_env$cache_dir
  test_cache <- file.path(tempdir(), "krpoltext_noninteractive_csv_cache")
  cache_env$cache_dir <- test_cache

  on.exit({
    unlink(test_cache, recursive = TRUE)
    cache_env$cache_dir <- old_dir
  })

  dir.create(test_cache, recursive = TRUE, showWarnings = FALSE)
  saveRDS(
    fallback_dt,
    krpoltext:::cache_path("party_statements", format = "csv", data_version = "v2022")
  )

  testthat::local_mocked_bindings(
    .can_read_parquet = function() TRUE,
    .env = asNamespace("krpoltext")
  )

  expect_message(
    ps <- load_party_statements(format = "parquet", cache = TRUE, refresh = FALSE),
    "trying the next available format"
  )
  expect_s3_class(ps, "data.table")
  expect_equal(nrow(ps), 1L)
  expect_equal(ps$id[[1]], "ps-1")
})

test_that("managed downloads are blocked in non-interactive load paths", {
  cache_env <- krpoltext:::.krpoltext_env
  old_dir <- cache_env$cache_dir
  test_cache <- file.path(tempdir(), "krpoltext_noninteractive_download_block")
  cache_env$cache_dir <- test_cache

  on.exit({
    unlink(test_cache, recursive = TRUE)
    cache_env$cache_dir <- old_dir
  })

  expect_error(
    load_party_statements(format = "csv", cache = TRUE, refresh = FALSE),
    "non-interactive sessions"
  )
  expect_false(dir.exists(test_cache))
})

test_that("managed download messages include the artifact format", {
  msg <- krpoltext:::.managed_download_message("party_statements", "parquet")

  expect_match(msg, "managed Parquet artifact", fixed = TRUE)
  expect_match(msg, "prefetch the CSV cache explicitly", fixed = TRUE)
})

test_that("load functions reject invalid arguments", {
  missing_path <- tempfile(fileext = ".csv")

  expect_error(load_campaign_booklet(path = 123))
  expect_error(load_campaign_booklet(path = missing_path, format = "csv"))
  expect_error(load_campaign_booklet(data_version = 1))
  expect_error(load_campaign_booklet(data_version = "v1900"))
})
