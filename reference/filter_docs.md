# Filter an in-memory table using named column filters

Filter an in-memory table using named column filters

## Usage

``` r
filter_docs(.data, ..., .strict = TRUE)
```

## Arguments

- .data:

  A data frame or `data.table`.

- ...:

  Named filtering arguments. Values can be scalars or vectors.

- .strict:

  Logical; if `TRUE` (default), invalid filter columns raise an error.
  If `FALSE`, they are ignored with a message.

## Value

A filtered `data.table`.

## Examples

``` r
dt <- data.table::data.table(year = 2020:2022, text = letters[1:3])
filter_docs(dt, year = 2021)
#>     year   text
#>    <int> <char>
#> 1:  2021      b
```
