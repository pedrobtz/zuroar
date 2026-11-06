# zuroar 0.0.0.9000

* New package: compressed sets of unsigned integers built on a bundled
  copy of CRoaring 5.4.0. In development towards the first CRAN release.

* `zuroar_info()` reports the bundled CRoaring version, the SIMD paths
  compiled in, and the instruction sets the processor offers.

* `roar()` and `roar_range()` build a 32-bit bitmap; `roar_add()` and
  `roar_remove()` return a changed copy, sharing unchanged containers;
  `roar_contains()` tests membership.
* A bitmap behaves as a sorted vector for `length()`, `min()`, `max()`,
  `range()`, `as.integer()`, `as.double()`, `format()` and `print()`.
* Errors inherit from `zuroar_error`, with `zuroar_error_value`,
  `zuroar_error_pointer`, `zuroar_error_unsupported` and
  `zuroar_error_memory` for the specific cases.
