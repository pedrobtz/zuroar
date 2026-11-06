#' A bitmap as a sorted vector
#'
#' A bitmap behaves like `sort(unique(v))` kept compressed. `length()` is
#' the number of values: an integer, or a double above
#' `.Machine$integer.max`, as for a long vector. `min()`, `max()` and `range()` read the
#' ends without expanding the bitmap; an empty bitmap has none, so they
#' are errors there. `as.double()` returns every value exactly.
#' `as.integer()` does too, and is an error when a value is above
#' `.Machine$integer.max`, rather than giving `NA`.
#'
#' `format()` and `print()` never fail: a bitmap whose pointer did not
#' survive [saveRDS()] prints as a null pointer, and every other function
#' signals `zuroar_error_pointer` on it.
#'
#' To loop over the values, use `for (v in as.double(x))`: R does not let
#' a class define its own iteration.
#'
#' @param x A bitmap.
#' @param ... For `Summary`, further arguments, which must be absent. For
#'   the others, ignored.
#' @param na.rm Ignored: a bitmap holds no `NA`.
#' @param n For `format()` and `print()`, how many values to show.
#' @return `length()` returns a single integer or double, `min()` and
#'   `max()` a single double,
#'   `range()` two, `as.double()` and `as.integer()` a vector, `format()` a
#'   string, and `print()` `x`, invisibly.
#' @name zuroar-vector
#' @examples
#' x <- roar(c(1, 5, 9, 100000))
#' length(x)
#' range(x)
#' as.integer(x)
#' x
NULL

#' @rdname zuroar-vector
#' @export
length.zuroar <- function(x) {
  .Call(zro_cardinality, x)
}

#' @rdname zuroar-vector
#' @export
Summary.zuroar <- function(..., na.rm = FALSE) {
  args <- list(...)
  if (!.Generic %in% c("min", "max", "range")) {
    zro_abort(
      "zuroar_error_unsupported",
      sprintf("%s() is not defined for a zuroar bitmap.", .Generic)
    )
  }
  if (length(args) != 1) {
    zro_abort(
      "zuroar_error_unsupported",
      sprintf(
        "%s() takes one bitmap; combine bitmaps with c() first.",
        .Generic
      )
    )
  }
  x <- args[[1]]
  if (.Call(zro_cardinality, x) == 0) {
    zro_abort(
      "zuroar_error_value",
      sprintf("An empty bitmap has no %s.", .Generic)
    )
  }
  switch(
    .Generic,
    min = .Call(zro_min, x),
    max = .Call(zro_max, x),
    range = c(.Call(zro_min, x), .Call(zro_max, x))
  )
}

#' @rdname zuroar-vector
#' @export
as.double.zuroar <- function(x, ...) {
  .Call(zro_to_double, x)
}

#' @rdname zuroar-vector
#' @export
as.numeric.zuroar <- as.double.zuroar

#' @rdname zuroar-vector
#' @export
as.integer.zuroar <- function(x, ...) {
  .Call(zro_to_integer, x)
}

#' @rdname zuroar-vector
#' @export
format.zuroar <- function(x, n = 10, ...) {
  # Never an error: R and testthat format objects while handling one.
  if (.Call(zro_is_null, x)) {
    return("<zuroar> null pointer: restore it with roar_unserialize()")
  }
  len <- .Call(zro_cardinality, x)
  if (len == 0) {
    return("<zuroar> empty")
  }
  shown <- .Call(zro_head_values, x, n)
  values <- format(shown, scientific = FALSE, trim = TRUE)
  more <- if (len > length(shown)) " ..." else ""
  sprintf(
    "<zuroar> %s value%s in [%s, %s]: %s%s",
    format(len, scientific = FALSE, big.mark = ","),
    if (len == 1) "" else "s",
    format(.Call(zro_min, x), scientific = FALSE),
    format(.Call(zro_max, x), scientific = FALSE),
    paste(values, collapse = " "),
    more
  )
}

#' @rdname zuroar-vector
#' @export
print.zuroar <- function(x, n = 10, ...) {
  cat(format(x, n = n), "\n", sep = "")
  invisible(x)
}

# pillar, and through it rlang's backtraces, describe each object in a call
# by type_sum(), whose default calls length(). On a bitmap whose pointer is
# null that would signal a second error while the first is being handled,
# so the abbreviation is given directly. Registered lazily: pillar is only
# in Suggests.
#' @exportS3Method pillar::type_sum
type_sum.zuroar <- function(x) {
  "roar"
}
