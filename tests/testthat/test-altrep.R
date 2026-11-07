# The ALTREP representation (design §4, D17): a bitmap is a double vector
# to R, read on demand and never expanded behind the user's back.

test_that("a bitmap survives saveRDS() and readRDS()", {
  withr::local_seed(1)
  path <- withr::local_tempfile(fileext = ".rds")
  for (v in gen_values()) {
    x <- roar(v)
    saveRDS(x, path)
    y <- readRDS(path)
    expect_s3_class(y, "zuroar")
    expect_true(y == x)
    expect_identical(as.double(y), oracle(v))
    expect_identical(length(y), length(oracle(v)))
  }
})

test_that("a bitmap survives serialize() and unserialize(), attributes too", {
  x <- roar(c(1, 5, 9, 2^32 - 1))
  attr(x, "note") <- "kept"
  for (xdr in c(TRUE, FALSE)) {
    y <- unserialize(serialize(x, NULL, xdr = xdr))
    expect_s3_class(y, "zuroar")
    expect_true(y == x)
    expect_identical(attr(y, "note"), "kept")
  }
  expect_true(unserialize(serialize(roar(), NULL)) == roar())
})

test_that("saved bytes are written on demand, not kept at rest", {
  x <- roar_range(1, 1e6)
  state <- .Call(zro_test_state, x)
  expect_type(state, "raw")
  expect_lt(length(state), 1000)
  expect_true(.Call(zro_test_unserialize, state) == x)
})

test_that("corrupt saved bytes are a zuroar_error_format, never a crash", {
  x <- roar(c(1, 5, 9, 70000, 70001, 70002))
  state <- .Call(zro_test_state, x)
  # Truncated at every byte, including to nothing.
  for (n in 0:(length(state) - 1)) {
    expect_error(
      .Call(zro_test_unserialize, state[seq_len(n)]),
      class = "zuroar_error_format"
    )
  }
  # Trailing bytes, a wrong type, and a corrupt cookie.
  expect_error(
    .Call(zro_test_unserialize, c(state, as.raw(0))),
    class = "zuroar_error_format"
  )
  expect_error(.Call(zro_test_unserialize, 1), class = "zuroar_error_format")
  bad <- state
  bad[[2]] <- xor(bad[[2]], as.raw(0xff))
  expect_error(.Call(zro_test_unserialize, bad), class = "zuroar_error_format")

  # The same through R's own stream: find the state inside it and flip it.
  stream <- serialize(x, NULL)
  at <- grepRaw(state, stream, fixed = TRUE)
  expect_length(at, 1)
  stream[[at + 1]] <- xor(stream[[at + 1]], as.raw(0xff))
  expect_error(unserialize(stream), class = "zuroar_error_format")
})

test_that("%in% and match() agree with the oracle", {
  withr::local_seed(2)
  for (v in gen_values()) {
    x <- roar(v)
    s <- oracle(v)
    probe <- c(head(s, 50), sample(2^32 - 1, 50), 0, 2^32 - 1, 0.5)
    expect_identical(probe %in% x, probe %in% s)
    expect_identical(match(probe, x), match(probe, s))
    expect_identical(match(x, probe), match(s, probe))
  }
})

test_that("[ returns a bitmap for positive, negative and logical positions", {
  withr::local_seed(3)
  for (v in gen_values()) {
    x <- roar(v)
    s <- oracle(v)
    n <- length(s)
    if (n == 0) {
      expect_true(x[integer()] == roar())
      next
    }
    expect_identical(as.double(x[seq_len(min(n, 7))]), head(s, 7))
    expect_identical(as.double(x[n]), s[n])
    i <- sample(n, min(n, 20), replace = TRUE)
    expect_identical(as.double(x[i]), sort(unique(s[i])))
    expect_identical(as.double(x[-1]), s[-1])
    mask <- seq_len(n) %% 2 == 0
    expect_identical(as.double(x[mask]), s[mask])
    expect_s3_class(x[i], "zuroar")
    expect_true(x[] == x)
    expect_true(x[0] == roar())
  }
})

test_that("[ rejects NA and positions past the end with zuroar_error_index", {
  x <- roar(c(2, 4, 6))
  expect_error(x[4], class = "zuroar_error_index")
  expect_error(x[NA], class = "zuroar_error_index")
  expect_error(x[c(1, NA)], class = "zuroar_error_index")
  expect_error(x["a"], class = "zuroar_error_index")
})

