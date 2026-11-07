# Extract a bounded number of values

`roar_values()` returns at most `n` values of `x`, starting with the
smallest at or above `from`. Unlike
[`as.double()`](https://rdrr.io/r/base/double.html), it never builds
more than `n` values, so it is the way to look at part of a large
bitmap.

## Usage

``` r
roar_values(x, from = 0, n, type = c("double", "integer", "character"))
```

## Arguments

- x:

  A bitmap.

- from:

  The smallest value to consider.

- n:

  The most values to return: a whole number, or `Inf` for all.

- type:

  `"double"`, the default for a `zuroar`, or `"integer"`, which is an
  error when a returned value is above `.Machine$integer.max`. For a
  `zuroar64`, `"character"`, the default, gives decimal text; `"double"`
  is an error at or above 2^53.

## Value

A double or integer vector of at most `n` values.

## Examples

``` r
y <- roar_range(1, 1e6)
roar_values(y, from = 500, n = 5)
#> [1] 500 501 502 503 504
roar_values(y, n = 3, type = "integer")
#> [1] 1 2 3
```
