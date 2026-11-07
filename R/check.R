# Input checks shared by the R entry points. The C side checks values
# element by element (NA, sign, whole number, domain), so here only the
# type is checked.

check_values <- function(values, arg = "values", wide = FALSE) {
  if (wide && is.character(values)) {
    # Canonical decimal text; the C side checks each string.
    return(as.vector(values))
  }
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
        "`%s` must be %s of whole numbers, not %s.",
        arg,
        if (wide) {
          "decimal text or a double vector"
        } else {
          "an integer or double vector"
        },
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
  if (!inherits(x, c("zuroar", "zuroar64"))) {
    zro_abort(
      "zuroar_error",
      sprintf("`%s` must be a zuroar bitmap, not %s.", arg, class(x)[[1]])
    )
  }
  invisible(x)
}

is64 <- function(x) inherits(x, "zuroar64")

# Two bitmaps in one operation must have the same width (design §6.1).
check_same <- function(x, y) {
  if (is64(x) != is64(y)) {
    zro_abort(
      "zuroar_error_unsupported",
      "Cannot mix a zuroar and a zuroar64 bitmap in one operation; promote the 32-bit one with roar64()."
    )
  }
  invisible(x)
}

# A 64-bit range end: one canonical decimal string or a whole double below
# 2^53, returned as text so the two ends share a type. The C side parses
# and checks the text.
check_scalar_value64 <- function(x, arg) {
  if (length(x) != 1 || is.factor(x)) {
    zro_abort(
      "zuroar_error_value",
      sprintf("`%s` must be a single whole number or decimal string.", arg)
    )
  }
  if (is.character(x)) {
    return(as.vector(x))
  }
  x <- as.double(check_values(x, arg))
  if (is.na(x) || x < 0 || x >= 2^53 || x != trunc(x)) {
    zro_abort(
      "zuroar_error_value",
      sprintf(
        "`%s` is %s; give a whole number below 2^53, or decimal text.",
        arg,
        format(x, scientific = FALSE, digits = 17)
      )
    )
  }
  sprintf("%.0f", x)
}

check_range64 <- function(from, to) {
  c(check_scalar_value64(from, "from"), check_scalar_value64(to, "to"))
}

check_bitmaps <- function(xs) {
  for (i in seq_along(xs)) {
    check_bitmap(xs[[i]], sprintf("..%d", i))
    check_same(xs[[1]], xs[[i]])
  }
  xs
}

check_pair <- function(x, y) {
  check_bitmap(x)
  check_bitmap(y, "y")
  check_same(x, y)
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

index_error <- function(message) {
  zro_abort("zuroar_error_index", message)
}

# Positions counting from 1, for roar_select() and `[[`: whole numbers in
# 1..len, returned as doubles.
check_positions <- function(k, len) {
  if (is.factor(k) || !(is.numeric(k))) {
    index_error("Positions must be whole numbers.")
  }
  k <- as.double(k)
  if (anyNA(k)) {
    index_error("Positions must not be NA.")
  }
  if (any(k != trunc(k))) {
    index_error("Positions must be whole numbers.")
  }
  bad <- k < 1 | k > len
  if (any(bad)) {
    index_error(sprintf(
      "Position %s is outside 1 to %s.",
      format(k[which(bad)[1]], scientific = FALSE),
      format(len, scientific = FALSE)
    ))
  }
  k
}
