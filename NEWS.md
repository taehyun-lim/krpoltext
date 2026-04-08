# krpoltext 0.2.0

## Highlights

- Added managed dual-format distribution via OSF for both CSV and Parquet artifacts.
- Added format-aware loaders with local CSV/Parquet path support and explicit CSV fallback behavior.
- Added stricter document-query helpers through `get_docs(..., .select, .strict)`, `filter_docs()`, and `select_vars()`.
- Added canonical metadata and schema helpers with dataset-level format metadata.
- Added a refreshed static JSON data API with format-specific download URLs and schema outputs.
- Expanded tests and release docs for the `v0.2.0` upgrade path.

## Notes

- Parquet reading uses `arrow` when available, but `v0.2.0` does not introduce a full Arrow backend or lazy dataset workflow.
- `download_data()` remains a CSV-prefetch helper; managed Parquet artifacts are available through `load_*()` with `format = "parquet"` or the published OSF URLs.
- Dataset metadata now reflects `83,201` total party statements for `v2022`.

# krpoltext 0.1.0

Initial GitHub-distributed release of the package.

## Initial Features

- `load_campaign_booklet()` for the South Korean Election Campaign Booklet corpus
- `load_party_statements()` for the South Korean Party Statements corpus
- `download_data()` for OSF download and local caching
- `metadata()` for dataset metadata and citation information
- `get_docs()` for column-based document filtering
- `as_quanteda_corpus()` for `quanteda` conversion
- `clear_cache()` for cache cleanup

## Data References

- Data Descriptor: Lim, T.H. (2025). *Scientific Data*, 12, 1030. <https://doi.org/10.1038/s41597-025-05220-4>
- OSF Repository: <https://doi.org/10.17605/OSF.IO/RCT9Y>
