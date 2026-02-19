# krpoltext 0.1.0

*Initial release — MVP for GitHub distribution.*

## New Features

- `load_campaign_booklet()`: Load the South Korean Election Campaign Booklet
  corpus (49,678 candidates, 2000–2022) with caching support.
- `load_party_statements()`: Load the South Korean Party Statements corpus
  (82,723 statements, 2003–2022) with caching support.
- `download_data()`: Automatic download from OSF with SHA-256 verification.
- `metadata()`: Retrieve dataset metadata including column descriptions,
  observation counts, and citation information.
- `get_docs()`: Query and filter documents by any available column with
  dynamic column matching.
- `as_quanteda_corpus()`: Convert loaded data to a **quanteda** corpus object.
- `clear_cache()`: Clear cached RDS files.

## Data

- Data Descriptor: Lim, T.H. (2025). *Scientific Data*, 12, 1030.
  <https://doi.org/10.1038/s41597-025-05220-4>
- OSF Repository: <https://doi.org/10.17605/OSF.IO/RCT9Y>
