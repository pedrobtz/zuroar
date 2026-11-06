test_that("|, &, roar_xor() and roar_andnot() match base R", {
  withr::local_seed(10)
  sets <- gen_values()
  for (i in names(sets)) {
    for (j in names(sets)) {
      a <- sets[[i]]
      b <- sets[[j]]
      x <- roar(a)
      y <- roar(b)
      label <- paste(i, j)
      expect_identical(as.double(x | y), oracle(union(a, b)), label = label)
      expect_identical(as.double(x & y), oracle(intersect(a, b)), label = label)
      expect_identical(
        as.double(roar_andnot(x, y)),
        oracle(setdiff(a, b)),
        label = label
      )
      expect_identical(
        as.double(roar_xor(x, y)),
        oracle(c(setdiff(a, b), setdiff(b, a))),
        label = label
      )
    }
  }
})

test_that("cardinality-only results equal length() of the built result", {
  withr::local_seed(11)
  sets <- gen_values()
  for (i in names(sets)) {
    for (j in names(sets)) {
      x <- roar(sets[[i]])
      y <- roar(sets[[j]])
      label <- paste(i, j)
      expect_equal(roar_cardinality(x, y), length(x & y), label = label)
      expect_equal(roar_cardinality(x, y, "or"), length(x | y), label = label)
      expect_equal(
        roar_cardinality(x, y, "xor"),
        length(roar_xor(x, y)),
        label = label
      )
      expect_equal(
        roar_cardinality(x, y, "andnot"),
        length(roar_andnot(x, y)),
        label = label
      )
      expect_type(roar_cardinality(x, y), "double")
    }
  }
})

test_that("comparisons follow subset and equality", {
  withr::local_seed(12)
  sets <- gen_values()
  for (i in names(sets)) {
    for (j in names(sets)) {
      a <- oracle(sets[[i]])
      b <- oracle(sets[[j]])
      x <- roar(a)
      y <- roar(b)
      label <- paste(i, j)
      subset <- all(a %in% b)
      equal <- identical(a, b)
      expect_identical(x == y, equal, label = label)
      expect_identical(x != y, !equal, label = label)
      expect_identical(x <= y, subset, label = label)
      expect_identical(y >= x, subset, label = label)
      expect_identical(x < y, subset && !equal, label = label)
      expect_identical(y > x, subset && !equal, label = label)
      # Properties (design §8).
      expect_identical(x < y, (x <= y) && (x != y), label = label)
      expect_true((x & y) <= x, label = label)
      expect_true((x & y) <= y, label = label)
      expect_identical(
        roar_disjoint(x, y),
        length(x & y) == 0,
        label = label
      )
      expect_identical(
        roar_intersects(x, y),
        !roar_disjoint(x, y),
        label = label
      )
    }
  }
})

test_that("roar_jaccard() is |x & y| / |x | y|", {
  x <- roar(c(1, 5, 9))
  y <- roar(c(5, 9, 12))
  expect_equal(roar_jaccard(x, y), 2 / 4)
  expect_equal(roar_jaccard(x, x), 1)
  expect_equal(roar_jaccard(x, roar()), 0)
  expect_identical(roar_jaccard(roar(), roar()), NaN)
})

test_that("roar_union() and roar_intersect() take any number of bitmaps", {
  withr::local_seed(13)
  sets <- gen_values()
  xs <- lapply(sets, roar)
  expect_identical(as.double(do.call(roar_union, xs)), oracle(unlist(sets)))
  want <- Reduce(
    intersect,
    lapply(sets[c("sparse", "mixed", "boundaries")], oracle)
  )
  expect_identical(
    as.double(roar_intersect(xs$sparse, xs$mixed, xs$boundaries)),
    oracle(want)
  )
  expect_identical(length(roar_union()), 0L)
  expect_identical(as.double(roar_union(xs$one)), 7)
  expect_identical(as.double(roar_intersect(xs$one)), 7)
  expect_error(roar_intersect(), class = "zuroar_error")
  expect_error(roar_union(xs$one, 5), class = "zuroar_error")
})

test_that("c() is the union, as sort(unique(c(...)))", {
  withr::local_seed(14)
  sets <- gen_values()
  x <- roar(sets$sparse)
  got <- c(x, roar(sets$dense), sets$runs, 42)
  expect_identical(
    as.double(got),
    oracle(c(sets$sparse, sets$dense, sets$runs, 42))
  )
  expect_identical(as.double(c(roar())), numeric())
  expect_error(c(x, -1), class = "zuroar_error_value")
})

test_that("roar_flip() flips an inclusive range, and twice is the identity", {
  withr::local_seed(15)
  sets <- gen_values()
  for (name in names(sets)) {
    v <- oracle(sets[[name]])
    x <- roar(v)
    for (r in list(
      c(0, 10),
      c(65530, 65545),
      c(4294967290, 4294967295),
      c(7, 7)
    )) {
      inside <- seq(r[1], r[2])
      want <- oracle(c(setdiff(v, inside), setdiff(inside, v)))
      label <- paste(name, r[1], r[2])
      expect_identical(as.double(roar_flip(x, r[1], r[2])), want, label = label)
      expect_true(
        roar_flip(roar_flip(x, r[1], r[2]), r[1], r[2]) == x,
        label = label
      )
    }
  }
  expect_error(roar_flip(roar(1), 5, 4), class = "zuroar_error_value")
})

test_that("set operations leave their arguments unchanged", {
  x <- roar(1:10)
  y <- roar(5:15)
  before <- list(as.double(x), as.double(y))
  r <- list(
    x | y,
    x & y,
    roar_xor(x, y),
    roar_andnot(x, y),
    roar_flip(x, 0, 3),
    x + 1,
    c(x, y)
  )
  expect_identical(list(as.double(x), as.double(y)), before)
})
