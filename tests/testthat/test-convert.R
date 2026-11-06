test_that("as.integer() and as.double() return the values exactly", {
  withr::local_seed(7)
  x <- roar(c(0, 5, 2^31 - 1))
  expect_identical(as.integer(x), c(0L, 5L, .Machine$integer.max))
  expect_identical(as.numeric(x), c(0, 5, 2^31 - 1))
  big <- roar(c(1, 2^31, 4294967295))
  expect_identical(as.double(big), c(1, 2^31, 4294967295))
  expect_identical(as.integer(roar()), integer())
  expect_identical(as.double(roar()), numeric())
})

test_that("as.integer() errors above .Machine$integer.max (D2)", {
  expect_error(as.integer(roar(2^31)), class = "zuroar_error_value")
})

test_that("format() and print() show the class, size, range and values", {
  expect_identical(format(roar()), "<zuroar> empty")
  expect_identical(format(roar(7)), "<zuroar> 1 value in [7, 7]: 7")
  expect_identical(
    format(roar(c(1, 5, 4294967295))),
    "<zuroar> 3 values in [1, 4294967295]: 1 5 4294967295"
  )
  expect_identical(
    format(roar_range(1, 20), n = 3),
    "<zuroar> 20 values in [1, 20]: 1 2 3 ..."
  )
  expect_output(
    print(roar(1:3)),
    "<zuroar> 3 values in [1, 3]: 1 2 3",
    fixed = TRUE
  )
  expect_invisible(print(roar(1)))
})

test_that("print() snapshot", {
  expect_snapshot({
    roar()
    roar(c(1, 5, 9, 100000))
    roar_range(0, 4294967295)
  })
})
