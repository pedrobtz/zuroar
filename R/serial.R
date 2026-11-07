#' Serialise a bitmap
#'
#' `roar_serialize()` writes `x` in the portable Roaring format, the one
#' that the C, C++, Java, Go, Rust and Python implementations share, as a
#' raw vector. `roar_unserialize()` reads such bytes back into a 32-bit
#' bitmap and `roar64_unserialize()` into a `zuroar64`. The two formats
#' share no marker that tells them apart, so the caller chooses the reader;
#' it is never guessed from the bytes.
#'
#' A bitmap also survives [saveRDS()], [serialize()] and a trip to another
#' R process on its own, through the same format. Use `roar_serialize()`
#' for bytes that other programs, or other Roaring libraries, will read.
#'
#' `roar_unserialize()` treats its input as untrusted. It checks the
#' length the header claims, reads with CRoaring's bounded deserialiser,
#' which never reads past the end, and validates the result, so corrupt or
#' hostile bytes give a `zuroar_error_format` error rather than a crash.
#'
#' @inheritParams roar_add
#' @param optimize If `TRUE`, write run-length containers wherever they
#'   are smaller, from an optimised copy; `x` itself is not changed.
#' @param bytes A raw vector holding a portable bitmap: 32-bit for
#'   `roar_unserialize()`, 64-bit for `roar64_unserialize()`.
#' @param trailing What to do with bytes after the end of the bitmap:
#'   `"error"`, the default, or `"ignore"`.
#' @return `roar_serialize()` a raw vector, `roar_unserialize()` a
#'   `zuroar` and `roar64_unserialize()` a `zuroar64`.
#' @seealso [roar_size()] for the number of bytes `roar_serialize()` writes.
#' @export
#' @examples
#' x <- roar(c(1, 5, 9, 100000))
#' b <- roar_serialize(x)
#' b
#' roar_unserialize(b)
#'
#' path <- tempfile(fileext = ".roar")
#' writeBin(roar_serialize(x), path)
#' roar_unserialize(readBin(path, "raw", file.size(path)))
roar_serialize <- function(x, optimize = FALSE) {
  check_bitmap(x)
  check_flag(optimize, "optimize")
  (if (is64(x)) {
    .Call(zro64_serialize, x, optimize)
  } else {
    .Call(zro_serialize, x, optimize)
  })
}

#' @rdname roar_serialize
#' @export
roar_unserialize <- function(bytes, trailing = c("error", "ignore")) {
  unserialize_bytes(bytes, trailing, missing(trailing), wide = FALSE)
}

#' @rdname roar_serialize
#' @export
roar64_unserialize <- function(bytes, trailing = c("error", "ignore")) {
  unserialize_bytes(bytes, trailing, missing(trailing), wide = TRUE)
}

unserialize_bytes <- function(bytes, trailing, default, wide) {
  if (!is.raw(bytes)) {
    zro_abort(
      "zuroar_error_format",
      sprintf("`bytes` must be a raw vector, not %s.", class(bytes)[[1]])
    )
  }
  trailing <- if (default) "error" else trailing
  if (
    !(is.character(trailing) &&
      length(trailing) == 1 &&
      trailing %in% c("error", "ignore"))
  ) {
    zro_abort("zuroar_error", '`trailing` must be "error" or "ignore".')
  }
  ignore <- trailing == "ignore"
  if (wide) {
    .Call(zro64_unserialize, bytes, ignore)
  } else {
    .Call(zro_unserialize, bytes, ignore)
  }
}

#' Send bitmaps to mirai workers
#'
#' A 32-bit bitmap travels to `mirai` daemons with no configuration: R's
#' own serialisation writes it in the portable format. The configuration
#' `roar_serial_config()` returns, for `mirai::daemons(serial = )`, is
#' needed for the 64-bit class, which is an external pointer; it is
#' harmless for 32-bit bitmaps, and only the bitmaps actually sent are
#' serialised.
#'
#' @return A serialisation configuration from `mirai::serial_config()`.
#' @export
#' @examples
#' if (requireNamespace("mirai", quietly = TRUE)) {
#'   cfg <- roar_serial_config()
#'   # mirai::daemons(2, serial = cfg)
#' }
roar_serial_config <- function() {
  if (!requireNamespace("mirai", quietly = TRUE)) {
    zro_abort(
      "zuroar_error",
      "roar_serial_config() needs the mirai package (>= 2.3.0); install it with install.packages(\"mirai\")."
    )
  }
  mirai::serial_config(
    c("zuroar", "zuroar64"),
    list(roar_serialize, roar_serialize),
    list(roar_unserialize, roar64_unserialize)
  )
}
