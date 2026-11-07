# The exact size of a 64-bit bitmap

`roar64_length()` returns the number of values in `x` as decimal text,
exact for every bitmap, including one holding all 2^64 values, where
[`length()`](https://rdrr.io/r/base/length.html) is an error because a
double above 2^53 is not exact.

## Usage

``` r
roar64_length(x)
```

## Arguments

- x:

  A `zuroar64`.

## Value

A single string.

## Examples

``` r
roar64_length(roar64(c("1", "2")))
#> [1] "2"
roar64_length(roar64_range("0", "1099511627775"))
#> [1] "1099511627776"
```
