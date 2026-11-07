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

# A mirai daemon is a fresh R process, which does not inherit this
# session's .libPaths(). Hand them over, so that it loads the zuroar under
# test rather than whichever copy its default library holds.
use_this_library <- function() {
  mirai::everywhere(.libPaths(lib), lib = .libPaths())
  invisible()
}
