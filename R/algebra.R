#' Operators on bitmaps
#'
#' Between two bitmaps, `|` is the union and `&` the intersection, each a
#' new bitmap. `==` and `!=` test equality, `x <= y` whether `x` is a
#' subset of `y`, `x < y` whether it is a strict subset, and `>=` and `>`
#' the reverse; each returns a single `TRUE` or `FALSE`.
#'
#' Between a bitmap and a single whole number `k`, `x + k`, `k + x` and
#' `x - k` shift every value by `k`, as [roar_shift()] does. A value that
#' would leave the domain from 0 to 2^32 - 1 is an error; use
#' `roar_shift(drop = TRUE)` to drop such values instead.
#'
#' Everything else is a `zuroar_error_unsupported` error, because a set has
#' no sensible answer:
#'
#' * `!x` would need a universe; use [roar_flip()] over a range.
#' * `x - y` between bitmaps: use [roar_andnot()]. `x ^ y` means power in
#'   R; use [roar_xor()].
#' * `x > 5` and other comparisons with numbers would expand the set into
#'   a logical vector; use `x & roar_range(6, 4294967295)` or
#'   [roar_contains()].
#'
#' @param e1,e2 Bitmaps, or a bitmap and a single whole number.
#' @return A bitmap, or a single logical for the comparisons.
#' @name zuroar-ops
#' @examples
#' x <- roar(c(1, 5, 9))
#' y <- roar(c(5, 9, 12))
#' x | y
#' x & y
#' x <= y
#' roar(5) < y
#' x + 10
NULL

#' @rdname zuroar-ops
#' @export
Ops.zuroar <- function(e1, e2) {
  if (nargs() == 1) {
    unsupported_op(sprintf(
      "Unary %s is not defined for a bitmap.%s",
      .Generic,
      if (.Generic == "!") " Use roar_flip() over a range." else ""
    ))
  }
  b1 <- inherits(e1, "zuroar")
  b2 <- inherits(e2, "zuroar")
  if (b1 && b2) {
    return(switch(
      .Generic,
      "|" = .Call(zro_binop, e1, e2, 1L),
      "&" = .Call(zro_binop, e1, e2, 2L),
      "==" = .Call(zro_compare, e1, e2, 1L),
      "!=" = !.Call(zro_compare, e1, e2, 1L),
      "<=" = .Call(zro_compare, e1, e2, 2L),
      ">=" = .Call(zro_compare, e2, e1, 2L),
      "<" = .Call(zro_compare, e1, e2, 3L),
      ">" = .Call(zro_compare, e2, e1, 3L),
      "-" = unsupported_op(
        "`-` between bitmaps is not defined. Use roar_andnot(x, y) for the difference."
      ),
      "^" = unsupported_op(
        "`^` is not defined for bitmaps. Use roar_xor(x, y) for the symmetric difference."
      ),
      unsupported_op(sprintf("`%s` is not defined between bitmaps.", .Generic))
    ))
  }
  if (.Generic == "+") {
    return(if (b1) shift(e1, e2, "e2") else shift(e2, e1, "e1"))
  }
  if (.Generic == "-" && b1) {
    return(shift(e1, -check_offset(e2, "e2"), "e2"))
  }
  if (.Generic %in% c("==", "!=", "<", "<=", ">", ">=")) {
    unsupported_op(sprintf(
      "`%s` between a bitmap and a number is not defined: it would expand the set. Use `&` with roar_range(), or roar_contains().",
      .Generic
    ))
  }
  unsupported_op(sprintf(
    "`%s` between a bitmap and %s is not defined.",
    .Generic,
    class(if (b1) e2 else e1)[[1]]
  ))
}

unsupported_op <- function(message) {
  zro_abort("zuroar_error_unsupported", message)
}

#' Combine bitmaps
#'
#' `c()` with a bitmap first is the union of its arguments: bitmaps and
#' whole numbers alike, as `sort(unique(c(...)))` is for vectors.
#'
#' @param ... Bitmaps and vectors of whole numbers from 0 to 2^32 - 1.
#' @return A bitmap.
#' @export
#' @examples
#' c(roar(c(1, 5)), roar(9), 2)
c.zuroar <- function(...) {
  args <- list(...)
  bitmaps <- lapply(args, function(a) {
    if (inherits(a, "zuroar")) a else roar(check_values(a), optimize = FALSE)
  })
  .Call(zro_many, bitmaps, 1L)
}

#' Shift every value
#'
#' `roar_shift()` adds `by` to every value of `x`. `x + k` and `x - k` are
#' the same with `drop = FALSE`. A value that would leave the domain from 0
#' to 2^32 - 1 is an error unless `drop = TRUE`, which drops it.
#'
#' @inheritParams roar_add
#' @param by A single whole number, positive or negative.
#' @param drop If `TRUE`, drop values that would leave the domain instead
#'   of signalling an error.
#' @return A bitmap.
#' @export
#' @examples
#' x <- roar(c(0, 5, 9))
#' roar_shift(x, 10)
#' roar_shift(x, -5, drop = TRUE)
roar_shift <- function(x, by, drop = FALSE) {
  check_bitmap(x)
  check_flag(drop, "drop")
  shift(x, check_offset(by, "by"), "by", drop = drop)
}

