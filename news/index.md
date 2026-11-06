# Changelog

## zuroar 0.0.0.9000

- New package: compressed sets of unsigned integers built on a bundled
  copy of CRoaring 5.4.0. In development towards the first CRAN release.

- [`zuroar_info()`](https://pedrobtz.github.io/zuroar/reference/zuroar_info.md)
  reports the bundled CRoaring version, the SIMD paths compiled in, and
  the instruction sets the processor offers.

- [`roar()`](https://pedrobtz.github.io/zuroar/reference/roar.md) and
  [`roar_range()`](https://pedrobtz.github.io/zuroar/reference/roar.md)
  build a 32-bit bitmap;
  [`roar_add()`](https://pedrobtz.github.io/zuroar/reference/roar_add.md)
  and
  [`roar_remove()`](https://pedrobtz.github.io/zuroar/reference/roar_add.md)
  return a changed copy, sharing unchanged containers;
  [`roar_contains()`](https://pedrobtz.github.io/zuroar/reference/roar_contains.md)
  tests membership.

- A bitmap behaves as a sorted vector for
  [`length()`](https://rdrr.io/r/base/length.html),
  [`min()`](https://rdrr.io/r/base/Extremes.html),
  [`max()`](https://rdrr.io/r/base/Extremes.html),
  [`range()`](https://rdrr.io/r/base/range.html),
  [`as.integer()`](https://rdrr.io/r/base/integer.html),
  [`as.double()`](https://rdrr.io/r/base/double.html),
  [`format()`](https://rdrr.io/r/base/format.html) and
  [`print()`](https://rdrr.io/r/base/print.html).

- Errors inherit from `zuroar_error`, with `zuroar_error_value`,
  `zuroar_error_pointer`, `zuroar_error_unsupported` and
  `zuroar_error_memory` for the specific cases.

- Set algebra: `|`, `&`,
  [`roar_xor()`](https://pedrobtz.github.io/zuroar/reference/roar_union.md),
  [`roar_andnot()`](https://pedrobtz.github.io/zuroar/reference/roar_union.md),
  [`roar_union()`](https://pedrobtz.github.io/zuroar/reference/roar_union.md),
  [`roar_intersect()`](https://pedrobtz.github.io/zuroar/reference/roar_union.md)
  and [`c()`](https://rdrr.io/r/base/c.html) build bitmaps; `==`, `!=`,
  `<=`, `<`, `>=` and `>` compare them as sets;
  [`roar_cardinality()`](https://pedrobtz.github.io/zuroar/reference/roar_cardinality.md),
  [`roar_jaccard()`](https://pedrobtz.github.io/zuroar/reference/roar_cardinality.md),
  [`roar_intersects()`](https://pedrobtz.github.io/zuroar/reference/roar_cardinality.md)
  and
  [`roar_disjoint()`](https://pedrobtz.github.io/zuroar/reference/roar_cardinality.md)
  answer without building one.
  [`roar_flip()`](https://pedrobtz.github.io/zuroar/reference/roar_union.md)
  flips a range.

- `x + k`, `x - k` and
  [`roar_shift()`](https://pedrobtz.github.io/zuroar/reference/roar_shift.md)
  shift every value; leaving the domain is an error unless
  `roar_shift(drop = TRUE)`.
