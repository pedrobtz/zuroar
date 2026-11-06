test_that("roar_contains() matches %in%", {
  withr::local_seed(5)
  sets <- gen_values()
  probe <- c(sets$boundaries, sets$sparse, 1, 2, 3, 131072 + 0:100)
  for (name in names(sets)) {
    x <- roar(sets[[name]])
    expect_identical(
      roar_contains(x, probe),
      probe %in% sets[[name]],
      label = name
    )
  }
  expect_identical(roar_contains(roar(1), numeric()), logical())
})

test_that("roar_contains() checks values", {
  expect_error(roar_contains(roar(1), -1), class = "zuroar_error_value")
  expect_error(roar_contains(roar(1), TRUE), class = "zuroar_error_value")
})

test_that("min(), max() and range() match base R", {
  withr::local_seed(6)
  sets <- gen_values()
  sets$empty <- NULL
  for (name in names(sets)) {
    v <- sets[[name]]
    x <- roar(v)
    expect_identical(min(x), min(v), label = name)
    expect_identical(max(x), max(v), label = name)
    expect_identical(range(x), range(as.double(v)), label = name)
  }
})

test_that("an empty bitmap has no minimum or maximum", {
  expect_error(min(roar()), class = "zuroar_error_value")
  expect_error(max(roar()), class = "zuroar_error_value")
  expect_error(range(roar()), class = "zuroar_error_value")
})

test_that("other Summary members are unsupported", {
  x <- roar(1:3)
  expect_error(sum(x), class = "zuroar_error_unsupported")
  expect_error(prod(x), class = "zuroar_error_unsupported")
  expect_error(any(x), class = "zuroar_error_unsupported")
  expect_error(min(x, roar(0)), class = "zuroar_error_unsupported")
})
