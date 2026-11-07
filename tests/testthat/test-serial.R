test_that("round trips are exact", {
  withr::local_seed(40)
  for (name in names(gen_values())) {
    v <- oracle(gen_values()[[name]])
    for (opt in c(FALSE, TRUE)) {
      x <- roar(v, optimize = opt)
      for (sopt in c(FALSE, TRUE)) {
        y <- roar_unserialize(roar_serialize(x, optimize = sopt))
        expect_true(y == x, label = paste(name, opt, sopt))
        expect_identical(as.double(y), v, label = paste(name, opt, sopt))
      }
    }
  }
  full <- roar_range(0, 4294967295)
  expect_true(roar_unserialize(roar_serialize(full)) == full)
})

test_that("roar_size() is the number of bytes roar_serialize() writes", {
  x <- roar(c(1, 5, 9, 100000))
  expect_identical(roar_size(x), as.double(length(roar_serialize(x))))
})

test_that("pyroaring and Java fixtures read to the expected sets", {
  sets <- fixture_sets()
  expect_gte(length(sets), 8)
  for (name in names(sets)) {
    for (writer in c("pyroaring", "java")) {
      x <- roar_unserialize(fixture_bytes(name, writer))
      expect_identical(
        as.double(x),
        sets[[name]]$values,
        label = paste(name, writer)
      )
    }
  }
})

test_that("roar_serialize() writes the bytes pyroaring and Java write", {
  sets <- fixture_sets()
  for (name in names(sets)) {
    s <- sets[[name]]
    # Build as the writers did: stepped values one by one, ranges as runs.
    x <- roar(s$values, optimize = FALSE)
    if (s$optimize) {
      x <- roar_optimize(x)
    }
    got <- roar_serialize(x, optimize = s$optimize)
    want <- fixture_bytes(name, "pyroaring")
    # Containers built from scratch may differ in kind from the writers'
    # (add_range makes runs), so compare after the same optimisation.
    expect_true(roar_unserialize(got) == roar_unserialize(want), label = name)
    if (s$optimize) {
      expect_identical(got, want, label = name)
    }
  }
})

test_that("truncation at every byte is a zuroar_error_format", {
  for (name in c("small", "boundaries", "mixed", "runs")) {
    b <- fixture_bytes(name, "java")
    for (n in seq_len(length(b) - 1) - 1) {
      expect_error(
        roar_unserialize(b[seq_len(n)]),
        class = "zuroar_error_format",
        label = paste(name, n)
      )
    }
  }
})

test_that("trailing bytes are an error unless trailing = \"ignore\"", {
  b <- fixture_bytes("small", "java")
  extra <- c(b, as.raw(c(1, 2, 3)))
  expect_error(roar_unserialize(extra), class = "zuroar_error_format")
  expect_identical(
    as.double(roar_unserialize(extra, trailing = "ignore")),
    c(1, 5, 9, 100000)
  )
  expect_error(roar_unserialize(b, trailing = "drop"), class = "zuroar_error")
})

test_that("corrupted cookies, counts, offsets and runs are zuroar_error_format", {
  small <- fixture_bytes("small", "java") # no-run cookie 12346, 2 containers
  runs <- fixture_bytes("runs", "java") # run cookie 12347
  bad <- list(
    cookie = c(u32(0), small[-(1:4)]),
    cookie_other = c(u32(12345), small[-(1:4)]),
    count_huge = c(small[1:4], u32(4294967295), small[-(1:8)]),
    count_more = c(small[1:4], u32(3), small[-(1:8)]),
    run_cookie_count = {
      b <- runs
      b[3:4] <- u16(60000) # containers - 1 in the high 16 bits
      b
    },
    empty_raw = raw(),
    one_byte = as.raw(1)
  )
  for (name in names(bad)) {
    expect_error(
      roar_unserialize(bad[[name]]),
      class = "zuroar_error_format",
      label = name
    )
  }
})

test_that("a corrupted offset header is ignored, not trusted", {
  # CRoaring reads containers in sequence and never follows the offsets,
  # so an offset pointing past the end cannot make it read out of bounds.
  small <- fixture_bytes("small", "java") # no-run cookie, 2 containers
  b <- small
  b[17:20] <- u32(1e6) # the first container's offset
  expect_identical(as.double(roar_unserialize(b)), c(1, 5, 9, 100000))
})

test_that("an overlapping or overflowing run container fails validation", {
  # One run container (key 0) holding runs (start, length - 1):
  # run cookie 12347 with 1 container, run bitset 0x01, header key 0 and
  # cardinality - 1, then n_runs and the runs.
  header <- c(u16(12347), u16(0), as.raw(1), u16(0), u16(9))
  ok <- c(header, u16(1), u16(10), u16(9))
  expect_identical(as.double(roar_unserialize(ok)), as.double(10:19))
  overlap <- c(header, u16(2), u16(10), u16(9), u16(15), u16(3))
  overflow <- c(header, u16(1), u16(65530), u16(100))
  unsorted <- c(header, u16(2), u16(30), u16(1), u16(10), u16(1))
  for (b in list(overlap, overflow, unsorted)) {
    expect_error(roar_unserialize(b), class = "zuroar_error_format")
  }
})

test_that("single-byte corruption never crashes", {
  withr::local_seed(41)
  for (name in c("small", "mixed", "dense", "runs")) {
    b <- fixture_bytes(name, "java")
    positions <- if (length(b) <= 200) {
      seq_along(b)
    } else {
      sort(sample(length(b), 200))
    }
    for (i in positions) {
      for (v in c(0x00, 0xff, as.integer(b[i]) %/% 2 + 1)) {
        c2 <- b
        c2[i] <- as.raw(v %% 256)
        res <- tryCatch(
          roar_unserialize(c2),
          zuroar_error_format = function(e) NULL
        )
        if (!is.null(res)) {
          # Whatever reads must be a usable, valid bitmap.
          expect_gte(length(res), 0)
          expect_true(roar_unserialize(roar_serialize(res)) == res)
        }
      }
    }
  }
  succeed()
})

test_that("roar_unserialize() wants a raw vector", {
  expect_error(roar_unserialize("abc"), class = "zuroar_error_format")
  expect_error(roar_unserialize(1:3), class = "zuroar_error_format")
})

test_that("format errors snapshot", {
  expect_snapshot(error = TRUE, {
    roar_unserialize(as.raw(c(1, 2, 3)))
    roar_unserialize(c(roar_serialize(roar(1)), as.raw(0)))
  })
})
