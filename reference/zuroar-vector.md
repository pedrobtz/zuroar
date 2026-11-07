# A bitmap as a sorted vector

A bitmap behaves like `sort(unique(v))` kept compressed. It is a vector
to R: [`length()`](https://rdrr.io/r/base/length.html) is the number of
values, an integer, or a double above `.Machine$integer.max`, as for a
long vector; `x[[k]]` is the `k`-th smallest value; `x[i]` is a bitmap
of the values at positions `i`;
[`head()`](https://rdrr.io/r/utils/head.html) and
[`tail()`](https://rdrr.io/r/utils/head.html) return bitmaps; `v %in% x`
and `match(v, x)` work by visiting every value, so
[`roar_contains()`](https://pedrobtz.github.io/zuroar/reference/roar_contains.md)
is the fast membership test. [`sum()`](https://rdrr.io/r/base/sum.html)
adds the values in one pass.
[`min()`](https://rdrr.io/r/base/Extremes.html),
[`max()`](https://rdrr.io/r/base/Extremes.html) and
[`range()`](https://rdrr.io/r/base/range.html) read the ends without
expanding the bitmap; an empty bitmap has none, so they are errors
there. [`as.double()`](https://rdrr.io/r/base/double.html) returns every
value exactly. [`as.integer()`](https://rdrr.io/r/base/integer.html)
does too, and is an error when a value is above `.Machine$integer.max`,
rather than giving `NA`. A bitmap can be a data-frame column, and
survives [`saveRDS()`](https://rdrr.io/r/base/readRDS.html),
[`serialize()`](https://rdrr.io/r/base/serialize.html) and a trip to
another R process on its own.

## Usage

``` r
# S3 method for class 'zuroar'
x[i, ...]

# S3 method for class 'zuroar'
as.data.frame(
  x,
  row.names = NULL,
  optional = FALSE,
  ...,
  nm = deparse1(substitute(x))
)

# S3 method for class 'zuroar'
Summary(..., na.rm = FALSE)

# S3 method for class 'zuroar'
as.double(x, ...)

# S3 method for class 'zuroar'
as.numeric(x, ...)

# S3 method for class 'zuroar'
as.integer(x, ...)

# S3 method for class 'zuroar'
format(x, n = 10, ...)

# S3 method for class 'zuroar'
print(x, n = 10, ...)
```

## Arguments

- x:

  A bitmap.

- i:

  Positions, from 1, as in `[` on a vector: positive to select, negative
  to exclude, or a logical mask. `NA` and a position past the end are
  `zuroar_error_index` errors.

- ...:

  For `Summary`, further arguments, which must be absent. For the
  others, ignored or passed on.

- row.names, optional, nm:

  As for
  [`as.data.frame.vector()`](https://rdrr.io/r/base/as.data.frame.html).

- na.rm:

  Ignored: a bitmap holds no `NA`.

- n:

  For [`format()`](https://rdrr.io/r/base/format.html) and
  [`print()`](https://rdrr.io/r/base/print.html), how many values to
  show.

## Value

`[` returns a bitmap. [`min()`](https://rdrr.io/r/base/Extremes.html)
and [`max()`](https://rdrr.io/r/base/Extremes.html) return a single
double, [`range()`](https://rdrr.io/r/base/range.html) two,
[`sum()`](https://rdrr.io/r/base/sum.html) one,
[`as.double()`](https://rdrr.io/r/base/double.html) and
[`as.integer()`](https://rdrr.io/r/base/integer.html) a vector,
[`format()`](https://rdrr.io/r/base/format.html) a string,
[`print()`](https://rdrr.io/r/base/print.html) `x`, invisibly, and
[`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html) a data
frame with one column.

## Details

The values are read from the compressed form on demand and never
expanded behind your back: an operation that needs them as a plain
vector, such as `x[1] <- 5`, `identical(x, y)` or `cumsum(x)`, is a
`zuroar_error_unsupported` error. Compare bitmaps as sets with `==`, and
expand one explicitly with
[`as.double()`](https://rdrr.io/r/base/double.html).

[`format()`](https://rdrr.io/r/base/format.html) gives one line
describing the bitmap, which
[`print()`](https://rdrr.io/r/base/print.html) shows. To loop over the
values, use `for (v in x)` or `lapply(x, f)`.

## Examples

``` r
x <- roar(c(1, 5, 9, 100000))
length(x)
#> [1] 4
x[[2]]
#> [1] 5
x[2:3]
#> <zuroar> 2 values in [5, 9]: 5 9
c(5, 6) %in% x
#> [1]  TRUE FALSE
range(x)
#> [1] 1e+00 1e+05
as.integer(x)
#> [1]      1      5      9 100000
x
#> <zuroar> 4 values in [1, 100000]: 1 5 9 100000
```
