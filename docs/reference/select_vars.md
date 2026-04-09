# Select columns from an in-memory table

Select columns from an in-memory table

## Usage

``` r
select_vars(.data, vars, .strict = TRUE)
```

## Arguments

- .data:

  A data frame or `data.table`.

- vars:

  Character vector of columns to keep.

- .strict:

  Logical; if `TRUE` (default), invalid selection columns raise an
  error. If `FALSE`, they are ignored with a message.

## Value

A `data.table` containing only the requested columns.

## Examples

``` r
dt <- data.table::data.table(year = 2020:2022, text = letters[1:3])
select_vars(dt, c("year", "text"))
#>     year   text
#>    <int> <char>
#> 1:  2020      a
#> 2:  2021      b
#> 3:  2022      c
```
