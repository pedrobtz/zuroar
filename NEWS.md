# zuroar 0.0.0.9000

* New package: compressed sets of unsigned integers built on a bundled
  copy of CRoaring 5.4.0. In development towards the first CRAN release.

* `zuroar_info()` reports the bundled CRoaring version, the SIMD paths
  compiled in, and the instruction sets the processor offers.

* `roar()` and `roar_range()` build a 32-bit bitmap; `roar_add()` and
  `roar_remove()` return a changed copy, sharing unchanged containers;
  `roar_contains()` tests membership.
* A bitmap is an ALTREP double vector that reads its values from the
  compressed form on demand and never expands behind your back: it
  survives `saveRDS()`, `serialize()` and a trip to a `mirai` or
  `parallel` worker, can be a data-frame column, and answers `length()`,
  `x[[k]]`, `x[i]` (a bitmap), `head()`, `tail()`, `%in%`, `match()`,
  `sum()`, `min()`, `max()`, `range()`, `as.integer()`, `as.double()`,
  `format()`, `print()`, `for` and `lapply()`. An operation that would
  need the values as a plain vector, such as `x[1] <- 5` or
  `identical(x, y)`, is an error; compare sets with `==`.
* Errors inherit from `zuroar_error`, with `zuroar_error_value`,
  `zuroar_error_index`, `zuroar_error_unsupported`, `zuroar_error_format`
  and `zuroar_error_memory` for the specific cases.
* Set algebra: `|`, `&`, `roar_xor()`, `roar_andnot()`, `roar_union()`,
  `roar_intersect()` and `c()` build bitmaps; `==`, `!=`, `<=`, `<`, `>=`
  and `>` compare them as sets; `roar_cardinality()`, `roar_jaccard()`,
  `roar_intersects()` and `roar_disjoint()` answer without building one.
  `roar_flip()` flips a range.
* `x + k`, `x - k` and `roar_shift()` shift every value; leaving the
  domain is an error unless `roar_shift(drop = TRUE)`.
* Ordered queries: `roar_rank()`, `roar_select()` (from 1), `roar_next()`,
  `roar_prev()`, `roar_count()` and `roar_contains_range()`, with
  inclusive ranges; `roar_values()` extracts a bounded number of values.
  `roar_add()` and `roar_remove()` take `from` and `to` for a range.
* `sort()` and `unique()` return the bitmap; `[<-`, `[[<-`, `rev()` and
  `sort(decreasing = TRUE)` are errors.
* `roar_optimize()`, `roar_stats()` and `roar_size()` show and tune how a
  bitmap is stored.
* `roar_serialize()` and `roar_unserialize()` write and read the portable
  Roaring format shared with Java, Go, Rust and Python. Reading treats the
  bytes as untrusted: bounded, validated, and a `zuroar_error_format` on
  anything corrupt, including a corrupt `.rds` file. `roar_serial_config()`
  configures `mirai` daemons for the 64-bit class to come; 32-bit bitmaps
  need no configuration.
* `roar64()` and `roar64_range()` build a `zuroar64`, a bitmap of values
  up to 2^64 - 1 that crosses into R as decimal text or doubles below
  2^53. It has the 32-bit API; `roar64_length()` gives its exact size and
  `roar64_unserialize()` reads its portable bytes. Every change to a
  `zuroar64` copies it, since CRoaring's 64-bit bitmaps have no
  copy-on-write.
