test_that("roar64() holds sort(unique()) of its input, as text", {
  withr::local_seed(60)
  for (name in names(gen_values64())) {
    v <- gen_values64()[[name]]
    for (opt in c(TRUE, FALSE)) {
      x <- roar64(v, optimize = opt)
      expect_s3_class(x, "zuroar64")
      expect_identical(as.character(x), text64(v), label = name)
      expect_identical(roar64(text64(v)) == x, TRUE, label = name)
      expect_equal(length(x), length(unique(v)), label = name)
      expect_identical(
        roar64_length(x),
        as.character(length(unique(v))),
        label = name
      )
    }
  }
})

test_that("values near 2^64 are exact through text", {
  top <- "18446744073709551615"
  x <- roar64(c(top, "9007199254740993", "0", "4294967296"))
  expect_identical(
    as.character(x),
    c("0", "4294967296", "9007199254740993", top)
  )
  expect_identical(max(x), top)
  expect_identical(min(x), "0")
  expect_identical(range(x), c("0", top))
  expect_identical(x[[4]], top)
  expect_identical(roar_select(x, 3), "9007199254740993")
  expect_identical(
    roar_contains(x, c(top, "18446744073709551614")),
    c(TRUE, FALSE)
  )
  expect_identical(roar_next(x, "9007199254740992"), "9007199254740993")
  expect_identical(roar_prev(x, "18446744073709551614"), "9007199254740993")
  expect_identical(roar_next(x, top), top)
  expect_identical(roar_rank(x, top), 4)
  expect_identical(
    format(x),
    "<zuroar64> 4 values in [0, 18446744073709551615]: 0 4294967296 9007199254740993 18446744073709551615"
  )
})

test_that("non-canonical text and doubles at or above 2^53 are errors", {
  bad <- list(
    "01",
    "-1",
    "+1",
    "1.0",
    "1e3",
    " 1",
    "",
    "18446744073709551616",
    "abc",
    NA_character_
  )
  for (v in bad) {
    expect_error(roar64(v), class = "zuroar_error_value", label = deparse(v))
  }
  for (v in list(2^53, 2^60, -1, 0.5, NA_real_, Inf)) {
    expect_error(roar64(v), class = "zuroar_error_value", label = deparse(v))
  }
  expect_error(roar64(TRUE), class = "zuroar_error_value")
  expect_identical(as.character(roar64(2^53 - 1)), "9007199254740991")
  expect_identical(as.character(roar64(c(3L, 1L))), c("1", "3"))
})

test_that("roar64() promotes a 32-bit bitmap", {
  x <- roar(c(1, 65536, 4294967295))
  z <- roar64(x)
  expect_s3_class(z, "zuroar64")
  expect_identical(as.character(z), c("1", "65536", "4294967295"))
  expect_identical(as.double(x), c(1, 65536, 4294967295)) # x unchanged
})

test_that("set operations match base R on sets above 2^32", {
  withr::local_seed(61)
  sets <- gen_values64()
  for (i in names(sets)) {
    for (j in names(sets)) {
      a <- sets[[i]]
      b <- sets[[j]]
      x <- roar64(a)
      y <- roar64(b)
      label <- paste(i, j)
      expect_identical(as.character(x | y), text64(union(a, b)), label = label)
      expect_identical(
        as.character(x & y),
        text64(intersect(a, b)),
        label = label
      )
      expect_identical(
        as.character(roar_andnot(x, y)),
        text64(setdiff(a, b)),
        label = label
      )
      expect_identical(
        as.character(roar_xor(x, y)),
        text64(c(setdiff(a, b), setdiff(b, a))),
        label = label
      )
      expect_equal(
        roar_cardinality(x, y),
        length(intersect(a, b)),
        label = label
      )
      expect_equal(
        roar_cardinality(x, y, "or"),
        length(union(a, b)),
        label = label
      )
      subset <- all(unique(a) %in% b)
      equal <- setequal(a, b)
      expect_identical(x <= y, subset, label = label)
      expect_identical(x == y, equal, label = label)
      expect_identical(x < y, subset && !equal, label = label)
      expect_identical(
        roar_intersects(x, y),
        length(intersect(a, b)) > 0,
        label = label
      )
    }
  }
  expect_identical(
    as.character(do.call(roar_union, lapply(sets, roar64))),
    text64(unlist(sets))
  )
  expect_identical(
    as.character(c(roar64(1), roar64("18446744073709551615"), 7)),
    c("1", "7", "18446744073709551615")
  )
})

