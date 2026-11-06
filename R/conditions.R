#' Conditions signalled by zuroar
#'
#' Every error zuroar signals inherits from `zuroar_error`, so code can
#' catch them all with `tryCatch(..., zuroar_error = )`. A more specific
#' class says what went wrong:
#'
#' * `zuroar_error_value`: a value outside the domain, such as `NA`, a
#'   negative or fractional number, or one above 2^32 - 1; or an output
#'   type that cannot hold a value, such as `as.integer()` on a bitmap
#'   holding a value above `.Machine$integer.max`.
#' * `zuroar_error_pointer`: a bitmap whose pointer is null. A bitmap is
#'   an external pointer, so it does not survive [saveRDS()] and
#'   [readRDS()] or a trip to another process.
#' * `zuroar_error_unsupported`: an operation a set does not define, such
#'   as `sum()` of a bitmap.
#' * `zuroar_error_memory`: CRoaring could not allocate memory.
#'
#' Match on the class, not on the message, which may change.
#'
#' @name zuroar-conditions
#' @aliases zuroar_error
#' @keywords internal
#' @examples
#' tryCatch(roar(-1), zuroar_error_value = function(e) "out of domain")
NULL

# Signals a zuroar condition. Also called from C through zro_abort().
zro_abort <- function(class, message, call = NULL) {
  cls <- unique(c(class, "zuroar_error", "error", "condition"))
  stop(structure(
    class = cls,
    list(message = message, call = call)
  ))
}
