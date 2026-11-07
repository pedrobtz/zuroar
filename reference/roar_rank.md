# Ordered queries

A bitmap is sorted, so it answers order questions directly.
`roar_rank()` counts the values at or below each of `values`, and
`roar_select()` returns the `k`-th smallest value, counting from 1, so
`roar_select(x, roar_rank(x, v))` is `v` for every `v` in `x`.
`roar_next()` and `roar_prev()` return the nearest value at or above, or
at or below, each of `values`, and `NA` where there is none.

## Usage

``` r
roar_rank(x, values)

roar_select(x, k)

roar_next(x, values)

roar_prev(x, values)

roar_count(x, from, to)

roar_contains_range(x, from, to)
```

## Arguments

- x:

  A bitmap.

- values:

  Whole numbers from 0 to 2^32 - 1.

- k:

  Positions, counting from 1 up to `length(x)`.

- from, to:

  The first and last values of a range, both included.

## Value

`roar_rank()` and `roar_count()` doubles, `roar_select()`, `roar_next()`
and `roar_prev()` doubles as long as their second argument,
`roar_contains_range()` a single logical.

## Details

`roar_count()` counts the values from `from` to `to`, both included, and
`roar_contains_range()` tells whether every one of them is present.

## Examples

``` r
x <- roar(c(1, 7, 9, 100000))
roar_rank(x, 9)
#> [1] 3
roar_select(x, c(1, 2))
#> [1] 1 7
roar_next(x, 8)
#> [1] 9
roar_prev(x, 8)
#> [1] 7
roar_next(x, 200000)
#> [1] NA

y <- roar_range(1, 1e6)
roar_count(y, from = 10, to = 20)
#> [1] 11
roar_contains_range(y, from = 1, to = 9)
#> [1] TRUE
```
