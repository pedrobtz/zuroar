# Input checks shared by the R entry points. The C side checks values
# element by element (NA, sign, whole number, domain), so here only the
# type is checked.

check_values <- function(values, arg = "values") {
  if (is.logical(values) && length(values) > 0) {
    zro_abort(
      "zuroar_error_value",
      sprintf(
        "`%s` is a logical vector. Bitmaps hold whole numbers; use which(%s) for the positions of TRUE values.",
        arg,
        arg
      )
    )
  }
  if (is.logical(values)) {
    return(integer())
  }
  if (is.factor(values) || !(is.integer(values) || is.double(values))) {
    zro_abort(
      "zuroar_error_value",
      sprintf(
        "`%s` must be an integer or double vector of whole numbers, not %s.",
        arg,
        class(values)[[1]]
      )
    )
  }
  if (!is.null(attributes(values))) {
    values <- as.vector(values)
  }
  values
}

check_scalar_value <- function(x, arg) {
  if (length(x) != 1) {
    zro_abort(
      "zuroar_error_value",
      sprintf("`%s` must be a single whole number.", arg)
    )
  }
  x <- as.double(check_values(x, arg))
  if (is.na(x) || x < 0 || x > 4294967295 || x != trunc(x)) {
    zro_abort(
      "zuroar_error_value",
      sprintf(
        "`%s` is %s; it must be a whole number from 0 to 4294967295.",
        arg,
        format(x, scientific = FALSE, digits = 17)
      )
    )
  }
  x
}

check_flag <- function(x, arg) {
  if (!(is.logical(x) && length(x) == 1 && !is.na(x))) {
    zro_abort("zuroar_error", sprintf("`%s` must be TRUE or FALSE.", arg))
  }
  invisible(x)
}

check_bitmap <- function(x, arg = "x") {
  if (!inherits(x, "zuroar")) {
    zro_abort(
      "zuroar_error",
      sprintf("`%s` must be a zuroar bitmap, not %s.", arg, class(x)[[1]])
    )
  }
  invisible(x)
}

check_bitmaps <- function(xs) {
  for (i in seq_along(xs)) {
    check_bitmap(xs[[i]], sprintf("..%d", i))
  }
  xs
}

# Inclusive range ends, as a double vector of length two, from <= to.
check_range <- function(from, to) {
  from <- check_scalar_value(from, "from")
  to <- check_scalar_value(to, "to")
  if (from > to) {
    zro_abort(
      "zuroar_error_value",
      sprintf(
        "`from` (%s) must not be larger than `to` (%s).",
        format(from, scientific = FALSE),
        format(to, scientific = FALSE)
      )
    )
  }
  c(from, to)
}
