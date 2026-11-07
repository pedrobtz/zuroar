## R CMD check results

0 errors | 0 warnings | 1 note

* This is a new release.

## Test environments

The checks run on GitHub Actions through the reusable workflows of
[pedrobtz/r-actions](https://github.com/pedrobtz/r-actions), each with
`R CMD check --as-cran`:

* macOS (latest), R release
* Windows (latest), R release and R-devel
* Ubuntu (latest), R release and R oldrel-1
* R-devel containers: GCC 16, clang 23 and Ubuntu clang
* R-hub `nosuggests` (only hard dependencies) and `nold` (R built
  without long double)
* AddressSanitizer (GCC and clang), UndefinedBehaviorSanitizer (GCC and
  clang), valgrind, LTO, rchk, `-fanalyzer`, and R's constant checks
* `gctorture` at step 20 over the whole test suite
* Three builds of the bundled CRoaring library, which selects AVX2 and
  AVX-512 code at run time: the default, one without AVX-512, and the
  portable scalar code

## Bundled code

zuroar bundles CRoaring 5.4.0 (`src/croaring/`), used under the MIT side
of its Apache-2.0/MIT dual licence. Its authors are listed as copyright
holders in `Authors@R`, and `inst/COPYRIGHTS` gives the details. One
patch removes its diagnostic-suppressing pragmas; the bundled library
selects its SIMD paths at run time, so `Makevars` sets no architecture
flags.
