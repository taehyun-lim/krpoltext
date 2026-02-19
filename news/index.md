# Changelog

## krpoltext 0.1.0

*Initial release — MVP for GitHub distribution.*

### New Features

- [`load_campaign_booklet()`](https://taehyun-lim.github.io/krpoltext/reference/load_campaign_booklet.md):
  Load the South Korean Election Campaign Booklet corpus (49,678
  candidates, 2000–2022) with caching support.
- [`load_party_statements()`](https://taehyun-lim.github.io/krpoltext/reference/load_party_statements.md):
  Load the South Korean Party Statements corpus (82,723 statements,
  2003–2022) with caching support.
- [`download_data()`](https://taehyun-lim.github.io/krpoltext/reference/download_data.md):
  Automatic download from OSF with SHA-256 verification.
- [`metadata()`](https://taehyun-lim.github.io/krpoltext/reference/metadata.md):
  Retrieve dataset metadata including column descriptions, observation
  counts, and citation information.
- [`get_docs()`](https://taehyun-lim.github.io/krpoltext/reference/get_docs.md):
  Query and filter documents by any available column with dynamic column
  matching.
- [`as_quanteda_corpus()`](https://taehyun-lim.github.io/krpoltext/reference/as_quanteda_corpus.md):
  Convert loaded data to a **quanteda** corpus object.
- [`clear_cache()`](https://taehyun-lim.github.io/krpoltext/reference/clear_cache.md):
  Clear cached RDS files.

### Data

- Data Descriptor: Lim, T.H. (2025). *Scientific Data*, 12, 1030.
  <https://doi.org/10.1038/s41597-025-05220-4>
- OSF Repository: <https://doi.org/10.17605/OSF.IO/RCT9Y>
