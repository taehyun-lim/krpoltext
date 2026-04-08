test_that("download_data refuses uncached downloads in non-interactive sessions", {
  cache_env <- krpoltext:::.krpoltext_env
  old_dir <- cache_env$cache_dir
  test_cache <- file.path(tempdir(), "krpoltext_download_guard")
  cache_env$cache_dir <- test_cache

  on.exit({
    unlink(test_cache, recursive = TRUE)
    cache_env$cache_dir <- old_dir
  })

  expect_error(
    download_data("party_statements"),
    "non-interactive sessions"
  )
  expect_false(dir.exists(test_cache))
})
