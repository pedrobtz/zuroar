test_that("a bitmap read back by readRDS() errors with zuroar_error_pointer", {
  path <- withr::local_tempfile(fileext = ".rds")
  saveRDS(roar(1:3), path)
  x <- readRDS(path)
  expect_error(length(x), class = "zuroar_error_pointer")
  expect_error(as.double(x), class = "zuroar_error_pointer")
  expect_error(as.integer(x), class = "zuroar_error_pointer")
  expect_error(min(x), class = "zuroar_error_pointer")
  expect_error(roar_contains(x, 1), class = "zuroar_error_pointer")
  expect_error(roar_add(x, 1), class = "zuroar_error_pointer")
  expect_error(roar_remove(x, 1), class = "zuroar_error_pointer")
})

test_that("format() and print() describe a null pointer without failing", {
  path <- withr::local_tempfile(fileext = ".rds")
  saveRDS(roar(1:3), path)
  x <- readRDS(path)
  expect_match(format(x), "null pointer", fixed = TRUE)
  expect_output(print(x), "null pointer", fixed = TRUE)
})

test_that("a pointer error is also a zuroar_error", {
  path <- withr::local_tempfile(fileext = ".rds")
  saveRDS(roar(1), path)
  expect_error(length(readRDS(path)), class = "zuroar_error")
})

test_that("conditions snapshot", {
  expect_snapshot(error = TRUE, {
    roar(c(1, -2))
    roar(c(1, 0.5))
    roar(c(TRUE, FALSE))
    as.integer(roar(2^31))
    sum(roar(1))
  })
})

test_that("pillar abbreviates a bitmap without touching its pointer", {
  skip_if_not_installed("pillar")
  path <- withr::local_tempfile(fileext = ".rds")
  saveRDS(roar(1), path)
  expect_identical(pillar::type_sum(readRDS(path)), "roar")
  expect_identical(pillar::type_sum(roar(1:3)), "roar")
})
