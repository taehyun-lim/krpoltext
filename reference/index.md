# Package index

## Load Data

Download and load corpora from OSF in CSV or Parquet formats

- [`load_campaign_booklet()`](https://taehyun-lim.github.io/krpoltext/reference/load_campaign_booklet.md)
  : Load the South Korean Election Campaign Booklet corpus
- [`load_party_statements()`](https://taehyun-lim.github.io/krpoltext/reference/load_party_statements.md)
  : Load the South Korean Party Statements corpus
- [`download_data()`](https://taehyun-lim.github.io/krpoltext/reference/download_data.md)
  : Download krpoltext datasets from OSF

## Explore and Filter

Inspect metadata, schemas, and document filters

- [`metadata()`](https://taehyun-lim.github.io/krpoltext/reference/metadata.md)
  : Retrieve dataset metadata
- [`schema()`](https://taehyun-lim.github.io/krpoltext/reference/schema.md)
  : Retrieve dataset schema
- [`get_docs()`](https://taehyun-lim.github.io/krpoltext/reference/get_docs.md)
  : Query documents from a krpoltext corpus
- [`filter_docs()`](https://taehyun-lim.github.io/krpoltext/reference/filter_docs.md)
  : Filter an in-memory table using named column filters
- [`select_vars()`](https://taehyun-lim.github.io/krpoltext/reference/select_vars.md)
  : Select columns from an in-memory table

## Integration

Convert to other formats

- [`as_quanteda_corpus()`](https://taehyun-lim.github.io/krpoltext/reference/as_quanteda_corpus.md)
  : Convert a krpoltext data.table to a quanteda corpus

## Cache Management

- [`clear_cache()`](https://taehyun-lim.github.io/krpoltext/reference/clear_cache.md)
  : Clear cached datasets
