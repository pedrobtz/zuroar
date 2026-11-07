test_that("a bitmap travels to a mirai daemon and back with no serial config", {
  skip_on_cran()
  skip_if_not_installed("mirai", "2.3.0")
  # A daemon is a fresh R process; it reads the bitmap by loading the
  # installed zuroar. Under devtools::test() the package is only loaded,
  # so this runs under R CMD check and in CI.
  installed <- file.exists(file.path(
    system.file(package = "zuroar"),
    "R",
    "zuroar.rdb"
  ))
  skip_if_not(installed, "zuroar is not installed")

  mirai::daemons(1)
  withr::defer(mirai::daemons(0))
  x <- roar(c(1, 7, 100000))
  m <- mirai::mirai(zuroar::roar_add(x, 8), x = x)
  y <- mirai::call_mirai(m)$data
  expect_s3_class(y, "zuroar")
  expect_identical(as.double(y), c(1, 7, 8, 100000))
})
