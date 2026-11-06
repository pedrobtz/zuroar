# The sorted-vector oracle (design §8): a bitmap of v behaves as s.
index_cases <- function(len) {
  if (len == 0) {
    return(list(numeric(), 0, logical()))
  }
  list(
    1,
    len,
    c(1, len),
    seq_len(min(len, 200)),
    seq_len(len),
    -1,
    -len,
    -(1:min(len, 3)),
    c(3, 1, 3)[c(3, 1, 3) <= len],
    unique(pmax(1, round(seq(1, len, length.out = 50)))),
    seq(min(2, len), min(len, 150)),
    0,
    c(0, 1),
    TRUE,
    FALSE,
    rep(c(TRUE, FALSE, FALSE), length.out = len),
    if (len >= 2) c(TRUE, FALSE) else TRUE
  )
}
