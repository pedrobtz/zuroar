# Test hooks. Tests call these instead of .Call() directly: R's constant
# checking (R_CHECK_CONSTANTS >= 4, the rcnst check) compares every
# argument of a .Call() made from uncompiled code with identical(), which
# a bitmap refuses (design §6.6). Byte-compiled package code takes a path
# that does not compare.
test_dataptr <- function(x) .Call(zro_test_dataptr, x)
test_state <- function(x) .Call(zro_test_state, x)
test_unserialize <- function(state) .Call(zro_test_unserialize, state)
