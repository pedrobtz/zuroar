# Add or remove values

`roar_add()` returns a copy of `x` with `values` added and
`roar_remove()` one with `values` removed. Neither changes `x`: like
every zuroar function, they return a new bitmap. The copy shares
CRoaring's containers with `x` until it changes them, so adding one
value to a large bitmap does not copy it.

## Usage

``` r
roar_add(x, values)

roar_remove(x, values)
```

## Arguments

- x:

  A bitmap.

- values:

  Whole numbers from 0 to 2^32 - 1, as an integer or double vector.
  `NA`, negative and fractional values are errors. A logical vector is
  an error too: use [`which()`](https://rdrr.io/r/base/which.html) to
  turn one into positions.

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
```
