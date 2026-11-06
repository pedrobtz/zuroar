# A bitmap as a sorted vector

A bitmap behaves like `sort(unique(v))` kept compressed.
[`length()`](https://rdrr.io/r/base/length.html) is the number of
values: an integer, or a double above `.Machine$integer.max`, as for a
long vector. [`min()`](https://rdrr.io/r/base/Extremes.html),
[`max()`](https://rdrr.io/r/base/Extremes.html) and
[`range()`](https://rdrr.io/r/base/range.html) read the ends without
expanding the bitmap; an empty bitmap has none, so they are errors
there. [`as.double()`](https://rdrr.io/r/base/double.html) returns every
value exactly. [`as.integer()`](https://rdrr.io/r/base/integer.html)
does too, and is an error when a value is above `.Machine$integer.max`,
rather than giving `NA`.

## Usage

``` r
# S3 method for class 'zuroar'
length(x)

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

- ...:

  For `Summary`, further arguments, which must be absent. For the
  others, ignored.

- na.rm:

  Ignored: a bitmap holds no `NA`.

- n:

  For [`format()`](https://rdrr.io/r/base/format.html) and
  [`print()`](https://rdrr.io/r/base/print.html), how many values to
  show.

## Value

[`length()`](https://rdrr.io/r/base/length.html) returns a single
integer or double, [`min()`](https://rdrr.io/r/base/Extremes.html) and
[`max()`](https://rdrr.io/r/base/Extremes.html) a single double,
[`range()`](https://rdrr.io/r/base/range.html) two,
[`as.double()`](https://rdrr.io/r/base/double.html) and
[`as.integer()`](https://rdrr.io/r/base/integer.html) a vector,
[`format()`](https://rdrr.io/r/base/format.html) a string, and
[`print()`](https://rdrr.io/r/base/print.html) `x`, invisibly.

## Details

[`format()`](https://rdrr.io/r/base/format.html) and
[`print()`](https://rdrr.io/r/base/print.html) never fail: a bitmap
whose pointer did not survive
[`saveRDS()`](https://rdrr.io/r/base/readRDS.html) prints as a null
pointer, and every other function signals `zuroar_error_pointer` on it.

To loop over the values, use `for (v in as.double(x))`: R does not let a
class define its own iteration.

## Examples

``` r
x <- roar(c(1, 5, 9, 100000))
length(x)
#> [1] 4
range(x)
#> [1] 1e+00 1e+05
as.integer(x)
#> [1]      1      5      9 100000
x
#> <zuroar> 4 values in [1, 100000]: 1 5 9 100000
```
