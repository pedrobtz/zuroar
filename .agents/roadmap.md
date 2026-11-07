# zuroar: roadmap

Status: approved 2026-11-02; revised the same day for the design's
pyroaring amendment (sorted-vector methods in Stage 4, shifting and new
comparisons in Stage 3, `mirai` in Stage 5); re-planned 2026-11-06 for
design D17 (the ALTREP representation, §14): a new Stage 4 switches the
32-bit class to ALTREP before the stages that build on it, the later
stages move up one number, and a Review stage closes the roadmap as
`pkg-roadmap` now requires. Implements [design.md](design.md).
Target: v0.1.0, the first CRAN release.
Tracking: [v0.1.0 (#1)](https://github.com/pedrobtz/zuroar/issues/1), with
one sub-issue per stage;
[CRAN-submission (#12)](https://github.com/pedrobtz/zuroar/issues/12).

Design §9 plans eight stages, 0 to 7, with Stage 7 combining full CI, the
README, the article, benchmarks and the release. This roadmap splits that
last stage in three, because `Full CI` adds no features and
`v0.1.0 readiness` is the release alone, and appends `Review`. Stages 0
to 3 match the design; Stage 4 is the representation switch of design
D17, and Stages 5 to 8 are the design's 4 to 7. Stage 2 is `full`, where
the design has it quick, because it brings in the external pointers and
finalisers. Stages 5 to 8 were written on the external pointer before
D17 (their commits are on the `stage-*-wip` branches); each is rebased
onto Stage 4 when its turn comes, which changes little, since the S3
methods and bindings reach the bitmap through `zro_get()`.

## Stages

| Stage | Title | CI | Issue | Pull request | Done |
| --- | --- | --- | --- | --- | --- |
| 0 | [Package identity](#stage-0--package-identity) | quick | [#2](https://github.com/pedrobtz/zuroar/issues/2) | [#15](https://github.com/pedrobtz/zuroar/pull/15) | 2026-11-06 |
| 1 | [Vendored CRoaring](#stage-1--vendored-croaring) | full | [#3](https://github.com/pedrobtz/zuroar/issues/3) | [#16](https://github.com/pedrobtz/zuroar/pull/16) | 2026-11-06 |
| 2 | [The zuroar class](#stage-2--the-zuroar-class) | full | [#4](https://github.com/pedrobtz/zuroar/issues/4) | [#17](https://github.com/pedrobtz/zuroar/pull/17) | 2026-11-06 |
| 3 | [Set algebra](#stage-3--set-algebra) | quick | [#5](https://github.com/pedrobtz/zuroar/issues/5) | [#18](https://github.com/pedrobtz/zuroar/pull/18) | 2026-11-06 |
| 4 | [ALTREP representation](#stage-4--altrep-representation) | full | [#20](https://github.com/pedrobtz/zuroar/issues/20) | [#23](https://github.com/pedrobtz/zuroar/pull/23) | 2026-11-06 |
| 5 | [Rank, select and ranges](#stage-5--rank-select-and-ranges) | quick | [#6](https://github.com/pedrobtz/zuroar/issues/6) | [#19](https://github.com/pedrobtz/zuroar/pull/19) | 2026-11-07 |
| 6 | [Portable serialisation](#stage-6--portable-serialisation) | full | [#7](https://github.com/pedrobtz/zuroar/issues/7) | [#24](https://github.com/pedrobtz/zuroar/pull/24) | 2026-11-07 |
| 7 | [64-bit bitmaps](#stage-7--64-bit-bitmaps) | quick | [#8](https://github.com/pedrobtz/zuroar/issues/8) | [#26](https://github.com/pedrobtz/zuroar/pull/26) | 2026-11-07 |
| 8 | [README, article and benchmarks](#stage-8--readme-article-and-benchmarks) | quick | [#9](https://github.com/pedrobtz/zuroar/issues/9) | | |
| 9 | [Full CI](#stage-9--full-ci) | full | [#10](https://github.com/pedrobtz/zuroar/issues/10) | | |
| 10 | [v0.1.0 readiness](#stage-10--v010-readiness) | full | [#11](https://github.com/pedrobtz/zuroar/issues/11) | | |
| 11 | [Review](#stage-11--review) | full | [#21](https://github.com/pedrobtz/zuroar/issues/21) | | |

## Stage 0 — Package identity

**Issue.** [#2](https://github.com/pedrobtz/zuroar/issues/2), sub-issue of
[v0.1.0](https://github.com/pedrobtz/zuroar/issues/1).

**CI.** `quick`.

**Goal.** The empty package has its real identity and the CI it will be
checked by, and is clean.

**Work.**

- `DESCRIPTION`: real Title and Description; `Authors@R` with the
  maintainer (`aut`, `cre`), and the CRoaring authors as copyright holders
  (`cph`) (D9); `Depends: R (>= 4.1)`; `Language: en-GB`;
  `Version: 0.0.0.9000`; no `Imports`.
- `vendor.yaml` pinning CRoaring `v5.4.0`, commit
  `20495fec4d1622b93284033a160f67d21a5aa8bb`, and the SHA-256 of
  `roaring.c` and `roaring.h` (design §7.1). Nothing is vendored yet.
- `.Rbuildignore` with every entry the "Working with skills" section of
  `CLAUDE.md` lists, plus `^vendor\.yaml$`.
- `R-CMD-check` caller: add `{"os": "windows-latest", "r": "devel"}` to
  `runners`.
- `coverage` caller: pin `coverage.yml` to a commit, with the tag in a
  comment, as `CLAUDE.md` requires for a workflow with a write token.
- Replace the placeholder test with a load test.

**Exit criteria.**

- `R CMD check` passes on the quick r-actions profile with 0 errors, 0
  warnings and 0 notes other than "New submission".
- Every check in the quick-profile run on the pull request finishes in
  under five minutes. If not, `quick-step` or `quick-containers` is tuned
  here and recorded in this roadmap.
- The `R-CMD-check` caller lists the Windows R-devel runner.
- `vendor.yaml` holds the tag, commit and both checksums.

**Design.** §3, §7.1, §9 Stage 0.

## Stage 1 — Vendored CRoaring

**Issue.** [#3](https://github.com/pedrobtz/zuroar/issues/3), sub-issue of
[v0.1.0](https://github.com/pedrobtz/zuroar/issues/1).

**CI.** `full — first compiled code and a vendored library with SIMD target
regions, CPUID assembly and C11 atomics: sanitizers, valgrind, r-devel and
rchk.`

**Goal.** CRoaring builds inside the package on every r-actions leg with no
NOTE, and `zuroar_info()` reports what was compiled and what runs.

**Work.**

- `src/croaring/roaring.c` and `roaring.h` from the `v5.4.0` release,
  checked against `vendor.yaml`; upstream `LICENSE` and `AUTHORS` in
  `inst/COPYRIGHTS`.
- One patch, recorded in `vendor.yaml`, that deletes the diagnostic pragmas
  (§7.3); a script that verifies "upstream plus exactly this patch".
- The wrapper unit `src/zro_roaring.c` and `src/zro_roaring.h`: `NDEBUG`,
  `printf` as `Rprintf`, `#pragma GCC visibility push(hidden)` around the
  include, routine registration and `R_useDynamicSymbols(FALSE)`.
- `zuroar_info()`: CRoaring version, compiled SIMD paths, run-time
  instruction sets.
- A CI step that runs `nm -u` on the built objects and fails on `printf`,
  `stdout`, `stderr`, `abort`, `exit` or system RNG symbols.
- A development-only job that builds three ways (default,
  `CROARING_COMPILER_SUPPORTS_AVX512=0`, and `ROARING_DISABLE_X64=1` with
  `DISABLENEON=1`) and runs the test suite on each.

**Exit criteria.**

- A full-profile r-actions run is green with no NOTE on any leg, including
  the r-devel Debian clang and GCC containers and Windows Rtools.
- Every CI log records `zuroar_info()` output. *Deviation 2026-11-06:*
  every runner leg and the build variants print it; the R-hub container
  jobs show test output only on failure, so theirs do not.
- The sanitizer and valgrind legs are clean, and the valgrind leg's
  `zuroar_info()` shows AVX-512 off.
- The three builds pass the same tests.
- The `nm -u` step passes, and no `roaring_*` symbol is exported from the
  shared object.

**Design.** §4 (items 1 and 2), §7, D1, D3, D9.

## Stage 2 — The zuroar class

**Issue.** [#4](https://github.com/pedrobtz/zuroar/issues/4), sub-issue of
[v0.1.0](https://github.com/pedrobtz/zuroar/issues/1).

**CI.** `full — first external pointers and finalisers, and copy-on-write
containers shared between bitmaps: gctorture, valgrind, ASan.`

**Goal.** A user can build a 32-bit bitmap, add and remove values, test
membership and convert back to R, with values exact and arguments never
modified.

**Work.**

- `src/zro_bitmap.c`: the external pointer with finaliser and copy-on-write
  enabled; the null-pointer check every entry point calls.
- `roar()` (with `optimize = TRUE`), `roar_range()`, `roar_add()`,
  `roar_remove()`, `roar_contains()`; `length()`, `min()`, `max()`,
  `range()` (`Summary`; other members error); `as.integer()`,
  `as.double()`; `print()`, `format()`.
- Input validation and the condition classes `zuroar_error`,
  `zuroar_error_value`, `zuroar_error_pointer`, `zuroar_error_memory`;
  a logical vector given to `roar()` is an error pointing to `which()`
  (D13).
- Test generators that hit array, bitset and run containers and the
  boundaries at 2^16, 2^31 and 2^32 - 1; base R oracle tests.

**Exit criteria.**

- Every function above matches the base R oracle (`sort(unique())`, `%in%`)
  on the generated sets.
- Invalid input (`NA`, negative, fractional, above 2^32 - 1) is a
  `zuroar_error_value`; `as.integer()` above `.Machine$integer.max` errors.
- A bitmap after `saveRDS()` and `readRDS()` gives `zuroar_error_pointer`.
- Tests show `roar_add()` and `roar_remove()` leave their argument
  unchanged, and collecting a bitmap that shares containers leaves the other
  intact.
- A full-profile r-actions run is green.

**Design.** §4 (item 3), §5, §6.1, §6.5, §8 (oracle, lifetimes), D2, D4,
D5.

## Stage 3 — Set algebra

**Issue.** [#5](https://github.com/pedrobtz/zuroar/issues/5), sub-issue of
[v0.1.0](https://github.com/pedrobtz/zuroar/issues/1).

**CI.** `quick`.

**Goal.** The set operations work pairwise, many-way and as
cardinality-only variants.

**Work.**

- `Ops` methods between bitmaps: `|`, `&`, `==`, `!=`, `<=`, `<`, `>=`,
  `>`; `-` between bitmaps, `!` and comparisons with numbers error with
  `zuroar_error_unsupported`.
- Shifting: `x + k`, `k + x`, `x - k` and `roar_shift(x, by, drop =
  FALSE)` (D12).
- `c()` as union.
- `roar_xor()`, `roar_andnot()`, `roar_flip()`, `roar_union()`,
  `roar_intersect()`, `roar_cardinality()`, `roar_jaccard()`,
  `roar_disjoint()`, `roar_intersects()`.

**Exit criteria.**

- Every operation matches `union()`, `intersect()` and `setdiff()` on the
  generated sets, and `c()` matches `sort(unique(c(...)))`.
- Property tests pass: `x & y` is a subset of both; cardinality-only
  results equal `length()` of the materialised result; `roar_flip()` twice
  is the identity; `x < y` is `x <= y && x != y`; `roar_disjoint()` is
  `length(x & y) == 0`; `(x + k) - k` is `x`.
- A shift out of the domain is a `zuroar_error_value`, and with
  `drop = TRUE` matches the oracle with those values removed.
- `R CMD check` passes on the quick profile.

**Design.** §5, §6.3, §8 (properties), D11, D12.

## Stage 4 — ALTREP representation

**Issue.** [#20](https://github.com/pedrobtz/zuroar/issues/20), sub-issue of
[v0.1.0](https://github.com/pedrobtz/zuroar/issues/1).

**CI.** `full — new ALTREP methods and a second finalizer path, and
serialisation through R itself: gctorture, valgrind, ASan, rchk.`

**Goal.** A `zuroar` is an ALTREP double vector that never expands: it
survives `saveRDS()` and `serialize()`, works as a data-frame column,
answers `%in%` and `match()`, and every attempt to take its data pointer
is an error. Nothing the user saw in Stages 2 and 3 changes except that
`readRDS()` now gives the bitmap back.

**Work.**

- `src/zro_altrep.c`: the class and its methods as design §4 lists them:
  `Length`, `Elt`, `Get_region`, refusing `Dataptr` and
  `Dataptr_or_null`, `Is_sorted`, `No_NA`, `Extract_subset`,
  `Duplicate`, `Serialized_state`, `Unserialize`, `Inspect`. The bitmap
  lives in `data1` as the external pointer Stage 2 built, finaliser
  included; `zro_shell()` and `zro_get()` wrap and unwrap it, so the
  bindings of Stages 2 and 3 do not change.
- `Serialized_state` writes the portable bytes (§6.4) and `Unserialize`
  reads them through the bounded path of D8, so a corrupt `.rds` is a
  `zuroar_error_format`, not a crash.
- `zuroar_error_pointer` no longer applies to a `zuroar`; its tests move
  to `zuroar64` in Stage 7. `format()` and `print()` keep working on any
  object the class can produce.
- `Dataptr` refusing signals `zuroar_error_unsupported` with a message
  naming `as.double()` and `roar_values()`. *2026-11-06:* the message
  names `as.double()`, `head()` and `roar_contains()`; Stage 5 adds
  `roar_values()` when it exists.
- A test-only `.Call` that calls `REAL()` on a bitmap, to show the
  refusal from C; tests for `saveRDS()` and `serialize()` round trips,
  `identical()`, `%in%` and `match()` against the oracle, `data.frame(x)`,
  `lapply()`, and `sum()`, `print()` and `head()` without expansion.
- `CLAUDE.md`: the architecture entry and the invariants (`Dataptr` never
  returns; every ALTREP method is CRoaring-only or protects what it
  allocates).

**Exit criteria.**

- A bitmap saved with `saveRDS()` and read back equals the original, and
  so does one through `serialize()`/`unserialize()` and through a
  `mirai` daemon with no `serial` configuration.
- `v %in% x` and `match(v, x)` match the oracle on the generated sets,
  and the Stage 2 and 3 suites pass unchanged.
- `x + 1`, `x > 5`, `x[1] <- 5`, `unclass(x) + 1` and the test-only
  `REAL()` call are errors, and `sum(x)`, `print(x)`, `x[[k]]`,
  `head(x)`, `tail(x)` and `x[i]` succeed, on a bitmap whose expansion
  would exceed available memory (`roar_range(0, 2^32 - 1)`). *Deviation
  2026-11-06:* `as.double(x)` was dropped from the error list; it is the
  explicit expansion (§6.6) and on that bitmap fails only when memory
  runs out, which is R's error and depends on the machine.
- `x == roar_unserialize(roar_serialize(x))` is `TRUE`. *Deviation
  2026-11-06:* the criterion said `identical()`, which reads the data
  pointer on every R version and so is a `zuroar_error_unsupported`
  under D17 (design §6.6, §14); `==` is the set equality. Checked here
  through `serialize()`, `saveRDS()` and the test hook, since
  `roar_serialize()` is Stage 6's.
- A full-profile r-actions run is green: gctorture at the sensitive step,
  valgrind and ASan over the new methods, rchk on `src/zro_altrep.c`.

**Design.** §4, §6.4, §6.6, §8 (lifetimes), §14, D4, D11, D17.

*Done 2026-11-06.* Also: `sum()` works through a `Sum` method (design
§6.6 amended); `[` was a thin S3 method over `Extract_subset`, because
base `[` drops the class attribute of its result (Stage 5 replaces it); `as.data.frame()` is
`as.data.frame.vector`; `rev()`, `sort(decreasing = TRUE)` and
`unique()` keep their Stage 5 methods, so until then `rev(x)` is `x` and
`unique(x)` a plain vector; a data frame with a bitmap column builds and
subsets but does not print (design Q6).

## Stage 5 — Rank, select and ranges

**Issue.** [#6](https://github.com/pedrobtz/zuroar/issues/6), sub-issue of
[v0.1.0](https://github.com/pedrobtz/zuroar/issues/1).

**CI.** `quick`.

**Goal.** Ordered queries, range editing and bounded extraction work
with R's conventions, and a bitmap behaves as a sorted vector.

**Work.**

- `roar_rank()`, `roar_select()` (1-based), `roar_next()`, `roar_prev()`,
  `roar_count()` and `roar_contains_range()` (inclusive ranges),
  `roar_values()` (bounded extraction), `roar_optimize()`, `roar_stats()`,
  `roar_size()`.
- `roar_add(from =, to =)` and `roar_remove(from =, to =)`.
- Sorted-vector methods (§6.6): `[` (an S3 method over `zro_subset()`;
  *2026-11-06:* not through `Extract_subset`, which receives indices R
  has already resolved and so cannot raise the classed errors below),
  `[[`, `head()`, `tail()`, `sort()`, `unique()`;
  `[<-`, `[[<-`, `rev()` and `sort(decreasing = TRUE)` error;
  `zuroar_error_index` and `zuroar_error_unsupported`. No `mtfrm()`:
  D17 makes `%in%` and `match()` work without it.
- Rebase of the `stage-4-wip` work (pull request #19, written on the
  external pointer) onto Stage 4.

**Exit criteria.**

- `roar_rank()` matches `findInterval()` on the generated sets.
- `roar_select(x, roar_rank(x, v)) == v` for every `v` in `x`.
- `roar_next()` and `roar_prev()` match the oracle, with `NA` when no
  value qualifies.
- Range bounds at 0 and 2^32 - 1 are inclusive and tested.
- The sorted-vector oracle of design §8 passes for positive, negative and
  logical `i`, `[[`, `head()`, `tail()` and `match()`; mixed signs, `NA`
  and positions past the end are `zuroar_error_index`.
- `R CMD check` passes on the quick profile.

**Design.** §5, §6.2, §6.6, D6, D11, D17.

## Stage 6 — Portable serialisation

**Issue.** [#7](https://github.com/pedrobtz/zuroar/issues/7), sub-issue of
[v0.1.0](https://github.com/pedrobtz/zuroar/issues/1).

**CI.** `full — a decoder of untrusted bytes: ASan, UBSan and valgrind.`

**Goal.** Bitmaps round-trip through the portable format, other
implementations' bytes read correctly, and no corrupt input crashes.

**Work.**

- `src/zro_serial.c`: `roar_serialize()` (optionally run-optimised on a
  copy) and `roar_unserialize()` through the size check, the safe
  deserialiser and `roaring_bitmap_internal_validate()`; `trailing =
  "ignore"`.
- `zuroar_error_format` with CRoaring's reason string.
- Fixtures written by `pyroaring` and Java's RoaringBitmap, with their
  generating scripts, which run only in a development job.
- Hostile-input tests: truncation at every byte of a small fixture;
  corrupted cookies, container counts, offsets and run lengths.
- A `libFuzzer` target over the deserialising entry point, run in
  development only.
- `roar_serial_config()` for `mirai::daemons(serial = )`, needed for
  `zuroar64` (Stage 7) and harmless for `zuroar`, which Stage 4 made
  travel on its own; `mirai (>= 2.3.0)` in `Suggests`, guarded so the
  package works without it.
- `Serialized_state` and `Unserialize` of Stage 4 share
  `zro_portable_read()` with `roar_unserialize()`, so the hostile-input
  tests and the fuzz target cover `readRDS()` of a corrupt file too.

**Exit criteria.**

- Round trips are exact on the generated sets.
- A bitmap round-trips through a local `mirai` daemon with and without
  `roar_serial_config()` set; the test skips without `mirai`, and the
  `nosuggests` leg passes.
- The `pyroaring` and Java fixtures read to the expected sets.
- Every hostile input is a `zuroar_error_format`, and the ASan, UBSan and
  valgrind legs are clean.
- `roaring_bitmap_portable_deserialize()` does not appear in `src/` outside
  `src/croaring/`.
- A full-profile r-actions run is green.

**Design.** §6.4, §6.5, §8 (interoperability, hostile input, `mirai`),
D5, D8, D17.

## Stage 7 — 64-bit bitmaps

**Issue.** [#8](https://github.com/pedrobtz/zuroar/issues/8), sub-issue of
[v0.1.0](https://github.com/pedrobtz/zuroar/issues/1).

**CI.** `quick`.

**Goal.** `zuroar64` offers the 32-bit API over 0 to 2^64 - 1, exact
through decimal text.

**Work.**

- `src/zro_bitmap64.c` on CRoaring's `roaring64`; `roar64()` from decimal
  text or whole doubles below 2^53, and promotion from `zuroar`.
- `roar64_` functions where the classes differ; the 32-bit generics,
  operators and sorted-vector methods for `zuroar64`, with positions above
  2^53 a `zuroar_error_index`; 64-bit serialisation,
  `roar64_unserialize()` with 64-bit hostile-input tests, and the 64-bit
  half of `roar_serial_config()`.
- Counts as doubles that error above 2^53, `roar64_length()` as exact text,
  and the full 2^64 range read correctly (D14). *Deviation 2026-11-06:*
  `roaring64` needs one container per 2^16 values, so neither the full
  range nor a count above 2^53 fits in memory; the code keeps the wrap
  and the error, and ranges adding more than 2^40 values are refused
  with `zuroar_error_memory` (design §6.1). `roar64_range()` is added.
- Documentation that changes to a `zuroar64` copy the whole bitmap (D16).
- Output as decimal text, or double when every value is below 2^53.
- An error for mixing `zuroar` and `zuroar64` in one operation.
- `zuroar64` stays an external pointer (design §4, §14): the
  `zuroar_error_pointer` tests and `roar_serial_config()`'s purpose move
  here, and the documentation says a `zuroar64` does not survive
  `saveRDS()` where a `zuroar` does.

**Exit criteria.**

- Every operation matches the oracle on sets with values above 2^32,
  compared as decimal text.
- Non-canonical text and doubles at or above 2^53 are a
  `zuroar_error_value`.
- 64-bit serialisation round-trips and reads the 64-bit fixtures.
- `R CMD check` passes on the quick profile.

**Design.** §2, §6.1, §6.4.

## Stage 8 — README, article and benchmarks

**Issue.** [#9](https://github.com/pedrobtz/zuroar/issues/9), sub-issue of
[v0.1.0](https://github.com/pedrobtz/zuroar/issues/1).

**CI.** `quick`.

**Goal.** A newcomer can see what the package is for and how fast it is,
with every claim measured.

**Work.**

- `README.Rmd` (the `pkg-readme` skill), including the
  `ROARING_DISABLE_X64` override in `~/.R/Makevars` (D3).
- An article with benchmarks against base R and `bit` on union,
  intersection, membership and memory over dense, sparse and run-heavy sets.
- The pkgdown reference index.
- The Get started article, `vignettes/zuroar.Rmd`: by now the feature
  stages have switched on each chunk they implemented (`pkg-implement`);
  remove the `eval = FALSE` setup default if a stage has not.

**Exit criteria.**

- `README.md` is knitted from `README.Rmd` and its examples run.
- `vignettes/zuroar.Rmd` runs every chunk, with no `eval = FALSE` left,
  and the site builds.
- The article builds on the pkgdown workflow; no speed-up is stated
  without a measurement.
- `R CMD check` passes on the quick profile.

**Design.** §7.2, §8 (benchmarks), §9 Stage 7.

## Stage 9 — Full CI

**Issue.** [#10](https://github.com/pedrobtz/zuroar/issues/10), sub-issue of
[v0.1.0](https://github.com/pedrobtz/zuroar/issues/1).

**CI.** `full`.

**Goal.** No new features. Everything the full r-actions profile finds on
the default branch's code is fixed.

**Work.**

- Run the full profile (`full-ci` label): gctorture at the sensitive step,
  valgrind, ASan, every platform leg, `nosuggests`, `nold`, cran-special.
- Fix every failure, including those recorded on this issue after earlier
  merges.

**Exit criteria.**

- A full-profile run is green on the pull request and on the merge commit.

**Design.** §11.

## Stage 10 — v0.1.0 readiness

**Issue.** [#11](https://github.com/pedrobtz/zuroar/issues/11), sub-issue of
[v0.1.0](https://github.com/pedrobtz/zuroar/issues/1).

**CI.** `full`.

**Goal.** Only the submission itself is left.

**Work.**

- `Version: 0.1.0` and the matching `NEWS.md` heading.
- `cran-comments.md` listing the r-actions CI legs as test environments.
- `urlchecker::url_check()` and `spelling::spell_check_package()`.

**Exit criteria.**

- `urlchecker::url_check()` and `spelling::spell_check_package()` are
  clean.
- A full-profile r-actions run is green on the merge commit.
- The design's §11 acceptance criteria hold.

**Design.** §11.

## Stage 11 — Review

**Issue.** [#21](https://github.com/pedrobtz/zuroar/issues/21), sub-issue of
[v0.1.0](https://github.com/pedrobtz/zuroar/issues/1).

**CI.** `full`.

**Goal.** The release candidate as Stage 10 left it has been reviewed
twice and only the submission itself is left.

**Work.**

- The `pkg-critical-review` skill over the whole package: its blocking
  and required findings become sub-issues of the Review issue, each fixed
  in a pull request that closes it.
- Then the `pkg-cran-review` skill, run after those fixes so it sees the
  code that is submitted, with every FAIL and WARN resolved.
- `NEWS.md` reflecting any user-visible fix.

**Exit criteria.**

- Every blocking and required review issue is closed.
- The `pkg-cran-review` table is clean on the default branch.
- A full-profile r-actions run is green on the default branch, whose head
  becomes the release commit.
- The Review issue is closed by the review skills, not by a pull request,
  and `v0.1.0` reads 100%.

**Design.** §11.

## After 0.1.0

From design §2, in the order expected:

- A `zuint` adapter for `zuroar64`, in `Suggests`.
- Chunked iteration for sets too large to materialise.
- A C table and installed header, if Q2 goes that way (D7 rules it out of
  v0.1.0).
- The frozen format, read into an aligned copy (§6.4 explains why not now).
- Threads, if the family adopts a pool (D10).

## Open questions

Q3 was settled on 2026-11-02 by design D13. Q1 was settled by D5 the
same day and re-settled on 2026-11-06 by D17 (design §14).

- **Q4. Settled 2026-11-06 by Stage 1's full run** (#16): no leg's
  compiler mishandles the AVX-512 target regions (gcc16, clang23,
  ubuntu-clang, Rtools on Windows release and devel, macOS clang).
- **Q2** (after 0.1.0). Header and C table, or a second vendored copy in
  `zutable`? Blocks no stage.
- **Q5** (Stage 10). Is v0.1.0 a CRAN submission before a sibling uses it?
  The board's `CRAN intent` records the answer.
