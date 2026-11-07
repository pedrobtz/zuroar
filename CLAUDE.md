# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working
with code in this repository.

## What this is

`zuroar` gives R compressed sets of unsigned integers by wrapping
[CRoaring](https://github.com/RoaringBitmap/CRoaring), the reference C
implementation of Roaring bitmaps. A `zuroar` bitmap holds values from 0
to 2^32 - 1 and a `zuroar64` bitmap values up to 2^64 - 1. Both answer
membership, cardinality, rank, select and the set operations without
materialising a vector, and serialise to the portable Roaring format
that Java, Go, Rust, Python and C share. To R code a bitmap looks like a
sorted vector without duplicates (`x[i]`,
[`head()`](https://rdrr.io/r/utils/head.html),
[`c()`](https://rdrr.io/r/base/c.html)), and its API covers what
pyroaring offers, in R form (design §5.1). It has no `Imports` and no
`LinkingTo`; `testthat` and `mirai` are in `Suggests`. It is not a
general set package, not a bit vector (no universe or `[<-`), not an
algorithm library (every set operation is CRoaring’s) and, in v0.1.0,
not a C API.

The specification is
[`.agents/design.md`](https://pedrobtz.github.io/zuroar/.agents/design.md),
adopted from [RFC
0061](https://github.com/pedrobtz/packages/blob/main/rfcs/started/0061-zuroar-roaring-bitmaps.md).
It outranks this file: `CLAUDE.md` orients, the design doc decides. Its
decisions D1 to D16 are the maintainer’s to overturn; open questions Q2
and Q5 are still open.

## Current state

Scaffolded 2026-11-01 with `create-pkg.sh` (C, `use_c()`). Stages 0 to 4
merged on 2026-11-06: identity, vendored CRoaring, the `zuroar` class,
its set algebra, and the switch from an external pointer to an ALTREP
vector (design D17, re-planned the same day). The later stages, already
written on the pointer in the `stage-*-wip` branches and pull request
\#19, rebase onto it. The roadmap in `.agents/roadmap.md` takes it to
v0.1.0.

## Stage tracking

Progress toward the next version is tracked as GitHub sub-issues, so the
parent issue shows a progress bar such as “6 of 7”.

- **One parent issue per target version**, titled with the bare version,
  for example `v0.1.0`. `v0.1.0` issue: created by `pkg-roadmap`.
- **One sub-issue per roadmap stage**, titled as the roadmap titles it,
  for example `Stage 3 — R interface`, and linking to that section. The
  number of stages is whatever the roadmap has; there is no fixed scale.
- **Every tracking issue carries the `stage` label**, so it can be told
  apart from bug and feature issues and left out of open-issue counts.
- **Close a stage by merging its pull request.** Put `Closes #<n>` in
  the body of the stage’s pull request. Never close a stage whose exit
  criteria are not met; record a deviation in the roadmap first.
- **The roadmap stays authoritative.** The issues record which stages
  are done, not what a stage requires. Adding, removing or renaming a
  stage means editing the roadmap and the sub-issues in the same change.
- **Each stage has a CI tier, `quick` or `full`.** The roadmap sets it,
  and `quick` is the default. See Continuous integration for what each
  means. The second-to-last stage, `Full CI`, runs the full set and
  fixes what it finds before `v0.1.0 readiness`.
- Close the parent issue when CRAN accepts the version and it is tagged.
  Opening a parent issue implies at least one stage sub-issue; a parent
  with no sub-issues shows no progress on the board.

## Versioning

A new package develops at `0.0.0.9000` and targets `0.1.0` for its first
CRAN release. Set `Version: 0.1.0` and the matching `NEWS.md` heading
when the package enters `Pre-flight`. Bump to `0.1.0.9000` only after
CRAN accepts it, never before: a `.9000` version above an unreleased
`0.1.0` heading is wrong.

Until the first release the R API may change freely. Sibling packages
can still depend on this one before CRAN does, through `Remotes:` or
`LinkingTo:`. None does yet. The design names `zutable` and `zusearch`,
both proposed, as likely callers through `Suggests`; whether `zutable`
would link to a `zuroar` header is open question Q2. A package that
others wait on should reach CRAN first.

## Commands

Run from the package root.

``` sh
Rscript -e 'devtools::load_all()'                # compile src/ and load
Rscript -e 'devtools::document()'                # roxygen -> NAMESPACE, man/
Rscript -e 'devtools::test()'                    # full testthat suite
Rscript -e 'devtools::test(filter = "<name>")'   # one test file
Rscript -e 'devtools::test(shuffle = TRUE)'      # order independence
Rscript -e 'devtools::check()'                   # R CMD check
air format .                                     # format R sources
```

## Architecture

Grows as stages land; see `.agents/design.md` §4.

- `src/croaring/`: CRoaring’s `roaring.c` and `roaring.h`, upstream plus
  one patch. R compiles only top-level `src/*.c`, so nothing here builds
  on its own.
- `src/zro_roaring.h`: the only way first-party C includes CRoaring. It
  sets `NDEBUG`, includes every system header CRoaring uses, defines
  `printf` as `Rprintf` while `roaring.h` is parsed, and hides
  CRoaring’s declarations.
- `src/zro_roaring.c`: the wrapper unit, the only includer of
  `roaring.c`.
- `src/zro_init.c`, `src/zro_init.h`: routine registration and the
  `.Call` prototypes.
- `src/zro_altrep.c`: the representation (D17). A `zuroar` is an ALTREP
  double vector; its `data1` is an external pointer, with a finaliser,
  to a `zro_bitmap_t` holding the CRoaring bitmap, its cached
  cardinality and a read cursor. `zro_shell()`, `zro_attach()` and
  `zro_get()` live here with the methods: `Length`, `Elt`, `Get_region`
  and `Sum` read through CRoaring; `Dataptr` refuses; `Extract_subset`
  builds `x[i]`; `Duplicate` is a copy-on-write copy; `Serialized_state`
  and `Unserialize` are the portable bytes. Three `zro_test_*` routines
  exist for the tests only.
- `src/zro_bitmap.c`, `src/zro_bitmap.h`: the 32-bit bindings and the
  bounded reader `zro_portable_read()`. Entry points allocate the result
  shell first (`zro_shell()`), then build the bitmap, then
  `zro_attach()` it, so no R allocation can leak one. `zro_get()` checks
  the class and `zro_abort()` signals a classed condition through the
  R-level `zro_abort()`.
- `R/roar.R`, `R/methods.R`, `R/check.R`, `R/conditions.R`:
  constructors,
  [`roar_add()`](https://pedrobtz.github.io/zuroar/reference/roar_add.md)/[`roar_remove()`](https://pedrobtz.github.io/zuroar/reference/roar_add.md)/[`roar_contains()`](https://pedrobtz.github.io/zuroar/reference/roar_contains.md),
  the vector methods, type checks (the C side checks each value), and
  the condition helper.
- `src/zro_algebra.c`, `R/algebra.R`: `Ops`,
  [`c()`](https://rdrr.io/r/base/c.html), the named set operations,
  cardinality-only counts and shifting. Out-of-domain shifts are decided
  in R from [`min()`](https://rdrr.io/r/base/Extremes.html) and
  [`max()`](https://rdrr.io/r/base/Extremes.html) before CRoaring’s
  `add_offset()`, which drops silently.
- `src/zro_info.c`, `R/info.R`:
  [`zuroar_info()`](https://pedrobtz.github.io/zuroar/reference/zuroar_info.md).
- `src/zro_selftest.c`: an unexported oracle hook,
  `.Call(zro_selftest, x, y, optimize)`, so the build variants test
  CRoaring before the bindings exist.
- `R/zuroar-package.R` carries
  `@useDynLib zuroar, .registration = TRUE`.

## Invariants that are easy to break

These are fixed by the design before any code exists. Add each further
one when a stage establishes it.

- **No R API inside a CRoaring call.** Bindings validate R input, copy
  it into a `uint32_t` or `uint64_t` buffer, call CRoaring, then copy
  out. An R error raised in between would long-jump through CRoaring’s
  stack and leak or corrupt its state (design §4).
- **Untrusted bytes go only through the bounded path:**
  `roaring_bitmap_portable_deserialize_size()`, then
  `..._deserialize_safe()`, then `roaring_bitmap_internal_validate()`.
  The unsafe `roaring_bitmap_portable_deserialize()` is never called; it
  reads past the buffer on corrupt input (D8, §6.4).
- **Values stay exact.** No silent `NA` and no inexact double: a value
  that does not fit the requested type is a `zuroar_error_value` (D2).
- **Every function returns a new bitmap** and none modifies its
  argument; copy-on-write keeps that cheap (D4). An in-place shortcut
  changes a value another R variable still holds.
- **A `zuroar` is an ALTREP vector whose `Dataptr` never returns** (D17,
  design §4, §14): it signals `zuroar_error_unsupported`, so no base or
  third-party C can expand the set, and `Dataptr_or_null` returns
  `NULL`. Its `Serialized_state` writes portable bytes and `Unserialize`
  reads them through the bounded path, so
  [`saveRDS()`](https://rdrr.io/r/base/readRDS.html) works. Consequences
  to keep in mind: `identical(x, y)` is that error (use `==`), and so is
  `expect_identical()` on two bitmaps; base `[` drops the class of what
  `Extract_subset` returns, so `[.zuroar` puts it back;
  [`sum()`](https://rdrr.io/r/base/sum.html) goes through the `Sum`
  method, every other Summary member through `Summary.zuroar`.
- **An attached bitmap is never modified.** `zro_attach()` is the last
  write; every binding builds a new bitmap (D4). The read cursor in
  `zro_bitmap_t` holds a CRoaring iterator into the containers, and
  copy-on-write copies wrap containers without moving them, so the
  cursor stays valid for the bitmap’s life. An in-place CRoaring call on
  an attached bitmap would silently corrupt it.
- **ALTREP methods allocate nothing they do not protect, and call no R
  API while CRoaring runs.** `Get_region` and `Elt` allocate nothing;
  `Extract_subset`, `Duplicate` and `Unserialize` follow the shell-then-
  attach order; `Dataptr` may signal (R’s own compact sequences do). A
  `zuroar64` stays an external pointer, and **every entry point checks
  it for null**, which is what it becomes after
  [`readRDS()`](https://rdrr.io/r/base/readRDS.html), erroring with
  `zuroar_error_pointer` naming `roar_serialize()` (D5). Skipping the
  check is a segfault.
- **R conventions at the boundary:** ranges are inclusive and become
  CRoaring’s half-open `[min, max)`; `roar_select()` counts from 1 where
  CRoaring counts from 0 (D6). Off-by-one errors here pass most tests.
- **No architecture flags in `Makevars`.** No `-mavx2` or `-march`; SIMD
  comes from CRoaring’s run-time dispatch (D3). CRAN rejects such flags.
- **CRoaring’s symbols stay hidden.** The wrapper unit is the only
  includer of `roaring.c` and brackets it with
  `#pragma GCC visibility push(hidden)`. Exported `roaring_*` names
  would clash with a sibling’s vendored copy in the same session.
- **Vector meaning never silently overrides set meaning.** Where the two
  collide ([`rev()`](https://rdrr.io/r/base/rev.html), `[<-`, `x > 5`, a
  shift out of the domain), the result is an error, not a conversion to
  a plain vector or a dropped value (D11, D12).
- **No `Imports`.** A runtime dependency needs a design decision first.
- **[`format()`](https://rdrr.io/r/base/format.html),
  [`print()`](https://rdrr.io/r/base/print.html) and `type_sum()` never
  signal.** R, testthat and rlang format objects while handling a
  condition; a second error there escapes the handler. For a `zuroar64`
  they describe a null pointer instead, and the lazily registered
  [`pillar::type_sum()`](https://pillar.r-lib.org/reference/type_sum.html)
  method keeps rlang’s backtraces from calling
  [`length()`](https://rdrr.io/r/base/length.html) on one (design §6.6).
- **Allocate the shell before the bitmap.** `zro_shell()`, then the
  CRoaring call, then `zro_attach()`. `zro_abort()` only when every
  bitmap is attached or freed.
- **Include CRoaring only through `zro_roaring.h`, and R headers after
  it.** It must include each system header CRoaring uses before the
  hidden region. Under `#pragma GCC visibility push(hidden)`, a libc
  declaration seen for the first time would be marked hidden too; GCC
  hides a re-declaration as well, which is why `zro_roaring.h` routes
  every `posix_memalign` declaration in the hidden regions to a static
  forwarder. The prelude must mirror `roaring.h`’s includes, under the
  same conditions or wider. Clang accepts what GCC rejects here, so a
  macOS build proves nothing. `printf` is undefined again after
  `roaring.h`, except in the wrapper unit; left defined, it rewrites the
  `format(printf, ...)` attributes in R’s headers.

## Testing conventions

- **Self-sufficient.** Every test builds its own inputs inside the
  `test_that()` block. No file-scope objects.
- **Self-contained.** Global state goes through `withr::local_*()`,
  randomised input through
  [`withr::local_seed()`](https://withr.r-lib.org/reference/with_seed.html).
  Tests write only under
  [`tempdir()`](https://rdrr.io/r/base/tempfile.html).
- **Assert on condition classes, never message text.** Use
  `expect_error(..., class = "<pkg>_<kind>_error")`. Wording belongs in
  snapshot tests.
- **Order independence.** `devtools::test(shuffle = TRUE)` is part of
  the definition of done.
- **Borrow a conformance suite before writing one.** Mainstream
  implementations in Python, Java, Go or Node usually ship a test
  corpus. Use it as an oracle rather than inventing cases by hand. Here
  base R ([`union()`](https://rdrr.io/r/base/sets.html),
  [`intersect()`](https://rdrr.io/r/base/sets.html),
  [`setdiff()`](https://rdrr.io/r/base/sets.html), `%in%`,
  [`findInterval()`](https://rdrr.io/r/base/findInterval.html)) is the
  oracle for every operation, and portable-format fixtures written by
  `pyroaring` and Java’s RoaringBitmap, with their generating scripts,
  are planned for Stage 5 (design §8).
- **Helpers live in `tests/testthat/helper-*.R`.** `helper-sets.R` has
  `gen_values()`, sets that hit each container kind and the boundaries
  at 2^16, 2^31 and 2^32 - 1, and `oracle()`, which is `sort(unique())`.
  Call them inside `test_that()` after
  [`withr::local_seed()`](https://withr.r-lib.org/reference/with_seed.html).
- **[`length()`](https://rdrr.io/r/base/length.html) is an integer when
  it fits.** R’s dispatch converts a method’s double; compare with
  `length(oracle(v))`, not a double.
- **Keep the suite inside the CRAN time budget.** It runs in seconds.

## Definition of done

`devtools::document()` and `devtools::check()` clean, meaning 0 errors,
0 warnings and 0 notes. The one allowed note is “New submission” before
the first release. `devtools::test(shuffle = TRUE)` green. CI green at
the change’s tier: the quick profile for a `quick` roadmap stage or an
ordinary pull request, the full profile for a `full` stage, `Full CI`,
and every release. A user-facing change also needs a test, roxygen
documentation and a `NEWS.md` entry.

## Releasing to CRAN

- **CI is the pre-submission check.** The `pedrobtz/r-actions` R CMD
  check runs `--as-cran` on the CRAN-like runners and containers, and it
  replaces win-builder, the macOS builder and R-hub. None of them is a
  release step, and `cran-comments.md` lists the CI legs as its test
  environments.
- **Entering `Pre-flight`.** The roadmap’s feature stages are done, the
  version is set as in Versioning, `NEWS.md` and `cran-comments.md` are
  written, and CI is green. Only submission work remains.
- **Before submitting,** run `pkg-critical-review` once the roadmap is
  implemented and fix what it files, then `pkg-cran-review`, and resolve
  every finding. Both skills are in `pedrobtz/r-skills`.
- **The pretest is automated and does not read `cran-comments.md`.** A
  NOTE that is explained but not fixed gets the upload archived. Fix the
  NOTE, as under Vendored native code, instead of justifying it.
- **After acceptance,** `pkg-post-cran` tags the submitted commit with
  the bare version, `0.1.0` (no `v`), publishes the GitHub release,
  bumps to `0.1.0.9000`, closes the version’s parent issue and moves the
  board card.

## Editing rules

- roxygen comments are the source. Never edit `man/` or `NAMESPACE` by
  hand.
- Edit `README.Rmd`, not the generated `README.md`.
- Keep prose simple and short. One idea per sentence.
- Wrap roxygen text at 80 characters and run `air format .` on R
  sources.
- Use `lower_snake_case`, and prefix internal native symbols with
  `<pkg>_`.
- Keep hard runtime dependencies at zero unless a recorded design
  decision says otherwise.
- Export and document public functions. Do not create roxygen topics for
  internal ones.

## Continuous integration

Workflows come from `pedrobtz/r-actions`. Call those reusable workflows
instead of writing bespoke ones, and pin a released tag rather than
`main`. Pin a workflow that holds a write token, such as `coverage.yml`,
to a commit, with the tag in a comment. The `R-CMD-check` workflow must
call `r-cmd-check.yml`, because a hand-rolled one does not count as the
pre-submission check. This package calls `r-cmd-check.yml@v1`;
`coverage.yml` and `vendor-upstream.yml` (write tokens) pinned to the
`v1` commit; `native-checks.yaml` (sanitizers, valgrind, LTO, rchk,
analyzers, cran-special), `gctorture.yaml` and `vendor.yaml` at `@v1`.
`build-variants.yaml` is the package’s own development-only job (design
§7.4): it builds the default, no-AVX-512 and scalar variants, runs
`tools/check-symbols` and the tests on each. `pkgdown.yaml` is the r-lib
example workflow.

Small edits get a small run. The shared workflows look at the files a
pull request changes, compared with its merge base:

- **Markdown only**, such as `README.md`, `NEWS.md` or
  `cran-comments.md`, skips every check. Only coverage and the pkgdown
  site run.
- **`DESCRIPTION` or `README.Rmd` as well**, and nothing else, adds one
  R CMD check on Ubuntu R-release.
- **Any other file** runs everything.

So put a README or `DESCRIPTION` touch-up in its own pull request. Once
a pull request changes code, every later push to it runs every workflow.

### Quick by default, full by exception

The full profile is slow. gctorture at step 20 alone has taken 36 to 107
minutes on sibling packages. Waiting on it between roadmap stages was
the main thing slowing roadmaps down, so:

- **Pull requests run the quick profile.** It should finish in under
  five minutes. Here `-fanalyzer` (about 15 minutes over the
  amalgamation) runs on a pull request only with the `full-ci` label,
  and on every push to `main` (2026-11-06, Stage 3). Runner set-up
  (`setup-r`, apt) has taken 20 minutes on a bad day; that is the
  runner, not the profile. If it doesn’t, raise gctorture’s `quick-step`
  or trim `quick-containers` in the caller workflows; never cut the full
  profile.
- **A `full` roadmap stage takes the `full-ci` label** and merges only
  on a green full run. The roadmap gives the reason in the stage’s
  `**CI.**` line, for example first compiled code, a `PROTECT` or
  finalizer change, a vendored library, or a Windows-only path.
- **Don’t wait on the full run a merge starts** on the default branch,
  and cancel older full runs it supersedes. A failure that only the full
  set shows goes on the `Full CI` stage issue as a comment with the run
  link, and is fixed there. A failure the quick profile also shows is
  fixed now.
- **`Full CI` and `v0.1.0 readiness` wait** for a green full run on
  their merge commit, and the release commit always needs one.
- Locally, run `gctorture(TRUE)` on the code a C change touches when it
  is cheap; the full run is the authority.

## Vendored native code

CRoaring 5.4.0 (tag `v5.4.0`, commit
`20495fec4d1622b93284033a160f67d21a5aa8bb`), the `roaring.c` and
`roaring.h` amalgamation, used under the MIT side of its Apache-2.0/MIT
dual licence (D9). Vendored in Stage 1.

- **Layout.** `src/croaring/` holds `roaring.c`, `roaring.h`, upstream
  `LICENSE` and `AUTHORS`. `inst/COPYRIGHTS` and the `cph` entry in
  `DESCRIPTION` declare it.
- **Pins.** `vendor.yaml` (not `src/vendor/PROVENANCE`) records the tag,
  the commit, the SHA-256 of all four files, and the patch series, with
  the update procedure in its header comment.
- **The one patch.**
  `tools/patches/0001-remove-diagnostic-pragmas.patch` deletes the six
  `#pragma GCC diagnostic` blocks, four in `roaring.c` and two in
  `roaring.h`. `printf` is handled by the macro in `zro_roaring.h`
  instead of a patch; `tools/check-symbols` proves no `printf` is
  linked.
- **Verification.** `tools/verify-vendor` derives the tree from upstream
  plus the patches and compares it byte for byte. `--canary` must fail,
  and `--write` re-derives the tree for a bump. The `vendor` workflow
  runs it on every push and requires a change to `src/croaring/` to
  change `vendor.yaml` too. `vendor-upstream` opens an issue weekly when
  CRoaring releases.
- **Symbols.** `tools/check-symbols` runs after each build variant in
  the `build-variants` workflow. It fails on stdio, `abort`, `exit` or
  RNG references and on any exported CRoaring symbol.
- `tools/`, `vendor.yaml` and the patches are build-ignored; the tarball
  ships only the patched result.

General rules for vendored code:

- Pin a stable upstream release, never `master` or a release candidate.
- Record the tag, the commit and the checksums, and write down the
  update procedure so the next bump is mechanical.
- Keep upstream `LICENSE` and `NOTICE` beside the vendored code, declare
  the vendored code in `DESCRIPTION` and `inst/COPYRIGHTS`.
- Keep the vendor tree clearly separated from first-party source, and
  record every local patch and why it exists.
- **CRAN’s compiled-code check applies to vendored code too.** No
  `stdout` or `stderr`, no `printf`, `abort`, `exit` or system RNG may
  be linked, even behind a debug switch that never runs. Remove them
  with a patch in `tools/patches/`, list it in `vendor.yaml`, and make
  the vendor-verify script check “upstream plus exactly these patches”.
  Avoid diagnostic-suppressing pragmas too, because they draw their own
  NOTE. zuhtml is the reference: `tools/patches/0002-no-stdio.patch` and
  `tools/verify-vendor`. zuxml’s first upload was archived because it
  justified such a symbol instead of patching it.
- Guard against regressions in CI: run `nm -u` on the built objects and
  fail on any of those symbols, so an upstream bump cannot bring them
  back.

## Commits and pull requests

Short, imperative, sentence-case commit subjects, optionally scoped.
Keep each commit focused and do not sweep in unrelated files. A pull
request explains the user-visible outcome and the rationale, links
related issues, lists the checks that were run and the tests that were
skipped, and flags platform-sensitive or vendored changes. Performance
claims need evidence.

Never commit or push to the default branch. Work on a branch, open a
pull request, and leave it for review. Do not merge a pull request
unless you are told to.

When you find a defect, in this package or in an upstream tool, open an
issue for it rather than only working around it.

## Working with skills

The portfolio’s workflow skills live in `pedrobtz/r-skills` (`pkg-init`,
`pkg-roadmap`, `pkg-implement`, `pkg-critical-review`,
`pkg-cran-review`, `pkg-post-cran`, `pkg-readme`); the general process
skills are [Superpowers](https://github.com/obra/superpowers).
`building-a-package.md` in `pedrobtz/packages` walks through them in
order. Both sets defer to this file where they overlap, so the
settlements are recorded here.

- **One design.** The specification is `.agents/design.md`, adopted from
  the package’s RFC in `pedrobtz/packages/rfcs`. A package with an
  adopted design is past `brainstorming`; a design change goes through
  the RFC, not a new spec. Superpowers’ default
  `docs/superpowers/specs/` is not used.
- **Plans at two levels.** `.agents/roadmap.md` holds the stages, one
  mergeable pull request each, with exit criteria and a CI tier
  (`pkg-roadmap`). Inside a stage, `writing-plans` breaks the work into
  tasks of one test cycle each, saved as `.agents/plans/stage-<n>.md`.
  The roadmap stays authoritative; a plan is scratch and is not kept in
  sync.
- **Build and merge.** `pkg-implement` runs the stage loop: branch
  `stage-<n>-<slug>` from the stage issue, implement the plan with
  `test-driven-development`
  (`Rscript -e 'devtools::test(filter = "<name>")'` is the red/green
  command), open the pull request, merge on green at the stage’s CI
  tier. The confirmation the user gives at the start of that loop is the
  “told to merge” that Commits and pull requests requires, so the
  `finishing-a-development-branch` menu is not presented for stage pull
  requests. Any other pull request still waits for review.
- **Failures and claims.** A failing check or test goes through
  `systematic-debugging` before a fix. “Green”, “done” and “ready for
  CRAN” are claimed only after `verification-before-completion`: run the
  command, read the output.
- **Review.** `requesting-code-review` gates tasks inside a stage.
  `pkg-critical-review` reviews the whole package once the roadmap is
  implemented, with Posit’s reviewers, and files issues. CRAN’s reviewer
  email and GitHub review threads go through `receiving-code-review`.
- **Keep scratch out of the tarball.** `R CMD build` reads
  `.Rbuildignore`, not `.gitignore`. It must list `^\.agents$`,
  `^\.superpowers$` (the Superpowers task ledger), `^\.worktrees$` (if
  git worktrees are kept in the package directory; a sibling directory
  avoids the question), `^\.claude$`, `^CLAUDE\.md$`, `^AGENTS\.md$`,
  `^CRAN-SUBMISSION$` and `^cran-comments\.md$`. A stray top-level file
  is a NOTE, and the pretest archives on NOTEs.
