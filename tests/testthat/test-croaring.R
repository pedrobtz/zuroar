test_that("the vendored CRoaring matches base R on every container mix", {
  withr::local_seed(20261106)
  sets <- gen_sets()
  for (opt in c(FALSE, TRUE)) {
    for (i in names(sets)) {
      for (j in names(sets)) {
        x <- sets[[i]]
        y <- sets[[j]]
        got <- .Call(zuroar:::zro_selftest, x, y, opt)
        label <- paste0(i, " vs ", j, if (opt) " (run-optimised)")
        want_or <- sort(union(x, y))
        want_and <- sort(intersect(x, y))
        want_andnot <- sort(setdiff(x, y))
        want_xor <- sort(c(want_andnot, setdiff(y, x)))
        expect_identical(got$or, want_or, label = label)
        expect_identical(got$and, want_and, label = label)
        expect_identical(got$xor, want_xor, label = label)
        expect_identical(got$andnot, want_andnot, label = label)
        expect_identical(
          got$cardinality,
          as.double(lengths(list(want_or, want_and, want_xor, want_andnot))),
          label = label
        )
        expect_true(got$valid, label = label)
      }
    }
  }
})
