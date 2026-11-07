# Positions in a bitmap

A bitmap is a sorted vector without duplicates, so its values have
positions, counting from 1. `x[i]` returns a bitmap of the values at
positions `i`, as `[` keeps the class of a `Date`: positive positions
select, negative ones exclude, and a logical `i` is a mask over
positions, recycled as R recycles one. Order and repetition in `i` do
not matter, since the result is a set. Mixing signs, `NA`, and a
position past the end are `zuroar_error_index` errors, because a bitmap
holds no `NA`.

## Usage

``` r
# S3 method for class 'zuroar'
x[i, ...]

# S3 method for class 'zuroar'
x[[k, ...]]

# S3 method for class 'zuroar'
head(x, n = 6L, ...)

# S3 method for class 'zuroar'
tail(x, n = 6L, ...)

# S3 method for class 'zuroar'
sort(x, decreasing = FALSE, ...)

# S3 method for class 'zuroar'
unique(x, incomparables = FALSE, ...)

# S3 method for class 'zuroar'
rev(x)

# S3 method for class 'zuroar'
x[i, ...] <- value

# S3 method for class 'zuroar'
x[[i, ...]] <- value

# S3 method for class 'zuroar64'
x[i, ...]

# S3 method for class 'zuroar64'
x[[k, ...]]

# S3 method for class 'zuroar64'
head(x, n = 6L, ...)

# S3 method for class 'zuroar64'
tail(x, n = 6L, ...)

# S3 method for class 'zuroar64'
sort(x, decreasing = FALSE, ...)

# S3 method for class 'zuroar64'
unique(x, incomparables = FALSE, ...)

# S3 method for class 'zuroar64'
rev(x)

# S3 method for class 'zuroar64'
x[i, ...] <- value

# S3 method for class 'zuroar64'
x[[i, ...]] <- value
```

## Arguments

- x:

  A bitmap.

- i:

  Positions: positive or negative whole numbers, or a logical mask.
  Missing, it selects every value.

- ...:

  Must be empty for `[` and `[[`; ignored otherwise.

- k:

  A single position.

- n:

  For [`head()`](https://rdrr.io/r/utils/head.html) and
  [`tail()`](https://rdrr.io/r/utils/head.html), how many values to
  keep, or, when negative, how many to drop from the other end.

- decreasing:

  Must be `FALSE`.

- incomparables:

  Ignored.

- value:

  Not used: assignment is an error.

## Value

`[`, [`head()`](https://rdrr.io/r/utils/head.html),
[`tail()`](https://rdrr.io/r/utils/head.html),
[`sort()`](https://rdrr.io/r/base/sort.html) and
[`unique()`](https://rdrr.io/r/base/unique.html) a bitmap, `[[` a single
double.

## Details

`x[[k]]` is the `k`-th smallest value as a double;
[`roar_select()`](https://pedrobtz.github.io/zuroar/reference/roar_rank.md)
is its vectorised form. [`head()`](https://rdrr.io/r/utils/head.html)
and [`tail()`](https://rdrr.io/r/utils/head.html) return bitmaps and
follow R's rules for a negative `n`.
[`sort()`](https://rdrr.io/r/base/sort.html) and
[`unique()`](https://rdrr.io/r/base/unique.html) return `x`.

`v %in% x` and `match(v, x)` work, visiting every value of `x`;
[`roar_contains()`](https://pedrobtz.github.io/zuroar/reference/roar_contains.md)
and
[`roar_rank()`](https://pedrobtz.github.io/zuroar/reference/roar_rank.md)
answer the same questions without visiting the set.

Some vector operations have no meaning for a set and are
`zuroar_error_unsupported` errors: `x[i] <- v` and `x[[k]] <- v` (use
[`roar_add()`](https://pedrobtz.github.io/zuroar/reference/roar_add.md)
and
[`roar_remove()`](https://pedrobtz.github.io/zuroar/reference/roar_add.md)),
`rev(x)` and `sort(x, decreasing = TRUE)` (use `rev(as.double(x))`).

## Examples

``` r
x <- roar(c(1, 7, 9, 100000))
x[2:3]
#> <zuroar> 2 values in [7, 9]: 7 9
x[-1]
#> <zuroar> 3 values in [7, 100000]: 7 9 100000
x[c(TRUE, FALSE)]
#> <zuroar> 2 values in [1, 9]: 1 9
x[[2]]
#> [1] 7
head(x, 2)
#> <zuroar> 2 values in [1, 7]: 1 7
tail(x, -1)
#> <zuroar> 3 values in [7, 100000]: 7 9 100000
roar_contains(x, 9)
#> [1] TRUE
```
