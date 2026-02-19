# Clear cached datasets

Removes cached RDS files created by
[`load_campaign_booklet()`](https://taehyun-lim.github.io/krpoltext/reference/load_campaign_booklet.md)
and
[`load_party_statements()`](https://taehyun-lim.github.io/krpoltext/reference/load_party_statements.md).

## Usage

``` r
clear_cache(dataset = "all")
```

## Arguments

- dataset:

  Character vector of dataset names to clear, or `"all"` to clear
  everything. Valid names: `"campaign_booklet"`, `"party_statements"`.

## Value

Invisibly, a character vector of removed file paths.

## Examples

``` r
if (FALSE) { # \dontrun{
clear_cache("all")
} # }
```
