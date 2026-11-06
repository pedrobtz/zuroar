# RFC 0061: `zuroar`, Roaring bitmaps for R

Adopted from [RFC 0061](https://github.com/pedrobtz/packages/blob/main/rfcs/started/0061-zuroar-roaring-bitmaps.md)
on 2026-11-02. From here on this file is authoritative; the RFC is
history.

Amended 2026-11-02 after a review of pyroaring 1.2.0: a bitmap behaves as
a sorted vector (§6.6, D11); shifting, next and previous values, range
editing, strict subset, disjointness and `mirai` support join the API
(§5, §5.1); Q1 and Q3 are settled (§12).

- **Status:** Proposed. Merging this file adopts the design as the starting
  point for the package's own `.agents/design.md`; each decision in section
  10 stays the maintainer's until the package repository records it. A
  thin wrapper, since CRoaring does every set operation; the delicate
  part is building its processor-specific code for CRAN (section 7), and
  D3 is the decision most worth a second look.
- **Date:** 2026-11-01.
- **Packages:** `zuroar` (not yet created; crandb returns `not_found` and
  there is no `pedrobtz/zuroar` repository, both checked on 2026-11-01).
  No `Imports`. No `LinkingTo`. `Suggests: testthat, mirai` (`mirai`
  since the 2026-11-02 amendment). Vendors the CRoaring 5.4.0
  amalgamation, `roaring.c` and `roaring.h`, under the MIT side of its
  Apache-2.0/MIT dual licence. MIT for `zuroar`'s own code.
- **Source:** the request of 2026-11-01 for five new RFCs, which ranked
  this one smallest at eight stages; RFC 0037 §14 (CRoaring bitsets as
  later `zutable` work, the reason `additional-candidates.md` omits
  them); RFC 0059 §2 and §4; CRoaring `v5.4.0` and RoaringFormatSpec,
  read on 2026-11-01 (section 13). Nothing has been built.

## 1. What zuroar is

`zuroar` gives R a compressed set of unsigned integers. A bitmap holds
values from 0 to 2^32 - 1 (2^64 - 1 for the 64-bit class) and answers
membership, cardinality, rank, select and the set operations without
materialising a logical or sorted integer vector. CRoaring picks a
container per 65,536-value chunk: arrays for sparse chunks, bitsets for
dense ones, runs for intervals. Bitmaps serialise to the portable Roaring
format, which the Java, Go, Rust, Python and C implementations share.

> **CRoaring's sets as R values: no algorithm of our own, exact integers,
> and a portable byte format.**

To R code a bitmap looks like a sorted vector without duplicates:
`length()`, `x[i]`, `head()` and `c()` work as they would on
`sort(unique(v))`, while the values stay compressed (§6.6).

It is not a general set package (unsigned integers only), not a bit
vector (no fixed length, no universe, no positional `[<-`), not an
algorithm library (every set operation is CRoaring's) and not a C API
(D7).

### 1.1 Where it sits among existing CRAN packages

Checked on crandb and `tools::CRAN_package_db()` on 2026-11-01. The names
`roaring`, `RoaringBitmap`, `roaringbitmap`, `croaring`, `bitmapR`, `roaR`
and `rbitmap` are all `not_found`, and no package's title or description
mentions Roaring.

- **`bit`** 4.6.0 (GPL-2 | GPL-3): packed bit vectors and `bitwhich`
  for skewed selections. The better choice for a boolean vector of known
  length, but uncompressed: 2^32 positions cost 512 MiB.
- **`bit64`** 4.8.6 (GPL-2 | GPL-3): `integer64`, a value type, not a
  set; its set functions hash or sort plain vectors.
- **`sets`** 1.0-25 (GPL-2): generalised and fuzzy sets over R lists,
  expressive and slow for large integer sets.
- **`bitops`** 1.1-0 and base `bitwAnd()` work on 32-bit words;
  **`Matrix`** 1.7-6's `sparseVector` keeps uncompressed sorted indices.
- **Base R**: `union()`, `intersect()` and `setdiff()` hash or sort both
  inputs per call; a logical vector costs four bytes per position.

What is left for `zuroar`, as narrowly as it is true: operations on
compressed containers without decompressing either side; a byte format
shared with Spark, Lucene, ClickHouse and `pyroaring`; rank and select
over a compressed set, which no CRAN package offers; and an MIT licence a
sibling can build on.

### 1.2 The admission test

Of `base-layer-candidates.md` §2's four tests, three pass: a
specification and references (RoaringFormatSpec, with its 64-bit
extension; CRoaring, Java's RoaringBitmap, `pyroaring`), vendorable
permissive code (two amalgamated C11 files, no dependencies) and a real
weakness in base R (no compressed set type, no rank or select). The
consumer test is weak: RFC 0037 §14 calls compressed bitsets the natural
form of a `zutable` filter and RFC 0059's tombstones are a bitmap, but
both are RFCs, not packages. So `zuroar` belongs in base-layer §5,
"smaller but real"; unlike `zusearch` (RFC 0059 D1), it is small enough
that waiting for a consumer saves little.

## 2. Scope

**In v0.1.0:**

- A 32-bit class, `zuroar`, from integer or double vectors, inclusive
  ranges or the portable format; membership, cardinality, extremes,
  range counts, rank, select, next and previous value, bounded
  extraction, and adding or removing values and ranges.
- Sorted-vector behaviour: positional `[`, `[[`, `head()`, `tail()`,
  `c()`, `sort()`, `unique()`, and shifting with `+` and `-` (§6.6).
- Union, intersection, difference, symmetric difference and in-range
  complement, pairwise and many-way; cardinality-only variants, Jaccard,
  equality, subset, strict subset, disjointness and overlap.
- Portable serialisation, read through CRoaring's bounded deserialiser
  and structural validator, and a `mirai` serialisation hook.
- A 64-bit class, `zuroar64`, on CRoaring's `roaring64` maps.
- `zuroar_info()`: CRoaring version, compiled SIMD paths and run-time
  instruction sets.

**Later, in the order expected:** a `zuint` adapter for `zuroar64` in
`Suggests`; chunked iteration for sets too large to materialise; a C
table, if Q2 goes that way; the frozen format, read into an aligned
copy; threads, if the family adopts a pool.

## 3. Position in the `zu*` family

| | zuroar |
| --- | --- |
| Role | R API |
| R prefix | `roar_`, and `roar64_` where the classes differ |
| Info function | `zuroar_info()` |
| Root condition class | `zuroar_error` |
| Public C prefix | none; internal `zro_` |
| From C | no (D7) |
| Hides symbols | yes (R3); CRoaring's `roaring_*` included |
| Vendored code | CRoaring 5.4.0 amalgamation (Apache-2.0/MIT) |
| `Depends: R` | 4.1 (R2) |
| Language | en-GB (R2) |

`zro_` is unused by any RFC in this repository (searched 2026-11-01).
Hiding CRoaring's symbols matters because a sibling that vendors its own
copy, as RFC 0037 §14 contemplates for `zutable`, would otherwise define
the same `roaring_bitmap_*` names in one session.

**Relationships, all proposed:**

- **`zutable`** (RFCs 0036, 0037): a filter as a set of row numbers,
  called from R through `Suggests`. If its kernel needs bitmaps in C,
  the choice between a `zuroar` header and a second vendored copy is Q2.
- **`zusearch`** (RFC 0059): tombstones and, later, postings filters.
  RFC 0059 D8 keeps its own codecs; `zuroar` is an option for a later
  format version, not a dependency of its v0.1.0.
- **`zuann`** (base-layer §4.5, sketch): pre-filtering candidate ids.
- **`zuint`** and **`mdbx`** (both on CRAN): exact 64-bit values through
  a later adapter; a serialised bitmap is a raw vector `mdbx` stores.

## 4. Architecture

1. **Vendored C** (`src/croaring/`): release assets, verbatim except for
   §7.3's patch, in a subdirectory that R's default build skips.
2. **The wrapper unit** (`src/zro_roaring.c`, `src/zro_roaring.h`): the
   only includer of `roaring.c`; it fixes the build environment (§7.3),
   so CRoaring compiles as one translation unit with hidden symbols.
3. **Bindings** (`src/zro_bitmap.c`, `src/zro_bitmap64.c`,
   `src/zro_serial.c`): `.Call` entry points that validate R input, copy
   it into a `uint32_t` or `uint64_t` buffer, call CRoaring and copy the
   result out. No R API is called inside a CRoaring call, so an R error
   cannot long-jump through CRoaring's stack.

A bitmap is an external pointer to a `roaring_bitmap_t` (or
`roaring64_bitmap_t`) with a finaliser and class `zuroar` (or
`zuroar64`). Every operation returns a new pointer and none modifies its
argument (D4). Copy-on-write is enabled on every 32-bit bitmap through
`roaring_bitmap_set_copy_on_write()`, so `roar_add()` on a large bitmap
shares the containers it does not touch. CRoaring 5.4.0's `roaring64`
has no copy-on-write, so every change to a `zuroar64` copies the whole
bitmap (D16). A bitmap back from `readRDS()`
or a `mirai` worker without the hook of §6.4 has a null pointer; every
entry point detects it and the error names `roar_serialize()` (D5).

## 5. Public R API (v0.1.0 shape)

```r
# building
x <- roar(c(1L, 5L, 9L, 100000L))        # optimize = TRUE by default
y <- roar_range(1, 1e6)                  # inclusive, as seq()
z <- roar64(c("0", "18446744073709551615"))
x <- roar_add(x, 7L); x <- roar_remove(x, 5L)
y <- roar_add(y, from = 2e6, to = 3e6)   # add or remove an inclusive range
y <- roar_remove(y, from = 10, to = 19)

# a sorted vector without duplicates (section 6.6)
length(x)                                # 4: the cardinality
x[2:3]                                   # bitmap {7, 9}: positions, from 1
x[-1]                                    # bitmap without its smallest value
x[[2]]                                   # 7: one plain number
head(y, 3); tail(y, 3)                   # bitmaps
c(x, roar(42L))                          # union
x + 10; x - 1                            # shifted bitmaps
6 %in% x                                 # correct, but materialises x

# queries
min(x); max(x); range(x)
roar_contains(x, c(5L, 6L))              # FALSE FALSE: the fast %in%
roar_contains_range(y, from = 1, to = 9) # TRUE: every value present
roar_count(y, from = 10, to = 20)        # 1: values in the range
roar_rank(x, 9L)                         # 3: values <= 9
roar_select(x, c(1, 2))                  # 1 7: vectorised x[[k]]
roar_next(x, 8L); roar_prev(x, 8L)       # 9 and 7; NA when none

# algebra
x | y; x & y; x == y; x <= y; x < y      # union, intersection, (strict) subset
roar_xor(x, y); roar_andnot(y, x); roar_flip(x, from = 0, to = 9)
roar_union(x, y, w); roar_intersect(x, y, w)
roar_cardinality(x, y, op = "and")       # no bitmap materialised
roar_jaccard(x, y); roar_disjoint(x, y); roar_intersects(x, y)
roar_shift(x, by = -5, drop = TRUE)      # drops values that leave the domain

# back to R, and bytes
as.integer(x); as.double(y)
roar_values(y, from = 1, n = 1000)       # bounded extraction
roar_optimize(y); roar_stats(y)          # run containers; kinds, bytes
b <- roar_serialize(x)                   # portable format, raw vector
x2 <- roar_unserialize(b); roar_size(x); zuroar_info()
z2 <- roar64_unserialize(roar_serialize(z))  # 64-bit bytes need their own reader
roar64_length(z)                         # exact count as decimal text
cfg <- roar_serial_config()              # for mirai::daemons(serial = cfg)
```

`print()` and `format()` show the class, cardinality, range and first
values. `[<-`, `rev()` and `!` are errors (§6.3, §6.6).

### 5.1 Against pyroaring

`pyroaring` 1.2.0 (`Ezibenroc/PyRoaringBitMap`, CRoaring 5.2.2) is the
reference wrapper of the same library. Every feature it offers either
has an R form here or is left out for a stated reason.

<!-- markdownlint-disable MD013 -->
| pyroaring | zuroar |
| --- | --- |
| `BitMap(values, optimize=True)`, `BitMap(range(a, b))` | `roar(values, optimize = TRUE)`, `roar_range(from, to)` |
| `BitMap64` | `zuroar64` through `roar64()` |
| `BitMap` and `FrozenBitMap` | one class; every R value is immutable (D4) |
| `add`, `update`, `discard`, `remove`, `add_checked` | `roar_add()`, `roar_remove()`, returning a new bitmap |
| `add_range`, `remove_range` (half-open) | `roar_add(from =, to =)`, `roar_remove(from =, to =)` (inclusive) |
| `clear`, `pop`, `overwrite`, `*_update`, `flip_inplace` | none: they only make sense in place |
| `v in bm` | `roar_contains(x, v)`; `v %in% x` also works, slowly |
| `contains_range`, `range_cardinality` | `roar_contains_range()`, `roar_count()` |
| `len(bm)`, `bool(bm)` | `length(x)`, `length(x) > 0` |
| `min`, `max` | `min()`, `max()`, `range()` |
| `rank`, `bm[i]` (select from 0) | `roar_rank()`, `x[[i]]` and `roar_select()` (from 1) |
| `bm[i]` with negative `i` (from the end) | `tail(x, 1)`; a negative `x[-i]` drops, as in R |
| `bm[a:b:step]` | `x[i]` for any positions; `head()`, `tail()` |
| `next_set_bit`, `iter_equal_or_larger` | `roar_next()`, `roar_values(from =)`; `roar_prev()` added |
| `\|`, `&`, `-`, `^` and the named methods | `\|`, `&`, `roar_andnot()`, `roar_xor()`, `roar_union()`, `roar_intersect()` |
| `<`, `<=`, `==`, `!=`, `>=`, `>` | the same operators |
| `isdisjoint`, `intersect` (bool) | `roar_disjoint()`, `roar_intersects()` |
| `*_cardinality`, `jaccard_index` | `roar_cardinality(op =)`, `roar_jaccard()` |
| `flip(start, end)` | `roar_flip(from, to)` |
| `shift(offset)` (silently drops) | `x + k`, `roar_shift(by, drop = FALSE)` |
| `run_optimize`, `shrink_to_fit` | `roar_optimize()`, which does both |
| `get_statistics`, `__sizeof__` | `roar_stats()`, `roar_size()` |
| `to_array`, `__iter__` | `as.integer()`, `as.double()`; chunked iteration is later (§2) |
| `serialize`, `deserialize` (safe and validated) | `roar_serialize()`, `roar_unserialize()`, `roar64_unserialize()` (D8, D15) |
| pickling | `roar_serial_config()` for `mirai`; `saveRDS()` needs `roar_serialize()` (D5) |
| `copy`, `copy_on_write=` | not needed: copy-on-write is always on (§4) |
| `raw_pointer` | none: no C API (D7) |
| `__hash__` | none: R has no hashing of values |
<!-- markdownlint-enable MD013 -->

## 6. Semantics

### 6.1 Values and types

The 32-bit domain is 0 to 2^32 - 1. Input is an integer vector with no
`NA` or negative value, or a double vector of whole numbers in the
domain; anything else is a `zuroar_error_value` naming the first
offending position. Duplicates and order do not matter.

`as.integer()` and `roar_values()` error rather than produce `NA` above
`.Machine$integer.max`; `as.double()` and `type = "double"` are exact
over the whole domain (D2).

The 64-bit domain is 0 to 2^64 - 1. Input is canonical decimal text, or
whole doubles below 2^53. Output is decimal text, or double on request
when every value is below 2^53. Mixing `zuroar` and `zuroar64` in one
operation is an error; `roar64(x)` promotes explicitly.

Counts are doubles: `length()`, `roar_count()`, `roar_rank()`,
`roar_cardinality()` and `match()` positions. A 32-bit count is at most
2^32 and always exact. A `zuroar64` count above 2^53 is a
`zuroar_error_value` rather than an inexact double (D2, D14);
`roar64_length(x)` returns the exact cardinality as decimal text for
every bitmap. `roaring64_bitmap_get_cardinality()` returns a `uint64_t`,
so a bitmap holding all 2^64 values reports 0; the bindings read a zero
cardinality on a non-empty bitmap as 2^64.

### 6.2 Ranges, rank and select

R conventions at the boundary (D6). Ranges are inclusive at both ends,
as in `seq()`, and become CRoaring's half-open `[min, max)`.
`roar_select(x, k)` returns the `k`-th smallest value counting from 1,
where `roaring_bitmap_select()` counts from 0. `roar_rank(x, v)` is the
number of values at most `v`, CRoaring's own convention. So
`roar_select(x, roar_rank(x, v)) == v` for every `v` in `x`, a Stage 4
property test.

### 6.3 Operators

Between two bitmaps, `|`, `&`, `==`, `!=`, `<=`, `<`, `>=` and `>` are
`Ops` methods: union, intersection, equality, subset and strict subset,
each returning a bitmap or a single logical. `!` is undefined for want
of a universe; `xor()` is not generic in base R and `^` means power, so
`roar_xor()` is the only spelling; `-` between two bitmaps is an error,
and `roar_andnot()` names difference.

Between a bitmap and a whole number `k`, `x + k`, `k + x` and `x - k` are
`roar_shift(x, by = ±k)`, through `roaring_bitmap_add_offset()`. A value
that would leave the domain is a `zuroar_error_value` (D2), unless
`roar_shift(drop = TRUE)` asks for pyroaring's silent drop. Comparing a
bitmap with a number (`x > 5`) is an error whose message suggests
`x & roar_range()`, because an elementwise logical vector would
materialise the set.

`min`, `max` and `range` are `Summary` methods; an empty bitmap is a
`zuroar_error_value`, not R's `Inf` with a warning. `sum` and the other
`Summary` members are errors: a sum can exceed 2^53 and lose exactness.
Every other operator is an error.

### 6.4 Serialisation

`roar_serialize()` writes the portable format through
`roaring_bitmap_portable_serialize()` or its `roaring64` equivalent,
choosing by class,
optionally after `roaring_bitmap_run_optimize()` on a copy.
`roar_unserialize()` is the hostile-input surface (D8). It checks the
length with `roaring_bitmap_portable_deserialize_size()`, reads with
`roaring_bitmap_portable_deserialize_safe()`, which never reads past the
buffer, and then calls `roaring_bitmap_internal_validate()`, which the
upstream README requires for untrusted input. Trailing bytes are an
error unless `trailing = "ignore"`. The unsafe
`roaring_bitmap_portable_deserialize()` is never called.
`roar64_unserialize()` does the same through
`roaring64_bitmap_portable_deserialize_safe()` and
`roaring64_bitmap_internal_validate()`. The two formats share no
distinguishing cookie (the 64-bit one starts with an 8-byte bucket
count), so the reader is chosen by the caller, never detected (D15).

The frozen format is not exposed: `roaring.h` documents it as
endian-sensitive, and `roaring_bitmap_frozen_view()` borrows a buffer
whose alignment an R raw vector does not promise.

`saveRDS()` keeps the D5 behaviour: the bitmap comes back with a null
pointer and a clear error. `mirai` is supported without that cost.
`roar_serial_config()` returns
`mirai::serial_config(c("zuroar", "zuroar64"), ...)` with
`roar_serialize()` as both serialisers and `roar_unserialize()` and
`roar64_unserialize()` as the matching readers; passed to
`mirai::daemons(serial = )`, it ships bitmaps to and from workers through
R's `refhook` mechanism, serialising only what is sent. `mirai`
(>= 2.3.0, the first release whose `serial_config()` takes several
classes) joins `Suggests`, and
the function errors with `zuroar_error` naming `mirai` when it is not
installed.

### 6.5 Errors

Conditions inherit from `zuroar_error`: `zuroar_error_value` for input
outside the domain; `zuroar_error_format` for bytes that fail the length
check, the safe deserialiser or validation, with CRoaring's reason
string; `zuroar_error_pointer` for a null pointer after `readRDS()`;
`zuroar_error_index` for a position outside `seq_len(length(x))`;
`zuroar_error_unsupported` for an operation the class does not define
(`[<-`, `rev()`, `!`, `x > 5`); and `zuroar_error_memory` when CRoaring
returns `NULL` from an allocation.

### 6.6 A sorted vector without duplicates

A bitmap behaves, wherever R allows a method, like `sort(unique(v))`
kept compressed (D11). Positions count from 1 and are doubles, since a
32-bit bitmap can hold more than `.Machine$integer.max` values; for
`zuroar64`, positions above 2^53 are a `zuroar_error_index`.

- **`length(x)`** is the cardinality, so `seq_along(x)` and
  `seq_len(length(x))` work.
- **`x[i]`** returns a bitmap of the values at positions `i`, as `[`
  keeps the class of a `Date`. Positive positions select, negative ones
  exclude, as in R; mixing signs, `NA` or a position past the end is a
  `zuroar_error_index`, since a bitmap holds no `NA` (D2). A logical
  index is a mask over positions and is recycled as R recycles one.
  Order and repetition in `i` do not matter: `x[c(5, 2, 5)]` is the set
  of the 2nd and 5th values. A contiguous run of positions becomes one
  intersection with a range (`select` at each end), not a loop; other
  index vectors select through `roaring_bitmap_select()` per position.
  `x[]` is `x`.
- **`x[[k]]`** is the `k`-th smallest value as a plain double (character
  for `zuroar64`); `roar_select(x, k)` is its vectorised form.
- **`head(x, n)` and `tail(x, n)`** return bitmaps and follow R's rules
  for negative `n`.
- **`c(...)`** with bitmaps and whole-number vectors is their union, of
  the class of the first bitmap.
- **`sort(x)` and `unique(x)`** return `x`; `sort(x, decreasing = TRUE)`
  is an error, as is `rev(x)`: a set has no reversed form, and
  `rev(as.double(x))` is one call away.
- **`mtfrm()`** returns `as.double(x)` (decimal text for `zuroar64`), so
  `v %in% x` and `match(v, x)` give the right answer. They materialise
  `x`; the documentation points to `roar_contains()` and `roar_rank()`.
- **`[<-` and `[[<-`** are errors: assigning by position has no meaning
  for a set; `roar_add()` and `roar_remove()` change it.

R gives no hook for `for (v in x)`, `lapply(x, f)` or `union()`,
`intersect()` and `setdiff()`, which are not generic. A `for` loop over
a bitmap is an error from R itself; the documentation says to iterate
over `as.double(x)`.

## 7. Building the vendored C

### 7.1 What upstream ships

CRoaring 5.4.0 was released on 2026-10-26 (tag `v5.4.0`, commit
`20495fec4d1622b93284033a160f67d21a5aa8bb`). Each release carries the
output of `amalgamation.sh`: `roaring.c` (23,125 lines), `roaring.h`
(10,966 lines) and the C++ `roaring.hh` and `roaring64map.hh`, which
`zuroar` does not use. The README requires a C11 compiler (GCC 7 or
LLVM 8 and later), which every r-actions leg has. `vendor.yaml` pins:

```text
roaring.c  cdbd007b635b9bb2dc2074c69cb9f768e8aaf2dbe68f622c8643689b4e975dbc
roaring.h  b74054da2965baa17393c5ffa02bea587374fe33afcfff2c2d24dcf75fed419b
```

### 7.2 The processor-specific code

On x86-64, `roaring.h` defines `CROARING_IS_X64`, includes
`<x86intrin.h>`, and compiles AVX2 and AVX-512 functions inside
`CROARING_TARGET_AVX2` and `CROARING_TARGET_AVX512` regions, which are
`#pragma GCC target` blocks (clang's `attribute push` under clang).
AVX-512 code is compiled only when `CROARING_COMPILER_SUPPORTS_AVX512` is
1, which the header sets when `<avx512vbmi2intrin.h>` exists. At run
time `croaring_hardware_support()` reads CPUID once, caches the result
in an atomic, and each operation takes the AVX-512, AVX2 or scalar path.
On arm64, `CROARING_USENEON` is defined whenever `__ARM_NEON` is, which
is the baseline there.

None of this needs `-mavx2` or `-march`, which CRAN does not accept in
`Makevars`, and the binary runs on any x86-64 or arm64 processor.
`src/CMakeLists.txt` maps its four `ROARING_DISABLE_*` options (`X64`,
`AVX`, `AVX512`, `NEON`) to these compile definitions:

| Definition | Effect |
| --- | --- |
| `ROARING_DISABLE_X64=1` | no x86 intrinsics, target regions or CPUID |
| `ROARING_DISABLE_AVX=1` | dispatch always reports no AVX |
| `CROARING_COMPILER_SUPPORTS_AVX512=0` | no AVX-512 code compiled |
| `DISABLENEON=1` | scalar code on arm64 |

D3 keeps upstream's default, runtime dispatch, for the CRAN build: it is
how CRoaring is normally built, the scalar path is slowest on exactly
the dense operations that motivate the package, and `ROARING_DISABLE_X64`
everywhere is a one-line fallback if a CRAN flavour objects. A user can
force the scalar build with `CPPFLAGS += -DROARING_DISABLE_X64` in
`~/.R/Makevars`; the README says so, and no `configure` script is needed.

### 7.3 Patches and the wrapper unit

Three things in the amalgamation would trip `R CMD check`:

1. **Diagnostic pragmas.** `roaring.c` has four `#pragma GCC diagnostic
   push` blocks and `roaring.h` two (corrected 2026-11-06 in Stage 1; the
   RFC counted one), each ignoring `-Wuninitialized` and
   `-Wmaybe-uninitialized`; check's pragma scan reports such lines. The
   one recorded patch in `vendor.yaml` deletes them, and Stage 1 confirms
   that the warnings they hid are absent or false positives.
2. **`printf`.** 70 occurrences in `roaring.c`, in the `*_printf()`
   debugging functions, would leave a `printf` reference in the shared
   object. The wrapper unit includes `<stdio.h>` and `<R_ext/Print.h>`,
   then defines `printf` as `Rprintf` before including the amalgamation;
   `zro_roaring.h` does the same for every other file. A patch is the
   fallback if check still finds the symbol. *Settled 2026-11-06 (Stage
   1):* `zro_roaring.h` undefines the macro after `roaring.h` everywhere
   but the wrapper unit, because left defined it rewrites the
   `format(printf, ...)` attributes in R's own headers;
   `tools/check-symbols` confirms no `printf` is linked, so no patch.
3. **`assert()`.** About 160 calls across the two files. The wrapper
   defines `NDEBUG` before anything includes `<assert.h>`, so they
   compile out with no flag in `Makevars`.

The wrapper also brackets the include with `#pragma GCC visibility
push(hidden)` and `pop` (R3), registers routines and calls
`R_useDynamicSymbols(FALSE)`.

*Settled 2026-11-06 (Stage 1):* `zro_roaring.h` includes every system
header CRoaring uses before the hidden region, because the pragma also
marks a first-seen extern declaration hidden, which would make libc
references such as `posix_memalign` hidden. The pragma is skipped on
Windows, where symbols resolve per DLL, so there is no session-wide clash
to prevent. Registration lives in `src/zro_init.c` rather than the
wrapper unit, so the file that includes `roaring.c` holds nothing else.

### 7.4 What Stage 1 must prove

- No NOTE on any r-actions leg, including the r-devel Debian clang and
  GCC containers and Windows' Rtools.
- Every CI log records, through `zuroar_info()`, which path ran.
- A development-only job builds three ways (default,
  `CROARING_COMPILER_SUPPORTS_AVX512=0`, and `ROARING_DISABLE_X64=1` with
  `DISABLENEON=1`) and the same tests give identical results. Whether a
  CI host has AVX-512 is not ours to choose, so the scalar build is the
  oracle for the dispatched ones.
- The sanitizer and valgrind legs are clean. Valgrind does not emulate
  AVX-512, so the run-time check must keep those paths off under it;
  Stage 1 confirms that on the leg rather than assuming it.

## 8. Testing

- **Oracle.** Every operation against base R on generated sets:
  `sort(unique())`, `union()`, `intersect()`, `setdiff()`, `%in%`, and
  `findInterval()` for rank. Generators hit all three container kinds
  and the boundaries at 2^16, 2^31 and 2^32 - 1.
- **Properties.** Select inverts rank; `x & y` is a subset of both;
  cardinality-only variants equal `length()` of the materialised result;
  `roar_flip()` twice is the identity; `x < y` is `x <= y && x != y`;
  `roar_disjoint()` is `length(x & y) == 0`; `(x + k) - k` is `x` when no
  value leaves the domain; `roar_next(x, v)` is the smallest value at or
  above `v`.
- **Sorted-vector oracle.** For generated `v` and `s <- sort(unique(v))`:
  `as.double(roar(v)[i])` equals `s[i]` for positive, negative and
  logical `i`; `x[[k]]`, `head()`, `tail()`, `c()` and `match()` agree
  with the same calls on `s`.
- **Counts.** A `zuroar64` holding more than 2^53 values errors in
  `length()` and gives the right text from `roar64_length()`, including
  the full 2^64 range.
- **`mirai`.** With `roar_serial_config()` set, a bitmap round-trips
  through a local daemon (skipped when `mirai` is not installed).
- **Interoperability.** Fixtures written by `pyroaring` and Java's
  RoaringBitmap, committed with generating scripts that run only in a
  development job; both must read `roar_serialize()` output.
- **Hostile input.** Truncation at every byte of a small fixture and
  corrupted cookies, container counts, offsets and run lengths: each is a
  `zuroar_error_format`, none crashes under ASan and UBSan. A `libFuzzer`
  target over the deserialising entry point runs in development.
- **Lifetimes.** Collection of shared copy-on-write containers and null
  pointers after `readRDS()`.
- **Benchmarks** (article): base R and `bit` on union, intersection,
  membership and memory over dense, sparse and run-heavy sets. No
  speed-up is claimed before it is measured.

## 9. Roadmap

The RFC's plan, superseded by `.agents/roadmap.md`, which splits Stage 7
in three and makes Stage 2 `full`. Eight stages, numbered 0 to 7. Stages
run the quick CI profile unless
marked `full`. Each is one pull request, merged on green; nobody waits on
the post-merge full run.

| Stage | Delivers | Exit criterion |
| --- | --- | --- |
| 0 | repository, r-actions CI, skeleton, `vendor.yaml` | empty package clean |
| 1 (`full`) | vendored CRoaring, wrapper unit, `zuroar_info()` | §7.4 |
| 2 | `zuroar` class, building, membership, conversion | base R oracle |
| 3 | operators, many-way and cardinality-only algebra | §8 properties |
| 4 | rank, select, ranges, extraction, optimise, stats | rank/select test |
| 5 (`full`) | portable serialisation, validation, fixtures | §8 hostile input |
| 6 | `zuroar64`, 64-bit text and double conversion | oracle above 2^32 |
| 7 | Full CI, README, article, benchmarks, release | §11 |

Stage 1 is `full` because it is the build: target pragmas, CPUID inline
assembly and C11 atomics are what the sanitizer, valgrind and r-devel
legs catch, and every later stage stands on it. Stage 5 is `full`
because `roar_unserialize()` reads untrusted bytes, where an
out-of-bounds read shows only under sanitizers. Stage 7 fixes what the
full set finds in Stages 2 to 6.

## 10. Proposed decisions

All are **(C)**: this RFC decides them and the maintainer may overturn
any of them.

- **D1 (C).** Wrap CRoaring rather than implement Roaring: it is the
  reference C implementation, maintained, fuzzed upstream and amalgamated.
- **D2 (C).** Values stay exact. No silent `NA` or inexact double; a
  value that does not fit the requested type is an error.
- **D3 (C).** The CRAN build keeps runtime SIMD dispatch with no
  architecture flags; `ROARING_DISABLE_X64` is the documented user
  override and the first fallback if a CRAN flavour objects.
- **D4 (C).** Value semantics: every function returns a new bitmap, made
  cheap by copy-on-write.
- **D5 (C).** External pointers, explicit serialisation and a clear
  error for a pointer that did not survive `saveRDS()`. `mirai` is
  served by `roar_serial_config()` (§6.4). Settles Q1.
- **D6 (C).** R conventions at the boundary: inclusive ranges and
  1-based select.
- **D7 (C).** No C API and no installed header in v0.1.0. No sibling has
  asked; the portable format is the interoperability surface.
- **D8 (C).** Untrusted bytes are read only through the bounded
  deserialiser followed by structural validation.
- **D9 (C).** The MIT side of CRoaring's dual licence; the CRoaring
  authors are copyright holders in `Authors@R`, with upstream `LICENSE`
  and `AUTHORS` in `inst/COPYRIGHTS`.
- **D10 (C).** Single-threaded; no bitmap is shared across threads.
- **D11 (C).** A bitmap behaves as a sorted vector without duplicates
  wherever R lets a method say so: positional `[` returning a bitmap,
  `[[`, `head()`, `tail()`, `c()` as union, `sort()`, `unique()`,
  `mtfrm()`, and `+` and `-` with a number as a shift (§6.3, §6.6). Where
  vector meaning and set meaning collide (`rev()`, `[<-`, `x > 5`), the
  operation is an error rather than a silent conversion.
- **D12 (C).** Shifting a value out of the domain is an error unless
  `drop = TRUE`, unlike pyroaring's silent drop (D2).
- **D13 (C).** `roar()` rejects a logical vector with an error that
  points to `which()`. Settles Q3.
- **D14 (C).** Counts are doubles; a `zuroar64` count above 2^53 is an
  error, and `roar64_length()` gives every count exactly as text (§6.1).
- **D15 (C).** 64-bit bytes are read by `roar64_unserialize()`; the
  format is never guessed from the bytes (§6.4).
- **D16 (C).** A change to a `zuroar64` copies the whole bitmap in
  v0.1.0, because `roaring64` has no copy-on-write; the documentation
  says so. Sharing containers would need upstream support.

## 11. Acceptance criteria for v0.1.0

- Every behaviour in §6 has a passing test, against the base R oracle
  where one exists.
- The three builds of §7.4 agree on the whole test suite.
- Every corrupted input of §8 is an error and none is a crash under ASan
  and UBSan.
- `pyroaring` and Java fixtures read correctly and read this package's
  output.
- `R CMD check --as-cran` is clean on all r-actions legs; no `Imports`.
- The stages of `.agents/roadmap.md`, which supersedes §9. A stage that
  needs a second pull request moves scope to §2's later list, not the
  release.

## 12. Open questions

- **Q1. Settled 2026-11-02 by D5.** Keeping the portable bytes beside
  every bitmap would roughly double memory and serialise every result,
  in a package whose point is compression. `mirai`, the case that
  matters in practice, is served on demand by `roar_serial_config()`;
  `saveRDS()` stays explicit. An ALTREP class with a serialisation
  method is the route if this is reopened.
- **Q2.** If `zutable`'s kernel needs bitmaps in C, should `zuroar`
  install a header and C table (R10.1), or `zutable` vendor its own copy
  with hidden symbols?
- **Q3. Settled 2026-11-02 by D13.** A logical vector would fix a
  1-based meaning on a 0-based domain; `roar(which(l))` says it
  explicitly.
- **Q4.** Does any CRAN flavour's compiler mishandle the AVX-512 target
  regions? If so, `CROARING_COMPILER_SUPPORTS_AVX512=0` is a narrower
  fallback than D3's.
- **Q5.** Is v0.1.0 a CRAN submission before a sibling uses it? The
  board's `CRAN intent` records it.

## 13. Sources and verification

Checked on 2 November 2026, for the amendment:

- [pyroaring](https://github.com/Ezibenroc/PyRoaringBitMap) 1.2.0
  (2026-10-02, bundling CRoaring 5.2.2): `pyroaring/__init__.pyi` for the
  API of §5.1, and `pyroaring/abstract_bitmap.pxi` for positional
  indexing, slicing, `shift`'s silent drop and its deserialisation, which
  uses `portable_deserialize_safe()` and `internal_validate()` as D8 does.
- R 4.5.2: `union()`, `intersect()`, `setdiff()`, `is.element()`,
  `%in%` and `match()` do not dispatch; `[`, `head()`, `tail()`, `rev()`,
  `sort()`, `unique()`, `format()` and `mtfrm()` do.
- `mirai` 2.7.3: `serial_config(class, sfunc, ufunc)`, built on R's
  `refhook`, passed to `daemons(serial = )`; its NEWS gives 2.3.0 as the
  release that accepts several classes.
- CRoaring 5.4.0 `roaring64.h`: no copy-on-write; a `uint64_t`
  cardinality; `roaring64_bitmap_portable_deserialize_safe()` and
  `roaring64_bitmap_internal_validate()`.

Checked on 1 November 2026:

- [CRoaring](https://github.com/RoaringBitmap/CRoaring): latest release
  `v5.4.0` (2026-10-26) through the GitHub API; `roaring.c` and
  `roaring.h` downloaded, hashed and read for the macros, pragmas and
  `printf` and `assert` counts of §7.
- CRoaring's [README][cr-readme] (C11, amalgamation, portable format,
  validating untrusted input) and [LICENSE][cr-licence] ("a dual license
  (Apache/MIT)", either at the user's choice).
- [`src/CMakeLists.txt`](https://github.com/RoaringBitmap/CRoaring/blob/master/src/CMakeLists.txt):
  the option-to-definition mapping in §7.2.
- [RoaringFormatSpec](https://github.com/RoaringBitmap/RoaringFormatSpec):
  the portable format, its cookies and its 64-bit extension.
- crandb for `zuroar` and §1.1's names (all `not_found`) and versions;
  `tools::CRAN_package_db()` for any mention of Roaring (none); the
  GitHub API for `pedrobtz/zuroar` (not found).

Not verified here: that check's pragma scan flags these pragmas, that
valgrind hides AVX-512 from CPUID, and that no CRAN compiler mishandles
the target regions. Stage 1 settles all three.

[cr-readme]: https://github.com/RoaringBitmap/CRoaring/blob/master/README.md
[cr-licence]: https://github.com/RoaringBitmap/CRoaring/blob/master/LICENSE
