# Convert a krpoltext data.table to a quanteda corpus

Creates a
[`quanteda::corpus()`](https://quanteda.io/reference/corpus.html) object
from a `data.table` loaded by
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

  Additional arguments passed to
  [`quanteda::corpus()`](https://quanteda.io/reference/corpus.html).

## Value

A `quanteda` corpus object.

## Examples

``` r
if (FALSE) { # \dontrun{
ps <- load_party_statements()
corp <- as_quanteda_corpus(ps)

# Use a subset
ps_2020 <- get_docs("party_statements", year = 2020)
corp_2020 <- as_quanteda_corpus(ps_2020, docid_field = "id")
} # }
```
