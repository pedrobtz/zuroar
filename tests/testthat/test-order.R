test_that("roar_rank() matches findInterval()", {
  withr::local_seed(20)
  sets <- gen_values()
  probe <- c(0, 1, 7, 65535, 65536, 2^31, 4294967295, sample(2^32 - 1, 200))
  for (name in names(sets)) {
    s <- oracle(sets[[name]])
    x <- roar(s)
    expect_identical(
      roar_rank(x, probe),
      as.double(findInterval(probe, s)),
      label = name
    )
  }
})

test_that("roar_select() inverts roar_rank() for every value", {
  withr::local_seed(21)
  for (name in names(gen_values())) {
    s <- oracle(gen_values()[[name]])
    x <- roar(s)
    expect_identical(roar_select(x, roar_rank(x, s)), s, label = name)
    expect_identical(roar_select(x, seq_along(s)), s, label = name)
  }
})

test_that("roar_select() and [[ count from 1 and check positions", {
  x <- roar(c(1, 7, 9, 4294967295))
  expect_identical(roar_select(x, 1), 1)
  expect_identical(roar_select(x, 4), 4294967295)
  expect_identical(x[[2]], 7)
  expect_identical(roar_select(x, numeric()), numeric())
  for (k in list(0, 5, -1, NA, 1.5, "1")) {
    expect_error(roar_select(x, k), class = "zuroar_error_index")
    expect_error(x[[k]], class = "zuroar_error_index")
  }
  expect_error(x[[c(1, 2)]], class = "zuroar_error_index")
  expect_error(roar()[[1]], class = "zuroar_error_index")
})

test_that("roar_next() and roar_prev() match the oracle, with NA when none", {
  withr::local_seed(22)
  sets <- gen_values()
  probe <- c(0, 1, 7, 65535, 65536, 2^31, 4294967295, sample(2^32 - 1, 100))
  nxt <- function(s, v) {
    vapply(
      v,
      function(p) {
        a <- s[s >= p]
        if (length(a)) a[1] else NA_real_
      },
      numeric(1)
    )
  }
  prv <- function(s, v) {
    vapply(
      v,
      function(p) {
        a <- s[s <= p]
        if (length(a)) a[length(a)] else NA_real_
      },
      numeric(1)
    )
  }
  for (name in names(sets)) {
    s <- oracle(sets[[name]])
    x <- roar(s)
    expect_identical(roar_next(x, probe), nxt(s, probe), label = name)
    expect_identical(roar_prev(x, probe), prv(s, probe), label = name)
  }
})

test_that("roar_count() and roar_contains_range() take inclusive ranges", {
  withr::local_seed(23)
  top <- 4294967295
  ranges <- list(
    c(0, 0),
    c(0, 10),
    c(65530, 65545),
    c(2^31 - 1, 2^31),
    c(top - 100, top),
    c(top, top),
    c(0, top),
    c(200000, 260000)
  )
  for (name in names(gen_values())) {
    s <- oracle(gen_values()[[name]])
    x <- roar(s)
    for (r in ranges) {
      label <- paste(name, r[1], r[2])
      n <- sum(s >= r[1] & s <= r[2])
      expect_identical(roar_count(x, r[1], r[2]), as.double(n), label = label)
      expect_identical(
        roar_contains_range(x, r[1], r[2]),
        n == r[2] - r[1] + 1,
        label = label
      )
    }
  }
  expect_true(roar_contains_range(roar_range(1, 1e6), 1, 9))
  expect_error(roar_count(roar(1), 5, 4), class = "zuroar_error_value")
})

test_that("roar_add() and roar_remove() take inclusive ranges", {
  top <- 4294967295
  x <- roar(c(5, 100))
  expect_identical(
    as.double(roar_add(x, from = 0, to = 3)),
    c(0, 1, 2, 3, 5, 100)
  )
  expect_identical(
    as.double(roar_add(x, from = top - 1, to = top)),
    c(5, 100, top - 1, top)
  )
  y <- roar_range(0, 20)
  expect_identical(as.double(roar_remove(y, from = 0, to = 18)), c(19, 20))
  expect_identical(
    length(roar_remove(roar_range(0, top), from = 0, to = top)),
    0L
  )
  expect_identical(length(roar_add(roar(), from = 0, to = top)), 2^32)
  expect_identical(
    as.double(roar_remove(y, from = 5, to = 5)),
    as.double(setdiff(0:20, 5))
  )
  # x unchanged
  expect_identical(as.double(x), c(5, 100))
})

test_that("roar_add() and roar_remove() take values or a range, not both", {
  x <- roar(1)
  expect_error(roar_add(x), class = "zuroar_error")
  expect_error(roar_add(x, 2, from = 1, to = 3), class = "zuroar_error")
  expect_error(roar_remove(x, from = 1), class = "zuroar_error")
  expect_error(roar_add(x, from = 3, to = 1), class = "zuroar_error_value")
})

test_that("roar_values() returns at most n values from `from`", {
  withr::local_seed(24)
  for (name in names(gen_values())) {
    s <- oracle(gen_values()[[name]])
    x <- roar(s)
    for (from in c(0, 65536, 2^31, 4294967295)) {
      for (n in c(0, 1, 5, 5000, Inf)) {
        want <- head(s[s >= from], n)
        expect_identical(
          roar_values(x, from = from, n = n),
          want,
          label = paste(name, from, n)
        )
      }
    }
  }
  y <- roar_range(1, 1e6)
  expect_identical(roar_values(y, from = 500, n = 3, type = "integer"), 500:502)
  expect_error(
    roar_values(roar(2^31), n = 1, type = "integer"),
    class = "zuroar_error_value"
  )
  expect_identical(roar_values(roar(c(1, 2^31)), n = 1, type = "integer"), 1L)
  expect_error(roar_values(y), class = "zuroar_error_value")
  expect_error(roar_values(y, n = -1), class = "zuroar_error_value")
  expect_error(roar_values(y, n = 1.5), class = "zuroar_error_value")
  expect_error(roar_values(y, n = 1, type = "char"), class = "zuroar_error")
})

test_that("roar_optimize(), roar_stats() and roar_size() describe storage", {
  x <- roar(c(1:10, 100000:200000), optimize = FALSE)
  st <- roar_stats(x)
  expect_named(st, c("kind", "containers", "values", "bytes"))
  expect_identical(st$kind, c("array", "bitset", "run"))
  expect_identical(sum(st$values), as.double(length(x)))
  o <- roar_optimize(x)
  expect_true(o == x)
  expect_gt(roar_stats(o)$containers[3], 0)
  expect_lt(roar_size(o), roar_size(x))
  full <- roar_stats(roar_range(0, 4294967295))
  expect_identical(sum(full$values), 2^32)
  expect_type(roar_size(roar()), "double")
})
