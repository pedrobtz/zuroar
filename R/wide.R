#' Build a 64-bit bitmap
#'
#' `roar64()` builds a `zuroar64`, a bitmap of whole numbers from 0 to
#' 2^64 - 1, on CRoaring's 64-bit Roaring bitmaps. R has no exact 64-bit
#' integer, so values cross over as canonical decimal text (`"0"` to
#' `"18446744073709551615"`, no sign, no leading zeros), or as doubles
#' below 2^53, where a double is still exact. `roar64()` of a 32-bit
#' bitmap promotes it. `roar64_range()` builds the bitmap of every value
#' from `from` to `to`, both included.
#'
#' A `zuroar64` has the 32-bit API: [roar_add()], [roar_contains()], the
#' set operators, [roar_rank()], positions, [roar_serialize()] and the
#' rest. Values come back as decimal text: `as.character()`, `x[[k]]`,
#' [roar_select()], `min()` and `max()`. `as.double()` works when every
#' value is below 2^53 and is an error otherwise. Counts are doubles, and a
#' count above 2^53 is an error; [roar64_length()] gives the exact
#' cardinality as text. Mixing a `zuroar` and a `zuroar64` in one
#' operation is an error: promote with `roar64()` first.
#'
#' CRoaring's 64-bit bitmaps have no copy-on-write, so every change to a
#' `zuroar64`, such as [roar_add()], copies the whole bitmap.
#'
#' @param values Whole numbers from 0 to 2^64 - 1, as decimal text or as
#'   doubles below 2^53; or a 32-bit bitmap to promote.
#' @inheritParams roar
#' @param from,to The first and last values, both included, as decimal
#'   text or whole doubles below 2^53.
#' @return A bitmap, an object of class `zuroar64`.
#' @export
#' @examples
#' z <- roar64(c("0", "18446744073709551615", "4294967296"))
#' z
#' as.character(z)
#' roar_contains(z, "4294967296")
#'
#' roar64(roar(1:3))
#' roar64_range("18446744073709551610", "18446744073709551615")
roar64 <- function(values = character(), optimize = TRUE) {
  check_flag(optimize, "optimize")
  if (inherits(values, "zuroar")) {
    out <- .Call(zro64_promote, values)
    return(if (optimize) .Call(zro64_optimize, out) else out)
  }
  if (inherits(values, "zuroar64")) {
    return(.Call(zro64_optimize, values))
  }
  .Call(zro64_from_values, check_values(values, wide = TRUE), optimize)
}

#' @rdname roar64
#' @export
roar64_range <- function(from, to) {
  .Call(zro64_from_range, check_range64(from, to))
}

#' The exact size of a 64-bit bitmap
#'
#' `roar64_length()` returns the number of values in `x` as decimal text,
#' exact for every bitmap, including one holding all 2^64 values, where
#' [length()] is an error because a double above 2^53 is not exact.
#'
#' @param x A `zuroar64`.
#' @return A single string.
#' @export
#' @examples
#' roar64_length(roar64(c("1", "2")))
#' roar64_length(roar64_range("0", "1099511627775"))
roar64_length <- function(x) {
  if (!is64(x)) {
    zro_abort("zuroar_error", "`x` must be a zuroar64 bitmap.")
  }
  .Call(zro64_length_text, x)
}

# --- Methods ----------------------------------------------------------------

#' @rdname zuroar-vector
#' @export
length.zuroar64 <- function(x) {
  .Call(zro64_cardinality, x)
}

