test_that("the package loads with its native library", {
  expect_true(isNamespaceLoaded("zuroar"))
  expect_true("zuroar" %in% names(getLoadedDLLs()))
})
