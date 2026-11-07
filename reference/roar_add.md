# Add or remove values

`roar_add()` returns a copy of `x` with values added and `roar_remove()`
one with values removed: either the `values` given, or every whole
number from `from` to `to`, both included. Neither changes `x`: like
every zuroar function, they return a new bitmap. The copy shares
CRoaring's containers with `x` until it changes them, so adding one
value to a large bitmap does not copy it.

## Usage

``` r
roar_add(x, values, from, to)

roar_remove(x, values, from, to)
```

## Arguments

- x:

  A bitmap.

- values:

  Whole numbers from 0 to 2^32 - 1, as an integer or double vector.
  `NA`, negative and fractional values are errors. A logical vector is
  an error too: use [`which()`](https://rdrr.io/r/base/which.html) to
  turn one into positions.

- from, to:

  Instead of `values`, the first and last values of a range, both
  included.

## Value

A bitmap.

## Examples

``` r
x <- roar(c(1, 5, 9))
roar_add(x, 7)
#> <zuroar> 4 values in [1, 9]: 1 5 7 9
roar_remove(x, 5)
#> <zuroar> 2 values in [1, 9]: 1 9
x
#> <zuroar> 3 values in [1, 9]: 1 5 9

y <- roar_range(1, 100)
roar_remove(y, from = 10, to = 89)
#> <zuroar> 20 values in [1, 100]: 1 2 3 4 5 6 7 8 9 90 ...
```
