#' Build a bitmap
#'
#' `roar()` builds a 32-bit bitmap from whole numbers between 0 and
#' 2^32 - 1, in any order and with or without duplicates. `roar_range()`
#' builds one holding every whole number from `from` to `to`, both
#' included, as [seq()] does.
#'
#' A bitmap is a compressed set: it stores each value once, in increasing
#' order, and answers [length()], [min()], [max()] and [roar_contains()]
#' without expanding into a vector. [as.integer()] and [as.double()] give
#' its values back.
#'
#' @param values Whole numbers from 0 to 2^32 - 1, as an integer or double
#'   vector. `NA`, negative and fractional values are errors. A logical
#'   vector is an error too: use [which()] to turn one into positions.
#' @param optimize If `TRUE`, the default, use run-length containers where
#'   they are smaller, and release spare capacity.
#' @param from,to The first and last values of the range, both included.
#'   `from` must not be larger than `to`.
#' @return A bitmap, an object of class `zuroar`.
#' @seealso [roar_add()] and [roar_remove()] to change a bitmap.
#' @export
#' @examples
#' x <- roar(c(9, 1, 5, 5, 100000))
#' x
#' length(x)
#' as.double(x)
#'
#' roar_range(1, 1e6)
roar <- function(values = integer(), optimize = TRUE) {
  values <- check_values(values)
  check_flag(optimize, "optimize")
  .Call(zro_from_values, values, optimize)
}

#' @rdname roar
#' @export
roar_range <- function(from, to) {
  .Call(zro_from_range, check_range(from, to))
}

#' Add or remove values
#'
#' `roar_add()` returns a copy of `x` with values added and `roar_remove()`
#' one with values removed: either the `values` given, or every whole
#' number from `from` to `to`, both included. Neither changes `x`: like
#' every zuroar function, they return a new bitmap. The copy shares
#' CRoaring's containers with `x` until it changes them, so adding one
#' value to a large bitmap does not copy it.
#'
#' @param x A bitmap.
#' @inheritParams roar
#' @param from,to Instead of `values`, the first and last values of a
#'   range, both included.
#' @return A bitmap.
#' @export
#' @examples
#' x <- roar(c(1, 5, 9))
#' roar_add(x, 7)
#' roar_remove(x, 5)
#' x
#'
#' y <- roar_range(1, 100)
#' roar_remove(y, from = 10, to = 89)
roar_add <- function(x, values, from, to) {
  check_bitmap(x)
  change(x, values, from, to, add = TRUE, missing(values))
}

#' @rdname roar_add
#' @export
roar_remove <- function(x, values, from, to) {
  check_bitmap(x)
  change(x, values, from, to, add = FALSE, missing(values))
}

change <- function(x, values, from, to, add, no_values) {
  has_range <- !missing(from) || !missing(to)
  if (no_values == !has_range) {
    zro_abort(
      "zuroar_error",
      "Give either `values`, or both `from` and `to`."
    )
  }
  if (has_range) {
    if (missing(from) || missing(to)) {
      zro_abort("zuroar_error", "Give both `from` and `to`.")
    }
    if (is64(x)) {
      return(.Call(zro64_change_range, x, check_range64(from, to), add))
    }
    return(.Call(zro_change_range, x, check_range(from, to), add))
  }
  if (is64(x)) {
    values <- check_values(values, wide = TRUE)
    return(
      if (add) .Call(zro64_add, x, values) else .Call(zro64_remove, x, values)
    )
  }
  values <- check_values(values)
  if (add) .Call(zro_add, x, values) else .Call(zro_remove, x, values)
}

#' Test membership
#'
#' `roar_contains()` tells, for each of `values`, whether `x` holds it.
#' It is the fast form of `values %in% x`, which works too but visits
#' every value of `x`.
#'
#' @inheritParams roar_add
#' @param values Whole numbers from 0 to 2^32 - 1; for a `zuroar64`,
#'   decimal text or doubles below 2^53.
#' @return A logical vector as long as `values`.
#' @export
#' @examples
#' x <- roar(c(1, 5, 9))
#' roar_contains(x, c(5, 6))
roar_contains <- function(x, values) {
  check_bitmap(x)
  if (is64(x)) {
    return(.Call(zro64_contains, x, check_values(values, wide = TRUE)))
  }
  .Call(zro_contains, x, check_values(values))
}
