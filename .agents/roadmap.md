# zuroar: roadmap

Status: approved 2026-11-02; revised the same day for the design's
pyroaring amendment (sorted-vector methods in Stage 4, shifting and new
comparisons in Stage 3, `mirai` in Stage 5). Implements
[design.md](design.md).
Target: v0.1.0, the first CRAN release.
Tracking: [v0.1.0 (#1)](https://github.com/pedrobtz/zuroar/issues/1), with
one sub-issue per stage;
[CRAN-submission (#12)](https://github.com/pedrobtz/zuroar/issues/12).

Design §9 plans eight stages, 0 to 7, with Stage 7 combining full CI, the
README, the article, benchmarks and the release. This roadmap splits that
last stage in three, because `Full CI` adds no features and
`v0.1.0 readiness` is the release alone. Stages 0 to 6 match the design.
Stage 2 is `full`, where the design has it quick, because it brings in the
external pointers and finalisers.

## Stages

| Stage | Title | CI | Issue | Pull request | Done |
| --- | --- | --- | --- | --- | --- |
| 0 | [Package identity](#stage-0--package-identity) | quick | [#2](https://github.com/pedrobtz/zuroar/issues/2) | [#15](https://github.com/pedrobtz/zuroar/pull/15) | 2026-11-06 |
| 1 | [Vendored CRoaring](#stage-1--vendored-croaring) | full | [#3](https://github.com/pedrobtz/zuroar/issues/3) | [#16](https://github.com/pedrobtz/zuroar/pull/16) | 2026-11-06 |
| 2 | [The zuroar class](#stage-2--the-zuroar-class) | full | [#4](https://github.com/pedrobtz/zuroar/issues/4) | [#17](https://github.com/pedrobtz/zuroar/pull/17) | 2026-11-06 |
| 3 | [Set algebra](#stage-3--set-algebra) | quick | [#5](https://github.com/pedrobtz/zuroar/issues/5) | [#18](https://github.com/pedrobtz/zuroar/pull/18) | 2026-11-06 |
| 4 | [Rank, select and ranges](#stage-4--rank-select-and-ranges) | quick | [#6](https://github.com/pedrobtz/zuroar/issues/6) | | |
| 5 | [Portable serialisation](#stage-5--portable-serialisation) | full | [#7](https://github.com/pedrobtz/zuroar/issues/7) | | |
| 6 | [64-bit bitmaps](#stage-6--64-bit-bitmaps) | quick | [#8](https://github.com/pedrobtz/zuroar/issues/8) | | |
| 7 | [README, article and benchmarks](#stage-7--readme-article-and-benchmarks) | quick | [#9](https://github.com/pedrobtz/zuroar/issues/9) | | |
| 8 | [Full CI](#stage-8--full-ci) | full | [#10](https://github.com/pedrobtz/zuroar/issues/10) | | |
| 9 | [v0.1.0 readiness](#stage-9--v010-readiness) | full | [#11](https://github.com/pedrobtz/zuroar/issues/11) | | |

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

## Stage 4 — Rank, select and ranges

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
- Sorted-vector methods (§6.6): `[`, `[[`, `head()`, `tail()`, `sort()`,
  `unique()`; `[<-`, `[[<-`, `rev()` and
  `sort(decreasing = TRUE)` error; `zuroar_error_index` and
  `zuroar_error_unsupported`.

**Exit criteria.**

- `roar_rank()` matches `findInterval()` on the generated sets.
- `roar_select(x, roar_rank(x, v)) == v` for every `v` in `x`.
- `roar_next()` and `roar_prev()` match the oracle, with `NA` when no
  value qualifies.
- Range bounds at 0 and 2^32 - 1 are inclusive and tested.
- The sorted-vector oracle of design §8 passes for positive, negative and
  logical `i`, `[[`, `head()` and `tail()`; mixed signs, `NA` and
  positions past the end are `zuroar_error_index`. *Deviation
  2026-11-06:* `match()` is dropped from this criterion and `mtfrm()`
  from the work. Base R's `match()` rejects an external pointer before it
  calls `mtfrm()`, so `%in%` cannot work for a bitmap (design §6.6).
- `R CMD check` passes on the quick profile.

**Design.** §5, §6.2, §6.6, D6, D11.

## Stage 5 — Portable serialisation

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
- `roar_serial_config()` for `mirai::daemons(serial = )`; `mirai (>= 2.3.0)`
  in `Suggests`, guarded so the package works without it.

**Exit criteria.**

- Round trips are exact on the generated sets.
- A bitmap round-trips through a local `mirai` daemon with
  `roar_serial_config()` set; the test skips without `mirai`, and the
  `nosuggests` leg passes.
- The `pyroaring` and Java fixtures read to the expected sets.
- Every hostile input is a `zuroar_error_format`, and the ASan, UBSan and
  valgrind legs are clean.
- `roaring_bitmap_portable_deserialize()` does not appear in `src/` outside
  `src/croaring/`.
- A full-profile r-actions run is green.

**Design.** §6.4, §6.5, §8 (interoperability, hostile input, `mirai`),
D5, D8.

## Stage 6 — 64-bit bitmaps

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
  and the full 2^64 range read correctly (D14).
- Documentation that changes to a `zuroar64` copy the whole bitmap (D16).
- Output as decimal text, or double when every value is below 2^53.
- An error for mixing `zuroar` and `zuroar64` in one operation.

**Exit criteria.**

- Every operation matches the oracle on sets with values above 2^32,
  compared as decimal text.
- Non-canonical text and doubles at or above 2^53 are a
  `zuroar_error_value`.
- 64-bit serialisation round-trips and reads the 64-bit fixtures.
- `R CMD check` passes on the quick profile.

**Design.** §2, §6.1, §6.4.

## Stage 7 — README, article and benchmarks

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

## Stage 8 — Full CI

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

## Stage 9 — v0.1.0 readiness

**Issue.** [#11](https://github.com/pedrobtz/zuroar/issues/11), sub-issue of
[v0.1.0](https://github.com/pedrobtz/zuroar/issues/1).

**CI.** `full`.

**Goal.** Only the submission itself is left.

**Work.**

- `Version: 0.1.0` and the matching `NEWS.md` heading.
- `cran-comments.md` listing the r-actions CI legs as test environments.
- The `pkg-critical-review` skill, with its blocking and required findings
  fixed; then the `pkg-cran-review` skill, with every finding resolved.
- `urlchecker::url_check()` and `spelling::spell_check_package()`.

**Exit criteria.**

- `urlchecker::url_check()` and `spelling::spell_check_package()` are
  clean.
- Every `pkg-critical-review` blocking and required finding and every
  `pkg-cran-review` finding is resolved.
- A full-profile r-actions run is green on the release commit.
- The design's §11 acceptance criteria hold.

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

Q1 and Q3 were settled on 2026-11-02 by design D5 and D13.

- **Q4. Settled 2026-11-06 by Stage 1's full run** (#16): no leg's
  compiler mishandles the AVX-512 target regions (gcc16, clang23,
  ubuntu-clang, Rtools on Windows release and devel, macOS clang).
- **Q2** (after 0.1.0). Header and C table, or a second vendored copy in
  `zutable`? Blocks no stage.
- **Q5** (Stage 9). Is v0.1.0 a CRAN submission before a sibling uses it?
  The board's `CRAN intent` records the answer.