check_offset <- function(by, arg) {
  if (
    !(is.numeric(by) && length(by) == 1 && !is.na(by) && by == trunc(by)) ||
      is.factor(by)
  ) {
    zro_abort(
      "zuroar_error_value",
      sprintf("`%s` must be a single whole number.", arg)
    )
  }
  as.double(by)
}

shift <- function(x, by, arg, drop = FALSE) {
  by <- check_offset(by, arg)
  len <- .Call(zro_cardinality, x)
  if (by == 0 || len == 0) {
    return(.Call(zro_shift, x, 0))
  }
  top <- 4294967295
  if (abs(by) > top) {
    if (!drop) {
      shift_error(by)
    }
    return(roar())
  }
  lo <- .Call(zro_min, x) + by
  hi <- .Call(zro_max, x) + by
  if (!drop && (lo < 0 || hi > top)) {
    shift_error(by)
  }
  .Call(zro_shift, x, by)
}

shift_error <- function(by) {
  zro_abort(
    "zuroar_error_value",
    sprintf(
      "Shifting by %s moves values outside 0 to 4294967295. Use roar_shift(drop = TRUE) to drop them.",
      format(by, scientific = FALSE)
    )
  )
}

#' Set operations by name
#'
#' `roar_union()` and `roar_intersect()` combine any number of bitmaps.
#' `roar_xor()` is the symmetric difference, the values in exactly one of
#' `x` and `y`, and `roar_andnot()` the difference, the values of `x` not
#' in `y`. `roar_flip()` adds the values of the range `from` to `to` that
#' are missing from `x` and removes those present.
#'
#' @inheritParams roar_add
#' @param y A bitmap.
#' @param ... Bitmaps. `roar_union()` of none is an empty bitmap;
#'   `roar_intersect()` needs at least one.
#' @param from,to The first and last values of the range, both included.
#' @return A bitmap.
#' @seealso [zuroar-ops] for `|` and `&`; [roar_cardinality()] for the
#'   size of a result without building it.
#' @export
#' @examples
#' x <- roar(c(1, 5, 9))
#' y <- roar(c(5, 9, 12))
#' roar_xor(x, y)
#' roar_andnot(x, y)
#' roar_union(x, y, roar(100))
#' roar_intersect(x, y)
#' roar_flip(x, 0, 5)
roar_union <- function(...) {
  .Call(zro_many, check_bitmaps(list(...)), 1L)
}

#' @rdname roar_union
#' @export
roar_intersect <- function(...) {
  xs <- check_bitmaps(list(...))
  if (length(xs) == 0) {
    zro_abort(
      "zuroar_error",
      "roar_intersect() needs at least one bitmap: an empty intersection has no universe."
    )
  }
  .Call(zro_many, xs, 2L)
}

#' @rdname roar_union
#' @export
roar_xor <- function(x, y) {
  check_bitmap(x)
  check_bitmap(y, "y")
  .Call(zro_binop, x, y, 3L)
}

#' @rdname roar_union
#' @export
roar_andnot <- function(x, y) {
  check_bitmap(x)
  check_bitmap(y, "y")
  .Call(zro_binop, x, y, 4L)
}

#' @rdname roar_union
#' @export
roar_flip <- function(x, from, to) {
  check_bitmap(x)
  ends <- check_range(from, to)
  .Call(zro_flip, x, ends)
}

#' Compare sets without building them
#'
#' `roar_cardinality()` counts the values the union, intersection,
#' symmetric difference or difference of `x` and `y` would hold, without
#' building that bitmap. `roar_jaccard()` is the Jaccard index, the size of
#' the intersection over the size of the union; it is `NaN` when both are
#' empty. `roar_intersects()` tells whether `x` and `y` share a value and
#' `roar_disjoint()` whether they share none.
#'
#' @inheritParams roar_union
#' @param op The operation whose result to count: `"and"`, `"or"`,
#'   `"xor"` or `"andnot"`.
#' @return `roar_cardinality()` a single double, `roar_jaccard()` a single
#'   double from 0 to 1, the others a single logical.
#' @export
#' @examples
#' x <- roar(c(1, 5, 9))
#' y <- roar(c(5, 9, 12))
#' roar_cardinality(x, y, op = "and")
#' roar_jaccard(x, y)
#' roar_intersects(x, y)
#' roar_disjoint(x, roar(100))
roar_cardinality <- function(x, y, op = c("and", "or", "xor", "andnot")) {
  check_bitmap(x)
  check_bitmap(y, "y")
  ops <- c(or = 1L, and = 2L, xor = 3L, andnot = 4L)
  if (missing(op)) {
    op <- "and"
  }
  if (!(is.character(op) && length(op) == 1 && op %in% names(ops))) {
    zro_abort(
      "zuroar_error",
      '`op` must be one of "and", "or", "xor" or "andnot".'
    )
  }
  .Call(zro_binop_cardinality, x, y, ops[[op]])
}

#' @rdname roar_cardinality
#' @export
roar_jaccard <- function(x, y) {
  check_bitmap(x)
  check_bitmap(y, "y")
  .Call(zro_jaccard, x, y)
}

#' @rdname roar_cardinality
#' @export
roar_intersects <- function(x, y) {
  check_bitmap(x)
  check_bitmap(y, "y")
  .Call(zro_compare, x, y, 4L)
}

#' @rdname roar_cardinality
#' @export
roar_disjoint <- function(x, y) {
  !roar_intersects(x, y)
}