#' @rdname zuroar-vector
#' @export
Summary.zuroar64 <- function(..., na.rm = FALSE) {
  args <- list(...)
  if (!.Generic %in% c("min", "max", "range")) {
    zro_abort(
      "zuroar_error_unsupported",
      sprintf("%s() is not defined for a zuroar64 bitmap.", .Generic)
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
  if (.Call(zro64_is_empty, x)) {
    zro_abort(
      "zuroar_error_value",
      sprintf("An empty bitmap has no %s.", .Generic)
    )
  }
  switch(
    .Generic,
    min = .Call(zro64_min, x),
    max = .Call(zro64_max, x),
    range = c(.Call(zro64_min, x), .Call(zro64_max, x))
  )
}

#' @rdname zuroar-vector
#' @export
as.character.zuroar64 <- function(x, ...) {
  .Call(zro64_to_r, x, 0L)
}

#' @rdname zuroar-vector
#' @export
as.double.zuroar64 <- function(x, ...) {
  .Call(zro64_to_r, x, 1L)
}

#' @rdname zuroar-vector
#' @export
as.numeric.zuroar64 <- as.double.zuroar64

#' @rdname zuroar-vector
#' @export
as.integer.zuroar64 <- function(x, ...) {
  .Call(zro64_to_r, x, 2L)
}

#' @rdname zuroar-vector
#' @export
format.zuroar64 <- function(x, n = 10, ...) {
  if (.Call(zro64_is_null, x)) {
    return("<zuroar64> null pointer: restore it with roar64_unserialize()")
  }
  if (.Call(zro64_is_empty, x)) {
    return("<zuroar64> empty")
  }
  len <- .Call(zro64_length_text, x)
  shown <- .Call(zro64_head_text, x, n)
  more <- if (len != as.character(length(shown))) " ..." else ""
  sprintf(
    "<zuroar64> %s value%s in [%s, %s]: %s%s",
    len,
    if (len == "1") "" else "s",
    .Call(zro64_min, x),
    .Call(zro64_max, x),
    paste(shown, collapse = " "),
    more
  )
}

#' @rdname zuroar-vector
#' @export
print.zuroar64 <- function(x, n = 10, ...) {
  cat(format(x, n = n), "\n", sep = "")
  invisible(x)
}

#' @exportS3Method pillar::type_sum
type_sum.zuroar64 <- function(x) {
  "roar64"
}

#' @rdname zuroar-index
#' @export
`[.zuroar64` <- function(x, i, ...) {
  if (...length() > 0) {
    index_error("A bitmap has one dimension; use x[i].")
  }
  if (missing(i)) {
    return(.Call(zro64_optimize, x))
  }
  sel <- index_positions(i, length(x))
  runs <- position_runs(sel$positions)
  .Call(zro64_subset, x, runs$starts, runs$ends, sel$keep)
}

#' @rdname zuroar-index
#' @export
`[[.zuroar64` <- function(x, k, ...) {
  if (...length() > 0) {
    index_error("A bitmap has one dimension; use x[[k]].")
  }
  if (length(k) != 1) {
    index_error(
      "`x[[k]]` takes a single position; use roar_select() for several."
    )
  }
  .Call(zro64_select, x, check_positions(k, length(x)))
}

#' @rdname zuroar-index
#' @exportS3Method utils::head
head.zuroar64 <- function(x, n = 6L, ...) {
  k <- end_count(n, length(x))
  if (k == 0) {
    return(roar64())
  }
  .Call(zro64_subset, x, 1, k, TRUE)
}

#' @rdname zuroar-index
#' @exportS3Method utils::tail
tail.zuroar64 <- function(x, n = 6L, ...) {
  len <- length(x)
  k <- end_count(n, len)
  if (k == 0) {
    return(roar64())
  }
  .Call(zro64_subset, x, len - k + 1, as.double(len), TRUE)
}

#' @rdname zuroar-index
#' @export
sort.zuroar64 <- function(x, decreasing = FALSE, ...) {
  if (!identical(decreasing, FALSE)) {
    zro_abort(
      "zuroar_error_unsupported",
      "A bitmap is always in increasing order; use rev(as.character(x)) for the values in decreasing order."
    )
  }
  .Call(zro64_optimize, x)
}

#' @rdname zuroar-index
#' @export
unique.zuroar64 <- function(x, incomparables = FALSE, ...) {
  .Call(zro64_optimize, x)
}

#' @rdname zuroar-index
#' @export
rev.zuroar64 <- rev.zuroar

#' @rdname zuroar-index
#' @export
`[<-.zuroar64` <- `[<-.zuroar`

#' @rdname zuroar-index
#' @export
`[[<-.zuroar64` <- `[[<-.zuroar`
