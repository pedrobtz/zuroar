test_that("conditions snapshot", {
  expect_snapshot(error = TRUE, {
    roar(c(1, -2))
    roar(c(1, 0.5))
    roar(c(TRUE, FALSE))
    as.integer(roar(2^31))
    prod(roar(1))
  })
})

test_that("pillar abbreviates a bitmap", {
  skip_if_not_installed("pillar")
  expect_identical(pillar::type_sum(roar(1:3)), "roar")
})
