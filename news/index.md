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

- A bitmap is an ALTREP double vector that reads its values from the
  compressed form on demand and never expands behind your back: it
  survives [`saveRDS()`](https://rdrr.io/r/base/readRDS.html),
  [`serialize()`](https://rdrr.io/r/base/serialize.html) and a trip to a
  `mirai` or `parallel` worker, can be a data-frame column, and answers
  [`length()`](https://rdrr.io/r/base/length.html), `x[[k]]`, `x[i]` (a
  bitmap), [`head()`](https://rdrr.io/r/utils/head.html),
  [`tail()`](https://rdrr.io/r/utils/head.html), `%in%`,
  [`match()`](https://rdrr.io/r/base/match.html),
  [`sum()`](https://rdrr.io/r/base/sum.html),
  [`min()`](https://rdrr.io/r/base/Extremes.html),
  [`max()`](https://rdrr.io/r/base/Extremes.html),
  [`range()`](https://rdrr.io/r/base/range.html),
  [`as.integer()`](https://rdrr.io/r/base/integer.html),
  [`as.double()`](https://rdrr.io/r/base/double.html),
  [`format()`](https://rdrr.io/r/base/format.html),
  [`print()`](https://rdrr.io/r/base/print.html), `for` and
  [`lapply()`](https://rdrr.io/r/base/lapply.html). An operation that
  would need the values as a plain vector, such as `x[1] <- 5` or
  `identical(x, y)`, is an error; compare sets with `==`.

- Errors inherit from `zuroar_error`, with `zuroar_error_value`,
  `zuroar_error_index`, `zuroar_error_unsupported`,
  `zuroar_error_format` and `zuroar_error_memory` for the specific
  cases.

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
