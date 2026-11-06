# Shift every value

`roar_shift()` adds `by` to every value of `x`. `x + k` and `x - k` are
the same with `drop = FALSE`. A value that would leave the domain from 0
to 2^32 - 1 is an error unless `drop = TRUE`, which drops it.

## Usage

``` r
roar_shift(x, by, drop = FALSE)
```

## Arguments

- x:

  A bitmap.

- by:

  A single whole number, positive or negative.

- drop:

  If `TRUE`, drop values that would leave the domain instead of
  signalling an error.

## Value

A bitmap.

## Examples

``` r
x <- roar(c(0, 5, 9))
roar_shift(x, 10)
#> <zuroar> 3 values in [10, 19]: 10 15 19
roar_shift(x, -5, drop = TRUE)
#> <zuroar> 2 values in [0, 4]: 0 4
```
