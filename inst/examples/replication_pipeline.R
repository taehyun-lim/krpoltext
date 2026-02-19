#!/usr/bin/env Rscript
# krpoltext: Replication-Ready Pipeline
# =======================================
# Load -> Preprocess -> Tokenize -> Analyze
#
# Data Descriptor: https://doi.org/10.1038/s41597-025-05220-4
# OSF Repository:  https://osf.io/rct9y/

library(krpoltext)

# --- 1. Load data ---
ps <- load_party_statements()
cb <- load_campaign_booklet()

cat("Party statements:", nrow(ps), "docs\n")
cat("Campaign booklets:", nrow(cb), "docs\n\n")

# --- 2. Subset ---
ps_sub <- get_docs("party_statements", year = 2015:2022, .data = ps)
cb_sub <- get_docs("campaign_booklet", office = "national_assembly", .data = cb)

cat("Filtered party statements:", nrow(ps_sub), "\n")
cat("Filtered campaign booklets:", nrow(cb_sub), "\n\n")

# --- 3. Convert to quanteda corpus (requires quanteda) ---
if (requireNamespace("quanteda", quietly = TRUE)) {
  library(quanteda)

  corp_ps <- as_quanteda_corpus(ps_sub, docid_field = "id")
  cat("Corpus created:", ndoc(corp_ps), "documents\n")

  # Tokenize
  toks <- tokens(corp_ps, remove_punct = TRUE, remove_numbers = TRUE)

  # Build DFM
  dfm_obj <- dfm(toks)
  cat("DFM dimensions:", nrow(dfm_obj), "docs x", ncol(dfm_obj), "features\n")

  # Top features
  cat("\nTop 20 features:\n")
  print(topfeatures(dfm_obj, 20))

  # Group by conservative/progressive
  dfm_grouped <- dfm_group(dfm_obj, groups = docvars(dfm_obj, "conservative"))
  cat("\nTop features by group:\n")
  print(topfeatures(dfm_grouped, 10, groups = TRUE))
} else {
  cat("Install 'quanteda' for the full analysis pipeline:\n")
  cat("  install.packages('quanteda')\n")
}

cat("\nPipeline complete.\n")
cat("Cite: Lim, T.H. (2025). Sci Data, 12, 1030. doi:10.1038/s41597-025-05220-4\n")
