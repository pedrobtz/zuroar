# Test membership

`roar_contains()` tells, for each of `values`, whether `x` holds it. It
is the fast form of `values %in% x`, which works too but visits every
value of `x`.

## Usage

``` r
roar_contains(x, values)
```

## Arguments

- x:

  A bitmap.

- values:

  Whole numbers from 0 to 2^32 - 1; for a `zuroar64`, decimal text or
  doubles below 2^53.

## Value

A logical vector as long as `values`.

## Examples

``` r
x <- roar(c(1, 5, 9))
roar_contains(x, c(5, 6))
#> [1]  TRUE FALSE
```
