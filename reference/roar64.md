# Build a 64-bit bitmap

`roar64()` builds a `zuroar64`, a bitmap of whole numbers from 0 to
2^64 - 1, on CRoaring's 64-bit Roaring bitmaps. R has no exact 64-bit
integer, so values cross over as canonical decimal text (`"0"` to
`"18446744073709551615"`, no sign, no leading zeros), or as doubles
below 2^53, where a double is still exact. `roar64()` of a 32-bit bitmap
promotes it. `roar64_range()` builds the bitmap of every value from
`from` to `to`, both included.

## Usage

``` r
roar64(values = character(), optimize = TRUE)

roar64_range(from, to)
```

## Arguments

- values:

  Whole numbers from 0 to 2^64 - 1, as decimal text or as doubles below
  2^53; or a 32-bit bitmap to promote.

- optimize:

  If `TRUE`, the default, use run-length containers where they are
  smaller, and release spare capacity.

- from, to:

  The first and last values, both included, as decimal text or whole
  doubles below 2^53.

## Value

A bitmap, an object of class `zuroar64`.

## Details

A `zuroar64` has the 32-bit API:
[`roar_add()`](https://pedrobtz.github.io/zuroar/reference/roar_add.md),
[`roar_contains()`](https://pedrobtz.github.io/zuroar/reference/roar_contains.md),
the set operators,
[`roar_rank()`](https://pedrobtz.github.io/zuroar/reference/roar_rank.md),
positions,
[`roar_serialize()`](https://pedrobtz.github.io/zuroar/reference/roar_serialize.md)
and the rest. Values come back as decimal text:
[`as.character()`](https://rdrr.io/r/base/character.html), `x[[k]]`,
[`roar_select()`](https://pedrobtz.github.io/zuroar/reference/roar_rank.md),
[`min()`](https://rdrr.io/r/base/Extremes.html) and
[`max()`](https://rdrr.io/r/base/Extremes.html).
[`as.double()`](https://rdrr.io/r/base/double.html) works when every
value is below 2^53 and is an error otherwise. Counts are doubles, and a
count above 2^53 is an error;
[`roar64_length()`](https://pedrobtz.github.io/zuroar/reference/roar64_length.md)
gives the exact cardinality as text. Mixing a `zuroar` and a `zuroar64`
in one operation is an error: promote with `roar64()` first.

CRoaring's 64-bit bitmaps have no copy-on-write, so every change to a
`zuroar64`, such as
[`roar_add()`](https://pedrobtz.github.io/zuroar/reference/roar_add.md),
copies the whole bitmap.

## Examples

``` r
z <- roar64(c("0", "18446744073709551615", "4294967296"))
z
#> <zuroar64> 3 values in [0, 18446744073709551615]: 0 4294967296 18446744073709551615
as.character(z)
#> [1] "0"                    "4294967296"           "18446744073709551615"
roar_contains(z, "4294967296")
#> [1] TRUE

roar64(roar(1:3))
#> <zuroar64> 3 values in [1, 3]: 1 2 3
roar64_range("18446744073709551610", "18446744073709551615")
#> <zuroar64> 6 values in [18446744073709551610, 18446744073709551615]: 18446744073709551610 18446744073709551611 18446744073709551612 18446744073709551613 18446744073709551614 18446744073709551615
```
