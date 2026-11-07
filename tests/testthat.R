# This file is part of the standard setup for testthat.
# Learn more about the roles of various files in:
# * https://r-pkgs.org/testing-design.html#sec-tests-files-overview
# * https://testthat.r-lib.org/articles/special-files.html

library(zuroar)

# Record in every check log which CRoaring build and SIMD paths ran
# (design §7.4).
str(zuroar_info())

# testthat is in Suggests, so CRAN's NOSUGGESTS check runs without it.
if (requireNamespace("testthat", quietly = TRUE)) {
  library(testthat)
  test_check("zuroar")
}
