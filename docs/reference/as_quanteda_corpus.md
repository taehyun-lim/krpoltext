# Convert a krpoltext data.table to a quanteda corpus

Creates a `quanteda::corpus()` object from a `data.table` loaded by
[`load_campaign_booklet()`](https://taehyun-lim.github.io/krpoltext/reference/load_campaign_booklet.md)
or
[`load_party_statements()`](https://taehyun-lim.github.io/krpoltext/reference/load_party_statements.md).
The `text` column is used as the document text; all other columns become
document-level variables (docvars).

## Usage

``` r
as_quanteda_corpus(x, text_field = "text", docid_field = NULL, ...)
```

## Arguments

- x:

  A `data.table` (or `data.frame`) with at least a `text` column.

- text_field:

  Character; name of the column containing document text. Defaults to
  `"text"`.

- docid_field:

  Character or `NULL`; name of the column to use as document IDs. If
  `NULL`, row numbers are used.

- ...:

  Additional arguments passed to `quanteda::corpus()`.

## Value

A `quanteda` corpus object.

## Examples

``` r
if (requireNamespace("quanteda", quietly = TRUE)) {
  dt <- data.table::data.table(
    id = c("doc-1", "doc-2"),
    text = c("first text", "second text"),
    year = c(2020L, 2021L)
  )

  corp <- as_quanteda_corpus(dt, docid_field = "id")
  corp
}
```
