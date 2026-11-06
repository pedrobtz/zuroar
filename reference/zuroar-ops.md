# Operators on bitmaps

Between two bitmaps, `|` is the union and `&` the intersection, each a
new bitmap. `==` and `!=` test equality, `x <= y` whether `x` is a
subset of `y`, `x < y` whether it is a strict subset, and `>=` and `>`
the reverse; each returns a single `TRUE` or `FALSE`.

## Usage

``` r
# S3 method for class 'zuroar'
Ops(e1, e2)
```

## Arguments

- e1, e2:

  Bitmaps, or a bitmap and a single whole number.

## Value

A bitmap, or a single logical for the comparisons.

## Details

Between a bitmap and a single whole number `k`, `x + k`, `k + x` and
`x - k` shift every value by `k`, as
[`roar_shift()`](https://pedrobtz.github.io/zuroar/reference/roar_shift.md)
does. A value that would leave the domain from 0 to 2^32 - 1 is an
error; use `roar_shift(drop = TRUE)` to drop such values instead.

Everything else is a `zuroar_error_unsupported` error, because a set has
no sensible answer:

- `!x` would need a universe; use
  [`roar_flip()`](https://pedrobtz.github.io/zuroar/reference/roar_union.md)
  over a range.

- `x - y` between bitmaps: use
  [`roar_andnot()`](https://pedrobtz.github.io/zuroar/reference/roar_union.md).
  `x ^ y` means power in R; use
  [`roar_xor()`](https://pedrobtz.github.io/zuroar/reference/roar_union.md).

- `x > 5` and other comparisons with numbers would expand the set into a
  logical vector; use `x & roar_range(6, 4294967295)` or
  [`roar_contains()`](https://pedrobtz.github.io/zuroar/reference/roar_contains.md).

## Examples

``` r
x <- roar(c(1, 5, 9))
y <- roar(c(5, 9, 12))
x | y
#> <zuroar> 4 values in [1, 12]: 1 5 9 12
x & y
#> <zuroar> 2 values in [5, 9]: 5 9
x <= y
#> [1] FALSE
roar(5) < y
#> [1] TRUE
x + 10
#> <zuroar> 3 values in [11, 19]: 11 15 19
```
