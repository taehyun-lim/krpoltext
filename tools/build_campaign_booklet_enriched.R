#!/usr/bin/env Rscript

`%||%` <- function(left, right) {
  if (is.null(left) || identical(left, "")) {
    return(right)
  }
  left
}

argv <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", argv, value = TRUE)
file_value <- if (length(file_arg) > 0) file_arg[[1]] else ""
script_path <- normalizePath(
  sub("^--file=", "", file_value %||% "tools/build_campaign_booklet_enriched.R"),
  winslash = "/",
  mustWork = FALSE
)
script_dir <- dirname(script_path)
python_bin <- Sys.getenv("KRELECTIONS_MCP_PYTHON", unset = Sys.which("python"))

if (!nzchar(python_bin)) {
  stop(
    "Set KRELECTIONS_MCP_PYTHON to the kr-elections-mcp virtualenv python.exe ",
    "path, or call tools/build_campaign_booklet_enriched.py directly.",
    call. = FALSE
  )
}

py_script <- file.path(script_dir, "build_campaign_booklet_enriched_duckdb.py")
args <- commandArgs(trailingOnly = TRUE)
status <- system2(python_bin, args = c(py_script, args))

if (!identical(status, 0L)) {
  quit(save = "no", status = status)
}
