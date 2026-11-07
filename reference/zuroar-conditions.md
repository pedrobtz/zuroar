# Conditions signalled by zuroar

Every error zuroar signals inherits from `zuroar_error`, so code can
catch them all with `tryCatch(..., zuroar_error = )`. A more specific
class says what went wrong:

## Details

- `zuroar_error_value`: a value outside the domain, such as `NA`, a
  negative or fractional number, or one above 2^32 - 1; or an output
  type that cannot hold a value, such as
  [`as.integer()`](https://rdrr.io/r/base/integer.html) on a bitmap
  holding a value above `.Machine$integer.max`.

- `zuroar_error_index`: a position outside `seq_len(length(x))`, or
  `NA`, in `x[i]`.

- `zuroar_error_unsupported`: an operation a set does not define, such
  as `x > 5`, or one that would need the values as a plain vector, such
  as `x[1] <- 5` or `identical(x, y)`.

- `zuroar_error_format`: bytes that are not a valid portable Roaring
  bitmap, for example a corrupt `.rds` file.

- `zuroar_error_memory`: CRoaring could not allocate memory.

Match on the class, not on the message, which may change.

## Examples

``` r
tryCatch(roar(-1), zuroar_error_value = function(e) "out of domain")
#> [1] "out of domain"
```
