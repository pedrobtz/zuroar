#' Ordered queries
#'
#' A bitmap is sorted, so it answers order questions directly.
#' `roar_rank()` counts the values at or below each of `values`, and
#' `roar_select()` returns the `k`-th smallest value, counting from 1, so
#' `roar_select(x, roar_rank(x, v))` is `v` for every `v` in `x`.
#' `roar_next()` and `roar_prev()` return the nearest value at or above,
#' or at or below, each of `values`, and `NA` where there is none.
#'
#' `roar_count()` counts the values from `from` to `to`, both included,
#' and `roar_contains_range()` tells whether every one of them is present.
#'
#' @inheritParams roar_add
#' @param values Whole numbers from 0 to 2^32 - 1.
#' @param k Positions, counting from 1 up to `length(x)`.
#' @param from,to The first and last values of a range, both included.
#' @return `roar_rank()` and `roar_count()` doubles, `roar_select()`,
#'   `roar_next()` and `roar_prev()` doubles as long as their second
#'   argument, `roar_contains_range()` a single logical.
#' @export
#' @examples
#' x <- roar(c(1, 7, 9, 100000))
#' roar_rank(x, 9)
#' roar_select(x, c(1, 2))
#' roar_next(x, 8)
#' roar_prev(x, 8)
#' roar_next(x, 200000)
#'
#' y <- roar_range(1, 1e6)
#' roar_count(y, from = 10, to = 20)
#' roar_contains_range(y, from = 1, to = 9)
roar_rank <- function(x, values) {
  check_bitmap(x)
  .Call(zro_rank, x, check_values(values))
}

#' @rdname roar_rank
#' @export
roar_select <- function(x, k) {
  check_bitmap(x)
  .Call(zro_select, x, check_positions(k, length(x)))
}

#' @rdname roar_rank
#' @export
roar_next <- function(x, values) {
  check_bitmap(x)
  .Call(zro_next, x, check_values(values))
}

#' @rdname roar_rank
#' @export
roar_prev <- function(x, values) {
  check_bitmap(x)
  .Call(zro_prev, x, check_values(values))
}

#' @rdname roar_rank
#' @export
roar_count <- function(x, from, to) {
  check_bitmap(x)
  .Call(zro_range_count, x, check_range(from, to))
}

#' @rdname roar_rank
#' @export
roar_contains_range <- function(x, from, to) {
  check_bitmap(x)
  .Call(zro_contains_range, x, check_range(from, to))
}

#' Extract a bounded number of values
#'
#' `roar_values()` returns at most `n` values of `x`, starting with the
#' smallest at or above `from`. Unlike [as.double()], it never builds more
#' than `n` values, so it is the way to look at part of a large bitmap.
#'
#' @inheritParams roar_add
#' @param from The smallest value to consider.
#' @param n The most values to return: a whole number, or `Inf` for all.
#' @param type `"double"`, the default, or `"integer"`, which is an error
#'   when a returned value is above `.Machine$integer.max`.
#' @return A double or integer vector of at most `n` values.
#' @export
#' @examples
#' y <- roar_range(1, 1e6)
#' roar_values(y, from = 500, n = 5)
#' roar_values(y, n = 3, type = "integer")
roar_values <- function(x, from = 0, n, type = c("double", "integer")) {
  check_bitmap(x)
  from <- check_scalar_value(from, "from")
  if (
    missing(n) ||
      !(is.numeric(n) && length(n) == 1 && !is.na(n) && n >= 0) ||
      (is.finite(n) && n != trunc(n))
  ) {
    zro_abort(
      "zuroar_error_value",
      "`n` must be a single non-negative whole number, or Inf."
    )
  }
  type <- if (missing(type)) "double" else type
  if (
    !(is.character(type) &&
      length(type) == 1 &&
      type %in% c("double", "integer"))
  ) {
    zro_abort("zuroar_error", '`type` must be "double" or "integer".')
  }
  .Call(zro_values, x, from, as.double(n), type == "integer")
}

#' Storage
#'
#' `roar_optimize()` returns a copy of `x` that uses run-length containers
#' where they are smaller and holds no spare capacity; [roar()] does this
#' by default. `roar_stats()` describes how `x` is stored: for each kind
#' of CRoaring container, how many there are, how many values they hold
#' and how many bytes they use. `roar_size()` is the number of bytes the
#' portable serialised form of `x` takes.
#'
#' @inheritParams roar_add
#' @return `roar_optimize()` a bitmap, `roar_stats()` a data frame with
#'   columns `kind`, `containers`, `values` and `bytes`, `roar_size()` a
#'   single double.
#' @export
#' @examples
#' x <- roar(c(1:10, 100000:200000), optimize = FALSE)
#' roar_stats(x)
#' roar_stats(roar_optimize(x))
#' roar_size(x)
roar_optimize <- function(x) {
  check_bitmap(x)
  .Call(zro_optimize, x)
}

#' @rdname roar_optimize
#' @export
roar_stats <- function(x) {
  check_bitmap(x)
  st <- .Call(zro_stats, x)
  data.frame(
    kind = attr(st, "kind"),
    containers = st$containers,
    values = st$values,
    bytes = st$bytes
  )
}

#' @rdname roar_optimize
#' @export
roar_size <- function(x) {
  check_bitmap(x)
  .Call(zro_size, x)
}
