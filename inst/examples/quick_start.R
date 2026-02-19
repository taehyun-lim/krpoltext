#!/usr/bin/env Rscript
# krpoltext: Quick Start Example
# ================================
# Load -> Filter -> Summarize in under 5 minutes
#
# Data Descriptor: https://doi.org/10.1038/s41597-025-05220-4
# OSF Repository:  https://osf.io/rct9y/

library(krpoltext)

# --- 1. Check metadata before loading ---
meta_ps <- metadata("party_statements")
cat("Dataset:", meta_ps$name, "\n")
cat("Coverage:", meta_ps$time_coverage, "\n")
cat("Entries:", format(meta_ps$n_candidates_or_entries, big.mark = ","), "\n")
cat("Paper DOI:", meta_ps$paper_doi, "\n")
cat("Columns:", paste(meta_ps$columns, collapse = ", "), "\n\n")

# --- 2. Load the party statements corpus ---
ps <- load_party_statements()
cat("Loaded", nrow(ps), "documents\n\n")

# --- 3. Filter: 2020 statements only ---
ps_2020 <- get_docs("party_statements", year = 2020, .data = ps)
cat("2020 statements:", nrow(ps_2020), "\n")

# --- 4. Simple summary ---
cat("\nDocuments by year (last 5 years):\n")
recent <- ps[ps$year >= 2018, ]
print(table(recent$year))

cat("\nDocuments by conservative indicator:\n")
print(table(ps$conservative))

cat("\nDone!\n")
cat("Full analysis workflow: vignette('replication-pipeline')\n")
cat("Data Descriptor: https://doi.org/10.1038/s41597-025-05220-4\n")
