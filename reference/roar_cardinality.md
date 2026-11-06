# Compare sets without building them

`roar_cardinality()` counts the values the union, intersection,
symmetric difference or difference of `x` and `y` would hold, without
building that bitmap. `roar_jaccard()` is the Jaccard index, the size of
the intersection over the size of the union; it is `NaN` when both are
empty. `roar_intersects()` tells whether `x` and `y` share a value and
`roar_disjoint()` whether they share none.

## Usage

``` r
roar_cardinality(x, y, op = c("and", "or", "xor", "andnot"))

roar_jaccard(x, y)

roar_intersects(x, y)

roar_disjoint(x, y)
```

## Arguments

- x:

  A bitmap.

- y:

  A bitmap.

- op:

  The operation whose result to count: `"and"`, `"or"`, `"xor"` or
  `"andnot"`.

## Value

`roar_cardinality()` a single double, `roar_jaccard()` a single double
from 0 to 1, the others a single logical.

## Examples

``` r
x <- roar(c(1, 5, 9))
y <- roar(c(5, 9, 12))
roar_cardinality(x, y, op = "and")
#> [1] 2
roar_jaccard(x, y)
#> [1] 0.5
roar_intersects(x, y)
#> [1] TRUE
roar_disjoint(x, roar(100))
#> [1] TRUE
```
