test_that("roar_add() and roar_remove() match union() and setdiff()", {
  withr::local_seed(2)
  sets <- gen_values()
  for (i in names(sets)) {
    for (j in names(sets)) {
      x <- roar(sets[[i]])
      v <- sets[[j]]
      label <- paste(i, j)
      expect_identical(
        as.double(roar_add(x, v)),
        oracle(union(sets[[i]], v)),
        label = label
      )
      expect_identical(
        as.double(roar_remove(x, v)),
        oracle(setdiff(sets[[i]], v)),
        label = label
      )
    }
  }
})

test_that("roar_add() and roar_remove() leave their argument unchanged", {
  withr::local_seed(3)
  v <- gen_values()$mixed
  x <- roar(v)
  before <- as.double(x)
  y <- roar_add(x, c(1, 2, 3, 4294967295))
  z <- roar_remove(x, v[1:100])
  expect_identical(as.double(x), before)
  expect_false(identical(as.double(y), before))
  expect_false(identical(as.double(z), before))
})

test_that("a copy keeps its values after the bitmap it shares with is gone", {
  withr::local_seed(4)
  v <- gen_values()$mixed
  x <- roar(v)
  y <- roar_add(x, 3)
  z <- roar_remove(y, 3)
  rm(x)
  gc()
  expect_identical(as.double(y), oracle(c(v, 3)))
  rm(y)
  gc()
  expect_identical(as.double(z), oracle(v))
})

test_that("roar_add() and roar_remove() check their input", {
  x <- roar(1:3)
  expect_error(roar_add(x, -1), class = "zuroar_error_value")
  expect_error(roar_remove(x, NA), class = "zuroar_error_value")
  expect_error(roar_add(1:3, 4), class = "zuroar_error")
})
