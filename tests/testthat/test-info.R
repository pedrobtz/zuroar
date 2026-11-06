test_that("zuroar_info() reports the bundled CRoaring version", {
  info <- zuroar_info()
  expect_named(info, c("croaring", "compiled", "runtime"))
  expect_identical(info$croaring, "5.4.0")
})

test_that("zuroar_info() lists only known SIMD paths", {
  info <- zuroar_info()
  expect_type(info$compiled, "character")
  expect_type(info$runtime, "character")
  expect_true(all(info$compiled %in% c("avx2", "avx512", "neon")))
  expect_true(all(info$runtime %in% c("avx2", "avx512", "sve", "sve2")))
})

test_that("zuroar_info() compiles the paths of the build architecture", {
  info <- zuroar_info()
  arch <- R.version$arch
  scalar <- nzchar(Sys.getenv("ZUROAR_SCALAR_BUILD"))
  skip_if(scalar, "scalar build")
  if (arch %in% c("x86_64", "amd64")) {
    expect_true("avx2" %in% info$compiled)
  }
  if (arch %in% c("aarch64", "arm64")) {
    expect_true("neon" %in% info$compiled)
  }
})

test_that("a scalar build compiles no SIMD path", {
  skip_if_not(nzchar(Sys.getenv("ZUROAR_SCALAR_BUILD")), "not a scalar build")
  expect_length(zuroar_info()$compiled, 0)
})
