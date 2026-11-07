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
# session's .libPaths(). Hand them over through R_LIBS before the daemon
# starts, so that it loads the zuroar under test rather than whichever copy
# its default library holds. It must be the environment, not a later
# mirai::everywhere(): a daemon started with roar_serial_config() loads
# zuroar at start-up, to read the configuration's functions.
local_daemon_library <- function(env = parent.frame()) {
  withr::local_envvar(
    R_LIBS = paste(.libPaths(), collapse = .Platform$path.sep),
    .local_envir = env
  )
}
