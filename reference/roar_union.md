# Set operations by name

`roar_union()` and `roar_intersect()` combine any number of bitmaps.
`roar_xor()` is the symmetric difference, the values in exactly one of
`x` and `y`, and `roar_andnot()` the difference, the values of `x` not
in `y`. `roar_flip()` adds the values of the range `from` to `to` that
are missing from `x` and removes those present.

## Usage

``` r
roar_union(...)

roar_intersect(...)

roar_xor(x, y)

roar_andnot(x, y)

roar_flip(x, from, to)
```

## Arguments

- ...:

  Bitmaps. `roar_union()` of none is an empty bitmap; `roar_intersect()`
  needs at least one.

- x:

  A bitmap.

- y:

  A bitmap.

- from, to:

  The first and last values of the range, both included.

## Value

A bitmap.

## See also

[zuroar-ops](https://pedrobtz.github.io/zuroar/reference/zuroar-ops.md)
for `|` and `&`;
[`roar_cardinality()`](https://pedrobtz.github.io/zuroar/reference/roar_cardinality.md)
for the size of a result without building it.

## Examples

``` r
x <- roar(c(1, 5, 9))
y <- roar(c(5, 9, 12))
roar_xor(x, y)
#> <zuroar> 2 values in [1, 12]: 1 12
roar_andnot(x, y)
#> <zuroar> 1 value in [1, 1]: 1
roar_union(x, y, roar(100))
#> <zuroar> 5 values in [1, 100]: 1 5 9 12 100
roar_intersect(x, y)
#> <zuroar> 2 values in [5, 9]: 5 9
roar_flip(x, 0, 5)
#> <zuroar> 5 values in [0, 9]: 0 2 3 4 9
```
