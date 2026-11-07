/* Portable serialisation of 32-bit bitmaps (design §6.4). Untrusted bytes
 * are read only through zro_portable_read() (D8); the unsafe
 * deserialiser without bounds is never called. */
#include "zro_bitmap.h"
#include "zro_portable.h"

#include "zro_init.h"

SEXP zro_serialize(SEXP x, SEXP optimize) {
  const roaring_bitmap_t *src = zro_get(x);
  const roaring_bitmap_t *r = src;
  /* An optimised copy lives in a shell, so that a failed R allocation
   * below cannot leak it. */
  SEXP holder = PROTECT(zro_shell());
  if (Rf_asLogical(optimize) == TRUE) {
    roaring_bitmap_t *copy = roaring_bitmap_copy(src);
    if (copy != NULL) roaring_bitmap_run_optimize(copy);
    zro_attach(holder, copy);
    r = copy;
  }
  size_t n = roaring_bitmap_portable_size_in_bytes(r);
  SEXP out = PROTECT(Rf_allocVector(RAWSXP, (R_xlen_t)n));
  size_t written = roaring_bitmap_portable_serialize(r, (char *)RAW(out));
  if (written != n) {
    zro_abort("zuroar_error", "CRoaring wrote %.0f bytes where %.0f were expected.",
              (double)written, (double)n);
  }
  UNPROTECT(2);
  return out;
}

SEXP zro_unserialize(SEXP bytes, SEXP ignore_trailing) {
  if (TYPEOF(bytes) != RAWSXP) {
    zro_abort("zuroar_error_format", "Expected a raw vector of portable bytes.");
  }
  size_t len = (size_t)XLENGTH(bytes);
  bool ignore = Rf_asLogical(ignore_trailing) == TRUE;
  SEXP out = PROTECT(zro_shell());

  size_t used = 0;
  const char *reason = NULL;
  roaring_bitmap_t *r =
      zro_portable_read((const char *)RAW(bytes), len, &used, &reason);
  if (r == NULL) {
    zro_abort("zuroar_error_format", "Cannot read the bitmap: %s.", reason);
  }
  if (used < len && !ignore) {
    roaring_bitmap_free(r);
    zro_abort("zuroar_error_format",
              "The bitmap ends after %.0f of %.0f bytes; pass trailing = "
              "\"ignore\" to read it anyway.",
              (double)used, (double)len);
  }
  zro_attach(out, r);
  UNPROTECT(1);
  return out;
}
