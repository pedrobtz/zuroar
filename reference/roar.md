# Build a bitmap

`roar()` builds a 32-bit bitmap from whole numbers between 0 and 2^32 -
1, in any order and with or without duplicates. `roar_range()` builds
one holding every whole number from `from` to `to`, both included, as
[`seq()`](https://rdrr.io/r/base/seq.html) does.

## Usage

``` r
roar(values = integer(), optimize = TRUE)

roar_range(from, to)
```

## Arguments

- values:

  Whole numbers from 0 to 2^32 - 1, as an integer or double vector.
  `NA`, negative and fractional values are errors. A logical vector is
  an error too: use [`which()`](https://rdrr.io/r/base/which.html) to
  turn one into positions.

- optimize:

  If `TRUE`, the default, use run-length containers where they are
  smaller, and release spare capacity.

- from, to:

  The first and last values of the range, both included. `from` must not
  be larger than `to`.

## Value

A bitmap, an object of class `zuroar`.

## Details

A bitmap is a compressed set: it stores each value once, in increasing
order, and answers [`length()`](https://rdrr.io/r/base/length.html),
[`min()`](https://rdrr.io/r/base/Extremes.html),
[`max()`](https://rdrr.io/r/base/Extremes.html) and
[`roar_contains()`](https://pedrobtz.github.io/zuroar/reference/roar_contains.md)
without expanding into a vector.
[`as.integer()`](https://rdrr.io/r/base/integer.html) and
[`as.double()`](https://rdrr.io/r/base/double.html) give its values
back.

## See also

[`roar_add()`](https://pedrobtz.github.io/zuroar/reference/roar_add.md)
and
[`roar_remove()`](https://pedrobtz.github.io/zuroar/reference/roar_add.md)
to change a bitmap.

## Examples

``` r
x <- roar(c(9, 1, 5, 5, 100000))
x
#> <zuroar> 4 values in [1, 100000]: 1 5 9 100000
length(x)
#> [1] 4
as.double(x)
#> [1] 1e+00 5e+00 9e+00 1e+05

roar_range(1, 1e6)
#> <zuroar> 1,000,000 values in [1, 1000000]: 1 2 3 4 5 6 7 8 9 10 ...
```
