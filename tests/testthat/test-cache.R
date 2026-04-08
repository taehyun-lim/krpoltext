test_that("format-aware cache file is created when cache = TRUE", {
  skip_if_not_installed("data.table")

  cache_env <- krpoltext:::.krpoltext_env
  old_dir <- cache_env$cache_dir
  tmp <- tempdir()
  cache_env$cache_dir <- file.path(tmp, "krpoltext_test_cache")

  on.exit({
    unlink(file.path(tmp, "krpoltext_test_cache"), recursive = TRUE)
    cache_env$cache_dir <- old_dir
  })

  csv_path <- tempfile(fileext = ".csv")
  dt <- data.table::data.table(year = 2020L, text = "a", id = "ps-1")
  data.table::fwrite(dt, csv_path)

  load_party_statements(
    path = csv_path,
    format = "csv",
    cache = TRUE,
    refresh = TRUE
  )

  cached_file <- krpoltext:::cache_path("party_statements", format = "csv", data_version = "v2022")
  expect_true(file.exists(cached_file))
  expect_gt(file.size(cached_file), 0L)
})

test_that("clear_cache removes format-aware and legacy cache files", {
  cache_env <- krpoltext:::.krpoltext_env
  old_dir <- cache_env$cache_dir
  tmp <- tempdir()
  test_cache <- file.path(tmp, "krpoltext_clear_test")
  cache_env$cache_dir <- test_cache

  on.exit({
    unlink(test_cache, recursive = TRUE)
    cache_env$cache_dir <- old_dir
  })

  dir.create(test_cache, recursive = TRUE, showWarnings = FALSE)

  dummy_paths <- c(
    krpoltext:::cache_path("party_statements", format = "csv", data_version = "v2022"),
    krpoltext:::cache_path("party_statements", format = "parquet", data_version = "v2022"),
    krpoltext:::.legacy_cache_path("party_statements", data_version = "v2022")
  )

  for (dummy_path in dummy_paths) {
    saveRDS(data.frame(x = 1), dummy_path)
    expect_true(file.exists(dummy_path))
  }

  clear_cache("party_statements")

  for (dummy_path in dummy_paths) {
    expect_false(file.exists(dummy_path))
  }
})

test_that("clear_cache rejects invalid dataset names", {
  expect_error(clear_cache("nonexistent"))
})
