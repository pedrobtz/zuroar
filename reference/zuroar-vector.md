# A bitmap as a sorted vector

A bitmap behaves like `sort(unique(v))` kept compressed. It is a vector
to R: [`length()`](https://rdrr.io/r/base/length.html) is the number of
values, an integer, or a double above `.Machine$integer.max`, as for a
long vector; `x[[k]]` is the `k`-th smallest value; `x[i]` is a bitmap
of the values at positions `i`;
[`head()`](https://rdrr.io/r/utils/head.html) and
[`tail()`](https://rdrr.io/r/utils/head.html) return bitmaps; `v %in% x`
and `match(v, x)` work by expanding `x` into a double vector first, so
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
[`as.character()`](https://rdrr.io/r/base/character.html) gives decimal
text.

## Usage

``` r
# S3 method for class 'zuroar'
as.data.frame(
  x,
  row.names = NULL,
  optional = FALSE,
  ...,
  nm = deparse1(substitute(x))
)

# S3 method for class 'zuroar'
mtfrm(x)

# S3 method for class 'zuroar'
Summary(..., na.rm = FALSE)

# S3 method for class 'zuroar'
as.double(x, ...)

# S3 method for class 'zuroar'
as.numeric(x, ...)

# S3 method for class 'zuroar'
as.character(x, ...)

# S3 method for class 'zuroar'
as.integer(x, ...)

# S3 method for class 'zuroar'
format(x, n = 10, ...)

# S3 method for class 'zuroar'
print(x, n = 10, ...)

# S3 method for class 'zuroar64'
length(x)

# S3 method for class 'zuroar64'
Summary(..., na.rm = FALSE)

# S3 method for class 'zuroar64'
as.character(x, ...)

# S3 method for class 'zuroar64'
as.double(x, ...)

# S3 method for class 'zuroar64'
as.numeric(x, ...)

# S3 method for class 'zuroar64'
as.integer(x, ...)

# S3 method for class 'zuroar64'
format(x, n = 10, ...)

# S3 method for class 'zuroar64'
print(x, n = 10, ...)
```

## Arguments

- x:

  A bitmap.

- row.names, optional, nm:

  As for
  [`as.data.frame.vector()`](https://rdrr.io/r/base/as.data.frame.html).

- ...:

  For `Summary`, further arguments, which must be absent. For the
  others, ignored or passed on.

- na.rm:

  Ignored: a bitmap holds no `NA`.

- n:

  For [`format()`](https://rdrr.io/r/base/format.html) and
  [`print()`](https://rdrr.io/r/base/print.html), how many values to
  show.

## Value

`[` returns a bitmap. [`min()`](https://rdrr.io/r/base/Extremes.html)
and [`max()`](https://rdrr.io/r/base/Extremes.html) return a single
double (text for a `zuroar64`),
[`range()`](https://rdrr.io/r/base/range.html) two,
[`sum()`](https://rdrr.io/r/base/sum.html) one,
[`as.double()`](https://rdrr.io/r/base/double.html) and
[`as.integer()`](https://rdrr.io/r/base/integer.html) a vector,
[`format()`](https://rdrr.io/r/base/format.html) a string,
[`print()`](https://rdrr.io/r/base/print.html) `x`, invisibly, and
[`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html) a data
frame with one column.

## Details

A `zuroar64` has the same methods (see
[`roar64()`](https://pedrobtz.github.io/zuroar/reference/roar64.md)):
[`min()`](https://rdrr.io/r/base/Extremes.html),
[`max()`](https://rdrr.io/r/base/Extremes.html) and
[`range()`](https://rdrr.io/r/base/range.html) return decimal text,
[`as.double()`](https://rdrr.io/r/base/double.html) is an error when a
value is at or above 2^53, and
[`length()`](https://rdrr.io/r/base/length.html) is an error above 2^53.
It is an external pointer, not a vector, so it does not survive
[`saveRDS()`](https://rdrr.io/r/base/readRDS.html), and `%in%`,
[`match()`](https://rdrr.io/r/base/match.html),
[`sum()`](https://rdrr.io/r/base/sum.html) and data-frame columns are
not available for it.

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
