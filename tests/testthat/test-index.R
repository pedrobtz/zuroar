test_that("x[i] matches s[i] for positive, negative and logical i", {
  withr::local_seed(30)
  for (name in names(gen_values())) {
    s <- oracle(gen_values()[[name]])
    x <- roar(s)
    for (i in index_cases(length(s))) {
      got <- x[i]
      expect_s3_class(got, "zuroar")
      expect_identical(
        as.double(got),
        sort(unique(s[i])),
        label = paste(name, deparse(head(i, 4)))
      )
    }
    expect_identical(as.double(x[]), s, label = name)
  }
})

test_that("a long run of positions selects through a range", {
  s <- as.double(c(5:100000, 300000:400000))
  x <- roar(s)
  expect_identical(as.double(x[10:150000]), s[10:150000])
  expect_identical(as.double(x[-(10:150000)]), s[-(10:150000)])
  y <- roar_range(0, 4294967295)
  expect_identical(range(y[-c(1, 2^32)]), c(1, 4294967294))
  expect_identical(length(y[-c(1, 2^32)]), 2^32 - 2)
})

test_that("bad positions are zuroar_error_index", {
  x <- roar(c(1, 7, 9))
  expect_error(x[c(1, -2)], class = "zuroar_error_index")
  expect_error(x[NA], class = "zuroar_error_index")
  expect_error(x[c(1, NA)], class = "zuroar_error_index")
  expect_error(x[4], class = "zuroar_error_index")
  expect_error(x[-4], class = "zuroar_error_index")
  expect_error(x[c(TRUE, FALSE, TRUE, TRUE)], class = "zuroar_error_index")
  expect_error(x["a"], class = "zuroar_error_index")
  expect_error(x[1, 2], class = "zuroar_error_index")
})

test_that("head() and tail() follow R's rules for n", {
  withr::local_seed(31)
  for (name in names(gen_values())) {
    s <- oracle(gen_values()[[name]])
    x <- roar(s)
    for (n in c(0, 1, 3, 6, 1e6, -1, -3, -1e6)) {
      expect_identical(
        as.double(head(x, n)),
        head(s, n),
        label = paste(name, n)
      )
      expect_identical(
        as.double(tail(x, n)),
        tail(s, n),
        label = paste(name, n)
      )
    }
    expect_identical(as.double(head(x)), head(s), label = name)
  }
  expect_error(head(roar(1), NA), class = "zuroar_error_index")
})

test_that("sort() and unique() return the set", {
  withr::local_seed(32)
  s <- oracle(gen_values()$mixed)
  x <- roar(s)
  expect_true(sort(x) == x)
  expect_true(unique(x) == x)
})

test_that("vector operations a set does not define are errors", {
  x <- roar(1:3)
  expect_error(rev(x), class = "zuroar_error_unsupported")
  expect_error(sort(x, decreasing = TRUE), class = "zuroar_error_unsupported")
  expect_error(x[1] <- 5, class = "zuroar_error_unsupported")
  expect_error(x[[1]] <- 5, class = "zuroar_error_unsupported")
})

test_that("indexing leaves its argument unchanged", {
  x <- roar(c(1, 7, 9, 100000))
  r <- list(x[2:3], x[-1], head(x, 2), tail(x, 2), x[c(TRUE, FALSE)])
  expect_identical(as.double(x), c(1, 7, 9, 100000))
})

test_that("index errors snapshot", {
  expect_snapshot(error = TRUE, {
    roar(1:3)[c(1, -2)]
    roar(1:3)[5]
    roar(1:3)[[0]]
    rev(roar(1:3))
  })
})
