test_that("cache file is created when cache = TRUE", {
  skip_if_not_installed("data.table")
  skip_if(
    system.file("extdata", "sk_party_statements_v2022.csv",
                package = "krpoltext") == "",
    message = "Party statements CSV not bundled; skipping cache test."
  )

  old_dir <- .krpoltext_env$cache_dir
  tmp <- tempdir()
  .krpoltext_env$cache_dir <- file.path(tmp, "krpoltext_test_cache")

  on.exit({
    unlink(file.path(tmp, "krpoltext_test_cache"), recursive = TRUE)
    .krpoltext_env$cache_dir <- old_dir
  })

  ps <- load_party_statements(cache = TRUE, refresh = TRUE)
  cached_file <- file.path(
    tmp, "krpoltext_test_cache",
    "sk_party_statements_v2022.rds"
  )
  expect_true(file.exists(cached_file))
  expect_gt(file.size(cached_file), 0L)
})

test_that("clear_cache removes cache files", {
  old_dir <- .krpoltext_env$cache_dir
  tmp <- tempdir()
  test_cache <- file.path(tmp, "krpoltext_clear_test")
  .krpoltext_env$cache_dir <- test_cache

  on.exit({
    unlink(test_cache, recursive = TRUE)
    .krpoltext_env$cache_dir <- old_dir
  })

  dir.create(test_cache, recursive = TRUE, showWarnings = FALSE)
  dummy_path <- file.path(test_cache, "sk_party_statements_v2022.rds")
  saveRDS(data.frame(x = 1), dummy_path)
  expect_true(file.exists(dummy_path))

  clear_cache("party_statements")
  expect_false(file.exists(dummy_path))
})

test_that("clear_cache rejects invalid dataset names", {
  expect_error(clear_cache("nonexistent"))
})
