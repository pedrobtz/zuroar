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
