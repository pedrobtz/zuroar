# Sets that put values in each CRoaring container kind: sparse chunks
# become array containers, dense chunks bitset containers, and long
# stretches run containers after run optimisation. Chunk boundaries at
# multiples of 2^16 are included on purpose. Integers only, so values stay
# below 2^31.
gen_sets <- function() {
  sparse <- sort(unique(c(0L, 65535L, 65536L, sample.int(2e6, 300))))
  dense <- 131072L + sample.int(65536L, 20000L) - 1L
  runs <- c(200000L:260000L, 400000L:400100L, 65530L:65545L)
  list(
    empty = integer(),
    sparse = sparse,
    dense = sort(unique(dense)),
    runs = runs,
    mixed = sort(unique(c(sparse, dense, runs)))
  )
}

# Doubles across the whole 32-bit domain, for the bindings. Each set
# exercises one container kind or a boundary: 2^16 (the chunk size), 2^31
# (past .Machine$integer.max) and 2^32 - 1 (the last value).
gen_values <- function() {
  top <- 4294967295
  list(
    empty = numeric(),
    one = 7,
    sparse = c(0, 65535, 65536, sample(2^32 - 1, 300)),
    dense = 131072 + sample(65536, 20000) - 1,
    runs = c(200000:260000, 65530:65545, (top - 100):top),
    boundaries = c(0, 2^16 - 1, 2^16, 2^31 - 1, 2^31, 2^32 - 2, top),
    duplicates = c(5, 5, 3, 3, 3, 2^31, 2^31),
    mixed = c(
      sample(2^32 - 1, 500),
      131072 + sample(65536, 9000),
      300000:340000
    )
  )
}

# The oracle: what a bitmap of `v` must hold.
oracle <- function(v) sort(unique(as.double(v)))

# The fixture sets of tests/testthat/fixtures/sets.txt, which
# tools/fixtures/make-fixtures wrote with pyroaring and Java.
fixture_sets <- function() {
  path <- test_path("fixtures", "sets.txt")
  lines <- readLines(path)
  lines <- lines[nzchar(lines) & !startsWith(lines, "#")]
  out <- list()
  for (line in lines) {
    f <- strsplit(line, "\t", fixed = TRUE)[[1]]
    pieces <- if (length(f) < 3 || !nzchar(f[3])) {
      character()
    } else {
      strsplit(f[3], ",", fixed = TRUE)[[1]]
    }
    values <- unlist(lapply(pieces, function(p) {
      step <- 1
      if (grepl("/", p, fixed = TRUE)) {
        step <- as.numeric(sub(".*/", "", p))
        p <- sub("/.*", "", p)
      }
      ab <- as.numeric(strsplit(p, "-", fixed = TRUE)[[1]])
      if (length(ab) == 1) ab else seq(ab[1], ab[2], by = step)
    }))
    out[[f[1]]] <- list(
      values = sort(unique(c(numeric(), values))),
      optimize = f[2] == "1"
    )
  }
  out
}

fixture_bytes <- function(name, writer) {
  path <- test_path("fixtures", paste0(name, ".", writer, ".bin"))
  readBin(path, "raw", file.size(path))
}
