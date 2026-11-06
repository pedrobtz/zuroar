#' Positions in a bitmap
#'
#' A bitmap is a sorted vector without duplicates, so its values have
#' positions, counting from 1. `x[i]` returns a bitmap of the values at
#' positions `i`, as `[` keeps the class of a `Date`: positive positions
#' select, negative ones exclude, and a logical `i` is a mask over
#' positions, recycled as R recycles one. Order and repetition in `i` do
#' not matter, since the result is a set. Mixing signs, `NA`, and a
#' position past the end are `zuroar_error_index` errors, because a bitmap
#' holds no `NA`.
#'
#' `x[[k]]` is the `k`-th smallest value as a double; [roar_select()] is
#' its vectorised form. `head()` and `tail()` return bitmaps and follow
#' R's rules for a negative `n`. `sort()` and `unique()` return `x`.
#'
#' `v %in% x` and `match(v, x)` are errors from R itself, which accepts
#' only vectors there: use [roar_contains()] for membership and
#' [roar_rank()] for positions, or `v %in% as.double(x)`.
#'
#' Some vector operations have no meaning for a set and are
#' `zuroar_error_unsupported` errors: `x[i] <- v` and `x[[k]] <- v` (use
#' [roar_add()] and [roar_remove()]), `rev(x)` and
#' `sort(x, decreasing = TRUE)` (use `rev(as.double(x))`).
#'
#' @param x A bitmap.
#' @param i Positions: positive or negative whole numbers, or a logical
#'   mask. Missing, it selects every value.
#' @param k A single position.
#' @param n For `head()` and `tail()`, how many values to keep, or, when
#'   negative, how many to drop from the other end.
#' @param decreasing Must be `FALSE`.
#' @param incomparables Ignored.
#' @param value Not used: assignment is an error.
#' @param ... Must be empty for `[` and `[[`; ignored otherwise.
#' @return `[`, `head()`, `tail()`, `sort()` and `unique()` a bitmap, `[[`
#'   a single double.
#' @name zuroar-index
#' @examples
#' x <- roar(c(1, 7, 9, 100000))
#' x[2:3]
#' x[-1]
#' x[c(TRUE, FALSE)]
#' x[[2]]
#' head(x, 2)
#' tail(x, -1)
#' roar_contains(x, 9)
NULL

#' @rdname zuroar-index
#' @export
`[.zuroar` <- function(x, i, ...) {
  if (...length() > 0) {
    index_error("A bitmap has one dimension; use x[i].")
  }
  if (missing(i)) {
    return(.Call(zro_optimize, x))
  }
  len <- length(x)
  sel <- index_positions(i, len)
  runs <- position_runs(sel$positions)
  .Call(zro_subset, x, runs$starts, runs$ends, sel$keep)
}

#' @rdname zuroar-index
#' @export
`[[.zuroar` <- function(x, k, ...) {
  if (...length() > 0) {
    index_error("A bitmap has one dimension; use x[[k]].")
  }
  if (length(k) != 1) {
    index_error(
      "`x[[k]]` takes a single position; use roar_select() for several."
    )
  }
  .Call(zro_select, x, check_positions(k, length(x)))
}

#' @rdname zuroar-index
#' @exportS3Method utils::head
head.zuroar <- function(x, n = 6L, ...) {
  len <- length(x)
  k <- end_count(n, len)
  if (k == 0) {
    return(roar())
  }
  .Call(zro_subset, x, 1, k, TRUE)
}

#' @rdname zuroar-index
#' @exportS3Method utils::tail
tail.zuroar <- function(x, n = 6L, ...) {
  len <- length(x)
  k <- end_count(n, len)
  if (k == 0) {
    return(roar())
  }
  .Call(zro_subset, x, len - k + 1, as.double(len), TRUE)
}

#' @rdname zuroar-index
#' @export
sort.zuroar <- function(x, decreasing = FALSE, ...) {
  if (!identical(decreasing, FALSE)) {
    zro_abort(
      "zuroar_error_unsupported",
      "A bitmap is always in increasing order; use rev(as.double(x)) for the values in decreasing order."
    )
  }
  .Call(zro_optimize, x)
}

#' @rdname zuroar-index
#' @export
unique.zuroar <- function(x, incomparables = FALSE, ...) {
  .Call(zro_optimize, x)
}

#' @rdname zuroar-index
#' @export
rev.zuroar <- function(x) {
  zro_abort(
    "zuroar_error_unsupported",
    "A set has no reversed form; use rev(as.double(x)) for the values in decreasing order."
  )
}

#' @rdname zuroar-index
#' @export
`[<-.zuroar` <- function(x, i, ..., value) {
  zro_abort(
    "zuroar_error_unsupported",
    "Assigning by position has no meaning for a set; use roar_add() and roar_remove()."
  )
}

#' @rdname zuroar-index
#' @export
`[[<-.zuroar` <- function(x, i, ..., value) {
  zro_abort(
    "zuroar_error_unsupported",
    "Assigning by position has no meaning for a set; use roar_add() and roar_remove()."
  )
}

# How many values head() or tail() keep, following R's rules for n.
end_count <- function(n, len) {
  if (!(is.numeric(n) && length(n) == 1 && !is.na(n)) || is.factor(n)) {
    index_error("`n` must be a single whole number.")
  }
  n <- trunc(as.double(n))
  if (n >= 0) min(n, len) else max(len + n, 0)
}

# Turns an index into sorted, unique positions counting from 1, and whether
# they are kept (positive or logical) or dropped (negative).
index_positions <- function(i, len) {
  if (is.logical(i)) {
    if (anyNA(i)) {
      index_error("The index must not be NA: a bitmap holds no NA.")
    }
    if (length(i) > len) {
      index_error(sprintf(
        "The logical index has %s elements, more than the bitmap's %s.",
        format(length(i), scientific = FALSE),
        format(len, scientific = FALSE)
      ))
    }
    if (len == 0 || length(i) == 0) {
      return(list(positions = numeric(), keep = TRUE))
    }
    return(list(positions = as.double(which(rep_len(i, len))), keep = TRUE))
  }
  if (is.factor(i) || !is.numeric(i)) {
    index_error("The index must be numeric positions or a logical mask.")
  }
  i <- as.double(i)
  if (anyNA(i)) {
    index_error("The index must not be NA: a bitmap holds no NA.")
  }
  i <- trunc(i)
  i <- i[i != 0]
  if (length(i) == 0) {
    return(list(positions = numeric(), keep = TRUE))
  }
  pos <- all(i > 0)
  if (!pos && !all(i < 0)) {
    index_error("Positive and negative positions cannot be mixed.")
  }
  p <- sort(unique(abs(i)))
  if (p[length(p)] > len) {
    index_error(sprintf(
      "Position %s is past the end of a bitmap of length %s.",
      format(p[length(p)], scientific = FALSE),
      format(len, scientific = FALSE)
    ))
  }
  list(positions = p, keep = pos)
}

# Sorted unique positions as runs of consecutive ones.
position_runs <- function(p) {
  if (length(p) == 0) {
    return(list(starts = numeric(), ends = numeric()))
  }
  brk <- diff(p) != 1
  list(starts = p[c(TRUE, brk)], ends = p[c(brk, TRUE)])
}