test_that("add, remove, ranges, flip and shifting work on 64 bits", {
  top <- "18446744073709551615"
  x <- roar64(c("5", top))
  expect_identical(
    as.character(roar_add(x, "9007199254740993")),
    c("5", "9007199254740993", top)
  )
  expect_identical(as.character(roar_remove(x, top)), "5")
  y <- roar_add(x, from = "18446744073709551610", to = top)
  expect_identical(roar64_length(y), "7")
  expect_identical(
    as.character(roar_remove(
      y,
      from = "18446744073709551610",
      to = "18446744073709551614"
    )),
    c("5", top)
  )
  expect_identical(roar_count(y, "18446744073709551612", top), 4)
  expect_true(roar_contains_range(y, "18446744073709551610", top))
  expect_false(roar_contains_range(y, "6", top))
  expect_identical(as.character(roar_flip(roar64(c(1, 3)), 0, 3)), c("0", "2"))
  r <- roar64_range("4294967290", "4294967300")
  expect_identical(length(r), 11L)
  expect_identical(as.character(r + 10), sprintf("%.0f", 4294967300:4294967310))
  expect_identical(as.character((r + 10) - 10), as.character(r))
  expect_error(x + 1, class = "zuroar_error_value")
  expect_error(roar64(0) - 1, class = "zuroar_error_value")
  expect_identical(as.character(roar_shift(x, 1, drop = TRUE)), "6")
  expect_identical(
    as.character(roar_shift(roar64(c(0, 9)), -5, drop = TRUE)),
    "4"
  )
  expect_identical(as.character(x), c("5", top)) # unchanged
})

test_that("a range too large for memory is refused, not attempted", {
  top <- "18446744073709551615"
  expect_error(roar64_range("0", top), class = "zuroar_error_memory")
  expect_error(
    roar_add(roar64(), from = "0", to = top),
    class = "zuroar_error_memory"
  )
  expect_error(roar_flip(roar64(), "0", top), class = "zuroar_error_memory")
  expect_identical(roar64_length(roar64_range("0", 2^40 - 1)), "1099511627776")
  # Removing and counting allocate nothing, so they take any range.
  expect_identical(
    length(roar_remove(roar64(c(1, 2)), from = "0", to = top)),
    0L
  )
  expect_identical(roar_count(roar64(c(1, top)), "0", top), 2)
})

test_that("positions, head() and tail() work on 64 bits", {
  withr::local_seed(62)
  s <- sort(unique(gen_values64()$mixed))
  x <- roar64(s)
  t <- sprintf("%.0f", s)
  expect_identical(as.character(x[2:10]), t[2:10])
  expect_identical(as.character(x[-1]), t[-1])
  expect_identical(as.character(x[c(TRUE, FALSE)]), t[c(TRUE, FALSE)])
  expect_identical(x[[3]], t[3])
  expect_identical(as.character(head(x, 3)), head(t, 3))
  expect_identical(as.character(tail(x, -2)), tail(t, -2))
  expect_identical(
    roar_select(x, roar_rank(x, t[c(1, 50, 500)])),
    t[c(1, 50, 500)]
  )
  expect_identical(roar_values(x, from = t[10], n = 3), t[10:12])
  expect_identical(
    roar_values(x, from = t[10], n = 3, type = "double"),
    s[10:12]
  )
  expect_error(x[[length(s) + 1]], class = "zuroar_error_index")
  expect_error(x[c(1, -1)], class = "zuroar_error_index")
  expect_error(rev(x), class = "zuroar_error_unsupported")
  expect_error(x[1] <- "1", class = "zuroar_error_unsupported")
  expect_true(sort(x) == x)
})

test_that("conversions are exact or errors (D2)", {
  x <- roar64(c("1", "9007199254740993"))
  expect_error(as.double(x), class = "zuroar_error_value")
  expect_error(as.integer(x), class = "zuroar_error_value")
  expect_identical(as.double(roar64(c(1, 2^53 - 1))), c(1, 2^53 - 1))
  expect_identical(as.integer(roar64(c(1, 7))), c(1L, 7L))
  expect_error(
    roar_values(x, n = 2, type = "double"),
    class = "zuroar_error_value"
  )
  expect_identical(roar_values(x, n = 1, type = "double"), 1)
  expect_identical(as.character(roar(c(1, 4294967295))), c("1", "4294967295"))
})

test_that("mixing zuroar and zuroar64 is an error", {
  x <- roar(1)
  z <- roar64(1)
  expect_error(x | z, class = "zuroar_error_unsupported")
  expect_error(z == x, class = "zuroar_error_unsupported")
  expect_error(roar_union(x, z), class = "zuroar_error_unsupported")
  expect_error(roar_xor(z, x), class = "zuroar_error_unsupported")
  expect_error(roar_cardinality(x, z), class = "zuroar_error_unsupported")
  expect_error(c(z, x), class = "zuroar_error_unsupported")
  expect_true(roar64(x) == z)
})

test_that("Summary members other than min, max and range are unsupported", {
  z <- roar64(1:3)
  expect_error(sum(z), class = "zuroar_error_unsupported")
  expect_error(min(roar64()), class = "zuroar_error_value")
})