test_that("[[, head() and tail() read positions without expanding", {
  withr::local_seed(4)
  for (v in gen_values()) {
    x <- roar(v)
    s <- oracle(v)
    if (length(s) == 0) {
      next
    }
    expect_identical(x[[1]], s[[1]])
    expect_identical(x[[length(s)]], s[[length(s)]])
    expect_identical(as.double(head(x, 3)), head(s, 3))
    expect_identical(as.double(tail(x, 3)), tail(s, 3))
    expect_identical(as.double(head(x, -2)), head(s, -2))
    expect_s3_class(head(x), "zuroar")
  }
})

test_that("sum(), mean() and loops read the values in one pass", {
  withr::local_seed(5)
  for (v in gen_values()) {
    x <- roar(v)
    s <- oracle(v)
    expect_identical(sum(x), sum(s))
    expect_identical(as.double(unlist(lapply(x, function(e) e))), s)
    expect_identical(vapply(x, function(e) e + 1, 1), s + 1)
    acc <- 0
    for (e in x) {
      acc <- acc + e
    }
    expect_identical(acc, sum(s))
    if (length(s) > 0) expect_identical(mean(x), mean(s))
  }
  expect_error(sum(roar(1), roar(2)), class = "zuroar_error_unsupported")
  expect_identical(sum(roar()), 0)
  expect_identical(sum(roar(c(0, 2^32 - 1)), na.rm = TRUE), 2^32 - 1)
})

test_that("a bitmap is a data-frame column", {
  x <- roar(c(3, 1, 7))
  d <- data.frame(id = x, label = c("a", "b", "c"))
  expect_identical(nrow(d), 3L)
  expect_s3_class(d$id, "zuroar")
  expect_true(d$id == x)
  e <- d[2:3, ]
  expect_s3_class(e$id, "zuroar")
  expect_identical(as.double(e$id), c(3, 7))
  expect_identical(d$id[[2]], 3)
  expect_identical(as.double(d[d$label != "a", "id"]), c(3, 7))
})

test_that("attributes change a copy and leave the original alone", {
  x <- roar(c(1, 5))
  y <- x
  attr(y, "note") <- "a"
  expect_null(attr(x, "note"))
  expect_identical(attr(y, "note"), "a")
  expect_s3_class(y, "zuroar")
  expect_true(x == y)
  expect_identical(class(unclass(y)), "numeric")
  expect_identical(sum(unclass(y)), 6)
})

test_that("nothing expands roar_range(0, 2^32 - 1)", {
  x <- roar_range(0, 2^32 - 1)
  expect_identical(length(x), 2^32)
  expect_output(print(x), "4,294,967,296 values", fixed = TRUE)
  expect_identical(x[[1]], 0)
  expect_identical(x[[2^32]], 2^32 - 1)
  expect_identical(as.double(head(x, 3)), c(0, 1, 2))
  expect_identical(as.double(tail(x, 2)), c(2^32 - 2, 2^32 - 1))
  expect_identical(as.double(x[c(2^31, 2^31 + 1)]), c(2^31 - 1, 2^31))
  expect_error(x > 5, class = "zuroar_error_unsupported")
  expect_error(x + 1, class = "zuroar_error_value")
  expect_error(x[1] <- 5, class = "zuroar_error_unsupported")
  expect_error(unclass(x) + 1, class = "zuroar_error_unsupported")
  expect_error(.Call(zro_test_dataptr, x), class = "zuroar_error_unsupported")
  expect_identical(sum(x), 2^63 - 2^31)
  expect_true(x == x)
})

test_that("the data pointer is refused from C and from base R", {
  x <- roar(1:3)
  y <- roar(1:3)
  expect_error(.Call(zro_test_dataptr, x), class = "zuroar_error_unsupported")
  # identical() reads through the data pointer on every R version; == is
  # the set equality.
  expect_error(identical(x, y), class = "zuroar_error_unsupported")
  expect_true(x == y)
  expect_error(x[2] <- 9, class = "zuroar_error_unsupported")
  expect_error(cumsum(x), class = "zuroar_error_unsupported")
  expect_identical(as.double(x), c(1, 2, 3))
})

test_that("the data pointer is refused with a message naming as.double()", {
  expect_snapshot(error = TRUE, {
    .Call(zro_test_dataptr, roar(1))
    roar(c(2, 4))[3]
  })
})

test_that("inspect() describes the bitmap without expanding it", {
  x <- roar_range(0, 2^32 - 1)
  expect_output(
    .Internal(inspect(x)),
    "zuroar bitmap: 4294967296 values",
    fixed = TRUE
  )
})

test_that("the sorted-vector hints are honoured", {
  x <- roar(c(5, 1, 3))
  expect_false(anyNA(x))
  expect_false(is.unsorted(x))
  expect_true(sort(x) == x)
})
