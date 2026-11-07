# Little-endian helpers for crafting headers.
u16 <- function(x) as.raw(c(x %% 256, (x %/% 256) %% 256))
u32 <- function(x) {
  as.raw(c(
    x %% 256,
    (x %/% 256) %% 256,
    (x %/% 65536) %% 256,
    (x %/% 16777216) %% 256
  ))
}