test_that("64-bit serialisation round-trips exactly", {
  withr::local_seed(63)
  for (name in names(gen_values64())) {
    x <- roar64(gen_values64()[[name]])
    for (opt in c(FALSE, TRUE)) {
      expect_true(
        roar64_unserialize(roar_serialize(x, optimize = opt)) == x,
        label = name
      )
    }
  }
  top <- roar64(c("0", "18446744073709551615"))
  expect_true(roar64_unserialize(roar_serialize(top)) == top)
  expect_identical(roar_size(top), as.double(length(roar_serialize(top))))
})

test_that("pyroaring and Java 64-bit fixtures read to the expected sets", {
  sets <- fixture_sets64()
  expect_gte(length(sets), 6)
  for (name in names(sets)) {
    want <- sets[[name]]$bitmap
    for (writer in c("pyroaring64", "java64")) {
      got <- roar64_unserialize(fixture_bytes(name, writer))
      expect_true(got == want, label = paste(name, writer))
    }
    if (sets[[name]]$optimize) {
      expect_identical(
        roar_serialize(want, optimize = TRUE),
        fixture_bytes(name, "pyroaring64"),
        label = name
      )
    }
  }
})

test_that("the readers are chosen by the caller, never guessed (D15)", {
  b32 <- roar_serialize(roar(c(1, 5)))
  b64 <- roar_serialize(roar64(c(1, 5)))
  expect_false(identical(b32, b64))
  expect_error(roar_unserialize(b64), class = "zuroar_error_format")
})

test_that("64-bit truncation and corruption are zuroar_error_format", {
  withr::local_seed(29)
  for (name in c("small", "high", "buckets", "runs")) {
    b <- fixture_bytes(name, "java64")
    # Every cut of the small fixtures (design §8). For the 2,949-byte
    # buckets fixture, every cut through its first and last 150 bytes,
    # where the bucket and container headers are, and 100 in between:
    # every cut there took 2.6 hours under gctorture at step 20. The fuzz
    # target covers arbitrary cuts.
    cuts <- seq_len(length(b) - 1) - 1
    if (length(b) > 400) {
      inner <- cuts[cuts >= 150 & cuts < length(b) - 150]
      cuts <- sort(c(
        cuts[cuts < 150 | cuts >= length(b) - 150],
        sample(inner, 100)
      ))
    }
    for (n in cuts) {
      expect_error(
        roar64_unserialize(b[seq_len(n)]),
        class = "zuroar_error_format",
        label = paste(name, n)
      )
    }
  }
  small <- fixture_bytes("small", "java64")
  expect_error(
    roar64_unserialize(c(small, as.raw(0))),
    class = "zuroar_error_format"
  )
  expect_true(
    roar64_unserialize(c(small, as.raw(0)), trailing = "ignore") ==
      roar64(c(1, 5, 9, 100000))
  )
  huge_count <- small
  huge_count[1:8] <- as.raw(255)
  expect_error(roar64_unserialize(huge_count), class = "zuroar_error_format")
  # Two buckets with the same high key, out of order.
  high <- fixture_bytes("high", "java64")
  expect_error(roar64_unserialize(raw()), class = "zuroar_error_format")
  expect_error(roar64_unserialize("x"), class = "zuroar_error_format")
})

test_that("64-bit byte flips never crash", {
  withr::local_seed(64)
  for (name in c("small", "high", "buckets")) {
    b <- fixture_bytes(name, "java64")
    positions <- if (length(b) <= 150) {
      seq_along(b)
    } else {
      sort(sample(length(b), 150))
    }
    for (i in positions) {
      for (v in c(0x00, 0xff)) {
        c2 <- b
        c2[i] <- as.raw(v)
        res <- tryCatch(
          roar64_unserialize(c2),
          zuroar_error_format = function(e) NULL
        )
        if (!is.null(res)) {
          expect_true(roar64_unserialize(roar_serialize(res)) == res)
        }
      }
    }
  }
  succeed()
})

test_that("a 64-bit bitmap after readRDS() is a null pointer", {
  path <- withr::local_tempfile(fileext = ".rds")
  saveRDS(roar64(1:3), path)
  z <- readRDS(path)
  expect_error(length(z), class = "zuroar_error_pointer")
  expect_error(as.character(z), class = "zuroar_error_pointer")
  expect_error(roar_contains(z, 1), class = "zuroar_error_pointer")
  expect_match(format(z), "null pointer", fixed = TRUE)
  skip_if_not_installed("pillar")
  expect_identical(pillar::type_sum(z), "roar64")
})

test_that("roar64_length() needs a zuroar64", {
  expect_error(roar64_length(roar(1)), class = "zuroar_error")
})

test_that("positions between values 2^64 apart never build that range", {
  top <- "18446744073709551615"
  z <- roar64(c("0", "5", "4294967296", top))
  expect_identical(as.character(tail(z, 2)), c("4294967296", top))
  expect_identical(as.character(z[1:4]), as.character(z))
  expect_identical(as.character(z[-(2:3)]), c("0", top))
  expect_identical(as.character(head(z, -1)), c("0", "5", "4294967296"))
})
