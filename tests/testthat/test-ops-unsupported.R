test_that("operators a set does not define are errors (D11)", {
  x <- roar(1:3)
  y <- roar(2:4)
  expect_error(!x, class = "zuroar_error_unsupported")
  expect_error(-x, class = "zuroar_error_unsupported")
  expect_error(x - y, class = "zuroar_error_unsupported")
  expect_error(x^y, class = "zuroar_error_unsupported")
  expect_error(x * y, class = "zuroar_error_unsupported")
  expect_error(x * 2, class = "zuroar_error_unsupported")
  expect_error(5 - x, class = "zuroar_error_unsupported")
  expect_error(x > 5, class = "zuroar_error_unsupported")
  expect_error(5 == x, class = "zuroar_error_unsupported")
  expect_error(x | TRUE, class = "zuroar_error_unsupported")
  expect_error(x & 1, class = "zuroar_error_unsupported")
})

test_that("roar_cardinality() checks op", {
  x <- roar(1)
  expect_error(roar_cardinality(x, x, "union"), class = "zuroar_error")
  expect_error(roar_cardinality(x, 1), class = "zuroar_error")
})

test_that("unsupported operators snapshot", {
  expect_snapshot(error = TRUE, {
    !roar(1)
    roar(1) - roar(2)
    roar(1) > 5
    roar(c(0, 4294967295)) + 1
  })
})
