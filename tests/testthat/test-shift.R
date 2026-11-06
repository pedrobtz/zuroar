test_that("x + k, k + x and x - k shift every value", {
  withr::local_seed(16)
  v <- oracle(c(0, 65535, 65536, 2^31, sample(1e6, 100)))
  x <- roar(v)
  expect_identical(as.double(x + 10), v + 10)
  expect_identical(as.double(10 + x), v + 10)
  expect_identical(as.double(x + 10L), v + 10)
  expect_identical(as.double((x + 1000) - 1000), v)
  expect_identical(as.double(x - 0), v)
  expect_identical(as.double(roar_shift(x, 70000)), v + 70000)
})

test_that("(x + k) - k is x when no value leaves the domain", {
  withr::local_seed(17)
  for (v in gen_values()) {
    x <- roar(v)
    top <- 4294967295
    k <- if (length(v) == 0) 5 else min(1000, top - max(v))
    expect_true((x + k) - k == x)
  }
})

test_that("a shift out of the domain is an error unless drop = TRUE", {
  top <- 4294967295
  x <- roar(c(0, 10, top - 5))
  expect_error(x + 6, class = "zuroar_error_value")
  expect_error(x - 1, class = "zuroar_error_value")
  expect_error(roar_shift(x, -1), class = "zuroar_error_value")
  expect_error(roar_shift(x, 2^33), class = "zuroar_error_value")
  expect_identical(as.double(roar_shift(x, 6, drop = TRUE)), c(6, 16))
  expect_identical(as.double(roar_shift(x, -5, drop = TRUE)), c(5, top - 10))
  expect_identical(length(roar_shift(x, 2^33, drop = TRUE)), 0L)
  expect_identical(length(roar_shift(x, -2^33, drop = TRUE)), 0L)
  expect_identical(as.double(roar_shift(x, 5)), c(5, 15, top))
})

test_that("a shift of an empty bitmap is empty", {
  expect_identical(length(roar() + 5), 0L)
  expect_identical(length(roar_shift(roar(), -5)), 0L)
})

test_that("the shift must be a single whole number", {
  x <- roar(1:3)
  expect_error(x + 0.5, class = "zuroar_error_value")
  expect_error(x + c(1, 2), class = "zuroar_error_value")
  expect_error(x + NA, class = "zuroar_error_value")
  expect_error(roar_shift(x, "1"), class = "zuroar_error_value")
  expect_error(roar_shift(x, 1, drop = NA), class = "zuroar_error")
})
