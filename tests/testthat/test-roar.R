test_that("roar() holds sort(unique()) of its input", {
  withr::local_seed(1)
  for (name in names(gen_values())) {
    v <- gen_values()[[name]]
    for (opt in c(TRUE, FALSE)) {
      x <- roar(v, optimize = opt)
      expect_s3_class(x, "zuroar")
      expect_identical(as.double(x), oracle(v), label = name)
      expect_identical(length(x), length(oracle(v)), label = name)
    }
  }
})

test_that("roar() takes integers and doubles alike", {
  expect_identical(as.double(roar(c(3L, 1L, 2L))), c(1, 2, 3))
  expect_identical(as.double(roar(c(3, 1, 2))), c(1, 2, 3))
  expect_identical(length(roar()), 0L)
  expect_identical(length(roar(integer())), 0L)
  expect_identical(length(roar(logical())), 0L)
})

test_that("roar() drops attributes such as names", {
  expect_identical(as.double(roar(c(a = 2, b = 1))), c(1, 2))
})

test_that("roar() rejects values outside the domain", {
  bad <- list(NA_integer_, NA_real_, NaN, -1L, -1, 0.5, 2^32, Inf, -Inf)
  for (v in bad) {
    expect_error(roar(c(1, v)), class = "zuroar_error_value")
  }
  expect_error(roar("1"), class = "zuroar_error_value")
  expect_error(roar(factor(1)), class = "zuroar_error_value")
  expect_error(roar(list(1)), class = "zuroar_error_value")
})

test_that("roar() rejects a logical vector (D13)", {
  expect_error(roar(c(TRUE, FALSE)), class = "zuroar_error_value")
  expect_error(roar(NA), class = "zuroar_error_value")
})

test_that("roar() checks optimize", {
  expect_error(roar(1, optimize = NA), class = "zuroar_error")
  expect_error(roar(1, optimize = "yes"), class = "zuroar_error")
})

test_that("roar_range() is inclusive at both ends", {
  expect_identical(as.double(roar_range(3, 7)), as.double(3:7))
  expect_identical(as.double(roar_range(5, 5)), 5)
  expect_identical(as.double(roar_range(65530, 65545)), as.double(65530:65545))
  top <- 4294967295
  expect_identical(as.double(roar_range(top - 3, top)), (top - 3):top)
  # Above .Machine$integer.max, length() is a double, as for a long vector.
  expect_identical(length(roar_range(0, top)), 2^32)
  expect_identical(length(roar_range(0, 2^31 - 2)), .Machine$integer.max)
  expect_identical(range(roar_range(0, top)), c(0, top))
})

test_that("roar_range() rejects bad ends", {
  expect_error(roar_range(5, 4), class = "zuroar_error_value")
  expect_error(roar_range(-1, 4), class = "zuroar_error_value")
  expect_error(roar_range(0, 2^32), class = "zuroar_error_value")
  expect_error(roar_range(0.5, 4), class = "zuroar_error_value")
  expect_error(roar_range(NA, 4), class = "zuroar_error_value")
  expect_error(roar_range(c(1, 2), 4), class = "zuroar_error_value")
  expect_error(roar_range(TRUE, 4), class = "zuroar_error_value")
})
