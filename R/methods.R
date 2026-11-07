#' A bitmap as a sorted vector
#'
#' A bitmap behaves like `sort(unique(v))` kept compressed. It is a vector
#' to R: `length()` is the number of values, an integer, or a double above
#' `.Machine$integer.max`, as for a long vector; `x[[k]]` is the `k`-th
#' smallest value; `x[i]` is a bitmap of the values at positions `i`;
#' `head()` and `tail()` return bitmaps; `v %in% x` and `match(v, x)` work
#' by visiting every value, so [roar_contains()] is the fast membership
#' test. `sum()` adds the values in one pass. `min()`, `max()` and
#' `range()` read the ends without expanding the bitmap; an empty bitmap
#' has none, so they are errors there. `as.double()` returns every value
#' exactly. `as.integer()` does too, and is an error when a value is above
#' `.Machine$integer.max`, rather than giving `NA`. A bitmap can be a
#' data-frame column, and survives [saveRDS()], [serialize()] and a trip to
#' another R process on its own.
#'
#' The values are read from the compressed form on demand and never
#' expanded behind your back: an operation that needs them as a plain
#' vector, such as `x[1] <- 5`, `identical(x, y)` or `cumsum(x)`, is a
#' `zuroar_error_unsupported` error. Compare bitmaps as sets with `==`,
#' and expand one explicitly with `as.double()`.
#'
#' `format()` gives one line describing the bitmap, which `print()` shows.
#' To loop over the values, use `for (v in x)` or `lapply(x, f)`.
#'
#' @param x A bitmap.
#' @param ... For `Summary`, further arguments, which must be absent. For
#'   the others, ignored or passed on.
#' @param na.rm Ignored: a bitmap holds no `NA`.
#' @param row.names,optional,nm As for [as.data.frame.vector()].
#' @param n For `format()` and `print()`, how many values to show.
#' @return `[` returns a bitmap. `min()` and `max()` return a single double,
#'   `range()` two, `sum()` one, `as.double()` and `as.integer()` a vector,
#'   `format()` a string, `print()` `x`, invisibly, and `as.data.frame()`
#'   a data frame with one column.
#' @name zuroar-vector
#' @examples
#' x <- roar(c(1, 5, 9, 100000))
#' length(x)
#' x[[2]]
#' x[2:3]
#' c(5, 6) %in% x
#' range(x)
#' as.integer(x)
#' x
NULL

#' @rdname zuroar-vector
#' @export
as.data.frame.zuroar <- function(
  x,
  row.names = NULL,
  optional = FALSE,
  ...,
  nm = deparse1(substitute(x))
) {
  force(nm)
  as.data.frame.vector(
    x,
    row.names = row.names,
    optional = optional,
    ...,
    nm = nm
  )
}

#' @rdname zuroar-vector
#' @export
Summary.zuroar <- function(..., na.rm = FALSE) {
  args <- list(...)
  if (!.Generic %in% c("min", "max", "range", "sum")) {
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
  if (.Generic == "sum") {
    # Exact on every platform: each run of values is added as a series.
    return(.Call(zro_sum, args[[1]]))
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
# by type_sum(), whose default calls length(). A zuroar answers that from
# its ALTREP Length method, but the 64-bit class, an external pointer, can
# have a null pointer there, and a second error while the first is being
# handled would escape the handler; so the abbreviation is given directly.
# Registered lazily: pillar is only in Suggests.
#' @exportS3Method pillar::type_sum
type_sum.zuroar <- function(x) {
  "roar"
}
