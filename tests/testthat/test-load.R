test_that("load functions can read local CSV files", {
  skip_if_not_installed("data.table")

  booklet_path <- tempfile(fileext = ".csv")
  booklet_dt <- data.table::data.table(
    date = "2020-04-15",
    code = "cb-1",
    party = "Example Party",
    text = "campaign text"
  )
  data.table::fwrite(booklet_dt, booklet_path)

  cb <- load_campaign_booklet(path = booklet_path, format = "csv", cache = FALSE)
  expect_s3_class(cb, "data.table")
  expect_equal(nrow(cb), 1L)
  expect_true(all(c("date", "code", "party", "text") %in% names(cb)))
  expect_false("huboid" %in% names(cb))

  enriched_booklet_path <- tempfile(fileext = ".csv")
  enriched_booklet_dt <- data.table::data.table(
    date = "2020-04-15",
    code = "cb-1",
    party = "Example Party",
    text = "campaign text",
    huboid = NA_character_,
    sg_id = NA_character_,
    sg_typecode = NA_character_,
    link_status = "not_found",
    matcher_version = "linkage-v1",
    nec_snapshot_id = "nec-v1"
  )
  data.table::fwrite(enriched_booklet_dt, enriched_booklet_path)

  cb_enriched <- load_campaign_booklet(
    path = enriched_booklet_path,
    format = "csv",
    cache = FALSE,
    variant = "enriched"
  )
  expect_true(all(c(
    "date", "code", "party", "text", "huboid", "sg_id",
    "sg_typecode", "link_status", "matcher_version", "nec_snapshot_id"
  ) %in% names(cb_enriched)))

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
    code = "cb-1",
    party = "Example Party",
    text = "campaign text"
  )
  arrow::write_parquet(as.data.frame(booklet_dt), booklet_path)

  cb <- load_campaign_booklet(path = booklet_path, format = "parquet", cache = FALSE)
  expect_s3_class(cb, "data.table")
  expect_equal(nrow(cb), 1L)
  expect_true(all(c("date", "code", "party", "text") %in% names(cb)))
  expect_false("huboid" %in% names(cb))

  enriched_booklet_path <- tempfile(fileext = ".parquet")
  enriched_booklet_dt <- data.table::data.table(
    date = "2020-04-15",
    code = "cb-1",
    party = "Example Party",
    text = "campaign text",
    huboid = NA_character_,
    sg_id = NA_character_,
    sg_typecode = NA_character_,
    link_status = "not_found",
    matcher_version = "linkage-v1",
    nec_snapshot_id = "nec-v1"
  )
  arrow::write_parquet(as.data.frame(enriched_booklet_dt), enriched_booklet_path)

  cb_enriched <- load_campaign_booklet(
    path = enriched_booklet_path,
    format = "parquet",
    cache = FALSE,
    variant = "enriched"
  )
  expect_true(all(c(
    "date", "code", "party", "text", "huboid", "sg_id",
    "sg_typecode", "link_status", "matcher_version", "nec_snapshot_id"
  ) %in% names(cb_enriched)))

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

test_that("campaign booklet managed downloads require confirmation", {
  spec <- krpoltext:::.artifact_spec(
    "campaign_booklet",
    format = "parquet",
    variant = "enriched"
  )
  prompts <- character()

  testthat::local_mocked_bindings(
    .is_interactive_session = function() TRUE,
    .ask_download_consent = function(prompt) {
      prompts <<- c(prompts, prompt)
      FALSE
    },
    .env = asNamespace("krpoltext")
  )

  expect_error(
    krpoltext:::.confirm_managed_download("campaign_booklet", spec),
    "Download cancelled"
  )
  expect_length(prompts, 1L)
  expect_match(prompts[[1]], "campaign_booklet", fixed = TRUE)
  expect_match(prompts[[1]], "variant: enriched", fixed = TRUE)
})

test_that("party statements managed downloads also require confirmation", {
  spec <- krpoltext:::.artifact_spec("party_statements", format = "csv")
  prompts <- character()

  testthat::local_mocked_bindings(
    .is_interactive_session = function() TRUE,
    .ask_download_consent = function(prompt) {
      prompts <<- c(prompts, prompt)
      FALSE
    },
    .env = asNamespace("krpoltext")
  )

  expect_error(
    krpoltext:::.confirm_managed_download("party_statements", spec)
  )
  expect_length(prompts, 1L)
  expect_match(prompts[[1]], "party_statements", fixed = TRUE)
})

test_that("load_party_statements checks consent before managed download", {
  cache_env <- krpoltext:::.krpoltext_env
  old_dir <- cache_env$cache_dir
  test_cache <- file.path(tempdir(), "krpoltext_party_statements_prompt")
  cache_env$cache_dir <- test_cache

  on.exit({
    unlink(test_cache, recursive = TRUE)
    cache_env$cache_dir <- old_dir
  })

  testthat::local_mocked_bindings(
    .is_interactive_session = function() TRUE,
    .bundled_artifact_path = function(file) "",
    .ask_download_consent = function(prompt) FALSE,
    .env = asNamespace("krpoltext")
  )

  expect_error(
    load_party_statements(format = "csv", cache = TRUE, refresh = FALSE),
    "Download cancelled"
  )
  expect_false(dir.exists(test_cache))
})

test_that("load_campaign_booklet checks consent before managed download", {
  cache_env <- krpoltext:::.krpoltext_env
  old_dir <- cache_env$cache_dir
  test_cache <- file.path(tempdir(), "krpoltext_campaign_booklet_prompt")
  cache_env$cache_dir <- test_cache

  on.exit({
    unlink(test_cache, recursive = TRUE)
    cache_env$cache_dir <- old_dir
  })

  testthat::local_mocked_bindings(
    .is_interactive_session = function() TRUE,
    .bundled_artifact_path = function(file) "",
    .ask_download_consent = function(prompt) FALSE,
    .env = asNamespace("krpoltext")
  )

  expect_error(
    load_campaign_booklet(format = "csv", cache = TRUE, refresh = FALSE),
    "Download cancelled"
  )
  expect_false(dir.exists(test_cache))
})

test_that("load functions reject invalid arguments", {
  missing_path <- tempfile(fileext = ".csv")

  expect_error(load_campaign_booklet(path = 123))
  expect_error(load_campaign_booklet(path = missing_path, format = "csv"))
  expect_error(load_campaign_booklet(data_version = 1))
  expect_error(load_campaign_booklet(data_version = "v1900"))
  expect_error(load_campaign_booklet(variant = "invalid"))
})
