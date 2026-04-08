#!/usr/bin/env Rscript
#
# Build a Parquet artifact from a canonical CSV source and print
# the metadata needed for `krpoltext` registry updates.
#
# Usage:
#   Rscript tools/build_parquet_artifacts.R input.csv output.parquet [dataset]
#
# Notes:
# - Requires `data.table` and `arrow`
# - Uses snappy compression by default
# - Validates row count, column count, and column order after export

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 2L || length(args) > 3L) {
  stop(
    "Usage: Rscript tools/build_parquet_artifacts.R input.csv output.parquet [dataset]",
    call. = FALSE
  )
}

input_csv <- normalizePath(args[[1]], winslash = "/", mustWork = TRUE)
output_parquet <- args[[2]]
dataset <- if (length(args) >= 3L) args[[3]] else tools::file_path_sans_ext(basename(input_csv))
compression <- Sys.getenv("KRPOLTEXT_PARQUET_COMPRESSION", unset = "snappy")

if (!requireNamespace("data.table", quietly = TRUE)) {
  stop("Package 'data.table' is required.", call. = FALSE)
}
if (!requireNamespace("arrow", quietly = TRUE)) {
  stop("Package 'arrow' is required.", call. = FALSE)
}

sha256_file <- function(path) {
  if (requireNamespace("digest", quietly = TRUE)) {
    return(digest::digest(file = path, algo = "sha256"))
  }

  NA_character_
}

cat("Reading CSV: ", input_csv, "\n", sep = "")
dt_csv <- data.table::fread(input_csv, encoding = "UTF-8")

dir.create(dirname(output_parquet), recursive = TRUE, showWarnings = FALSE)
cat("Writing Parquet: ", output_parquet, "\n", sep = "")
arrow::write_parquet(dt_csv, sink = output_parquet, compression = compression)

cat("Validating roundtrip\n")
dt_parquet <- data.table::as.data.table(
  arrow::read_parquet(output_parquet, as_data_frame = TRUE)
)

if (!identical(names(dt_csv), names(dt_parquet))) {
  stop("Column names or column order changed during Parquet export.", call. = FALSE)
}
if (nrow(dt_csv) != nrow(dt_parquet)) {
  stop("Row count mismatch after Parquet export.", call. = FALSE)
}
if (ncol(dt_csv) != ncol(dt_parquet)) {
  stop("Column count mismatch after Parquet export.", call. = FALSE)
}

output_info <- file.info(output_parquet)
sha256 <- sha256_file(output_parquet)

cat("\nArtifact summary\n")
cat("dataset: ", dataset, "\n", sep = "")
cat("file: ", basename(output_parquet), "\n", sep = "")
cat("compression: ", compression, "\n", sep = "")
cat("rows: ", format(nrow(dt_parquet), big.mark = ","), "\n", sep = "")
cat("cols: ", ncol(dt_parquet), "\n", sep = "")
cat("size_bytes: ", format(output_info$size, scientific = FALSE, trim = TRUE), "\n", sep = "")
cat("sha256: ", sha256, "\n", sep = "")

cat("\nRegistry snippet\n")
cat("parquet = list(\n")
cat("  file = \"", basename(output_parquet), "\",\n", sep = "")
cat("  url = NULL,\n")
cat("  sha256 = ", if (is.na(sha256)) "NULL" else paste0("\"", sha256, "\""), ",\n", sep = "")
cat("  size_bytes = ", format(output_info$size, scientific = FALSE, trim = TRUE), "\n", sep = "")
cat(")\n")