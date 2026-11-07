/* The 32-bit bindings (design §4, item 3). Each entry point validates its R
 * input and copies it into a uint32_t buffer, calls CRoaring, then copies
 * the result out. No R API is called while CRoaring runs, so an R error
 * cannot long-jump through CRoaring's stack, and every bitmap is attached
 * to its zuroar object (or freed) before anything can signal. The object
 * itself, an ALTREP vector, lives in zro_altrep.c. */
#include "zro_bitmap.h"

#include <math.h>
#include <stdarg.h>

#include "zro_init.h"

#define ZRO_U32_MAX 4294967295.0

/* --- Conditions --------------------------------------------------------- */

NORET void zro_abort(const char *cls, const char *fmt, ...) {
  char msg[512];
  va_list ap;
  va_start(ap, fmt);
  vsnprintf(msg, sizeof msg, fmt, ap);
  va_end(ap);

  SEXP name = PROTECT(Rf_mkString("zuroar"));
  SEXP ns = PROTECT(R_FindNamespace(name));
  SEXP cls_s = PROTECT(Rf_mkString(cls));
  SEXP msg_s = PROTECT(Rf_mkString(msg));
  SEXP call = PROTECT(Rf_lang3(Rf_install("zro_abort"), cls_s, msg_s));
  Rf_eval(call, ns);
  UNPROTECT(5);
  Rf_error("%s", msg); /* not reached: zro_abort() always signals */
}

/* --- Portable bytes ----------------------------------------------------- */

roaring_bitmap_t *zro_portable_read(const unsigned char *buf, size_t len,
                                    size_t *used, const char **reason) {
  *used = 0;
  size_t need = roaring_bitmap_portable_deserialize_size((const char *)buf, len);
  if (need == 0) {
    *reason = "the header is not a Roaring bitmap's, or the bytes are truncated";
    return NULL;
  }
  roaring_bitmap_t *r =
      roaring_bitmap_portable_deserialize_safe((const char *)buf, need);
  if (r == NULL) {
    *reason = "the bytes could not be read as containers";
    return NULL;
  }
  if (!roaring_bitmap_internal_validate(r, reason)) {
    roaring_bitmap_free(r);
    return NULL;
  }
  *used = need;
  return r;
}

/* --- Values ------------------------------------------------------------- */

#define ZRO_DOMAIN "must be whole numbers from 0 to 4294967295"

void zro_values_u32(SEXP v, uint32_t *out) {
  R_xlen_t n = XLENGTH(v);
  if (TYPEOF(v) == INTSXP) {
    const int *p = INTEGER(v);
    for (R_xlen_t i = 0; i < n; i++) {
      if (p[i] == NA_INTEGER) {
        zro_abort("zuroar_error_value", "Element %.0f is NA; values " ZRO_DOMAIN ".",
                  (double)(i + 1));
      }
      if (p[i] < 0) {
        zro_abort("zuroar_error_value", "Element %.0f is %d; values " ZRO_DOMAIN ".",
                  (double)(i + 1), p[i]);
      }
      out[i] = (uint32_t)p[i];
    }
  } else if (TYPEOF(v) == REALSXP) {
    const double *p = REAL(v);
    for (R_xlen_t i = 0; i < n; i++) {
      double d = p[i];
      if (ISNAN(d)) {
        zro_abort("zuroar_error_value", "Element %.0f is NA; values " ZRO_DOMAIN ".",
                  (double)(i + 1));
      }
      if (!(d >= 0 && d <= ZRO_U32_MAX && d == floor(d))) {
        zro_abort("zuroar_error_value", "Element %.0f is %.17g; values " ZRO_DOMAIN ".",
                  (double)(i + 1), d);
      }
      out[i] = (uint32_t)d;
    }
  } else {
    zro_abort("zuroar_error_value", "Values " ZRO_DOMAIN ".");
  }
}

static uint32_t *zro_buffer(R_xlen_t n) {
  /* R_alloc'd memory is released when the .Call returns, and an allocation
   * failure signals before any CRoaring state exists. */
  return (uint32_t *)R_alloc(n > 0 ? (size_t)n : 1, sizeof(uint32_t));
}

/* --- Building ----------------------------------------------------------- */

SEXP zro_from_values(SEXP v, SEXP optimize) {
  R_xlen_t n = XLENGTH(v);
  uint32_t *buf = zro_buffer(n);
  zro_values_u32(v, buf);
  bool opt = Rf_asLogical(optimize) == TRUE;

  SEXP out = PROTECT(zro_shell());
  roaring_bitmap_t *r = roaring_bitmap_of_ptr((size_t)n, buf);
  if (r != NULL && opt) {
    roaring_bitmap_run_optimize(r);
    roaring_bitmap_shrink_to_fit(r);
  }
  zro_attach(out, r);
  UNPROTECT(1);
  return out;
}

/* `range` holds the inclusive ends, already checked to be whole numbers in
 * the domain with from <= to. */
SEXP zro_from_range(SEXP range) {
  uint32_t ends[2];
  if (XLENGTH(range) != 2) zro_abort("zuroar_error", "Expected two range ends.");
  zro_values_u32(range, ends);

  SEXP out = PROTECT(zro_shell());
  /* CRoaring's range is half-open, [min, max). */
  roaring_bitmap_t *r =
      roaring_bitmap_from_range((uint64_t)ends[0], (uint64_t)ends[1] + 1, 1);
  if (r != NULL) {
    roaring_bitmap_run_optimize(r);
    roaring_bitmap_shrink_to_fit(r);
  }
  zro_attach(out, r);
  UNPROTECT(1);
  return out;
}

/* --- Changing a copy ---------------------------------------------------- */

static SEXP zro_change(SEXP x, SEXP v, bool add) {
  const roaring_bitmap_t *src = zro_get(x);
  R_xlen_t n = XLENGTH(v);
  uint32_t *buf = zro_buffer(n);
  zro_values_u32(v, buf);

  SEXP out = PROTECT(zro_shell());
  /* With copy-on-write on, the copy shares every container; the change
   * unshares only the ones it touches. `x` itself is never modified. */
  roaring_bitmap_t *r = roaring_bitmap_copy(src);
  if (r != NULL) {
    if (add) {
      roaring_bitmap_add_many(r, (size_t)n, buf);
    } else {
      roaring_bitmap_remove_many(r, (size_t)n, buf);
    }
  }
  zro_attach(out, r);
  UNPROTECT(1);
  return out;
}

SEXP zro_add(SEXP x, SEXP v) { return zro_change(x, v, true); }
SEXP zro_remove(SEXP x, SEXP v) { return zro_change(x, v, false); }

/* --- Queries ------------------------------------------------------------ */

SEXP zro_contains(SEXP x, SEXP v) {
  const roaring_bitmap_t *r = zro_get(x);
  R_xlen_t n = XLENGTH(v);
  uint32_t *buf = zro_buffer(n);
  zro_values_u32(v, buf);

  SEXP out = PROTECT(Rf_allocVector(LGLSXP, n));
  int *o = LOGICAL(out);
  roaring_bulk_context_t ctx = {0};
  for (R_xlen_t i = 0; i < n; i++) {
    o[i] = roaring_bitmap_contains_bulk(r, &ctx, buf[i]) ? TRUE : FALSE;
  }
  UNPROTECT(1);
  return out;
}

SEXP zro_cardinality(SEXP x) {
  const roaring_bitmap_t *r = zro_get(x);
  return Rf_ScalarReal((double)roaring_bitmap_get_cardinality(r));
}

/* min and max of a non-empty bitmap; the R side handles the empty one. */
SEXP zro_min(SEXP x) {
  const roaring_bitmap_t *r = zro_get(x);
  return Rf_ScalarReal((double)roaring_bitmap_minimum(r));
}

SEXP zro_max(SEXP x) {
  const roaring_bitmap_t *r = zro_get(x);
  return Rf_ScalarReal((double)roaring_bitmap_maximum(r));
}

/* --- Back to R ---------------------------------------------------------- */

#define ZRO_CHUNK 4096

SEXP zro_to_double(SEXP x) {
  const roaring_bitmap_t *r = zro_get(x);
  uint64_t n = roaring_bitmap_get_cardinality(r);
  SEXP out = PROTECT(Rf_allocVector(REALSXP, (R_xlen_t)n));
  double *o = REAL(out);
  uint32_t chunk[ZRO_CHUNK];
  roaring_uint32_iterator_t it;
  roaring_iterator_init(r, &it);
  uint64_t done = 0;
  while (done < n) {
    uint32_t got = roaring_uint32_iterator_read(&it, chunk, ZRO_CHUNK);
    if (got == 0) break;
    for (uint32_t i = 0; i < got; i++) o[done + i] = (double)chunk[i];
    done += got;
  }
  UNPROTECT(1);
  return out;
}

SEXP zro_to_integer(SEXP x) {
  const roaring_bitmap_t *r = zro_get(x);
  uint64_t n = roaring_bitmap_get_cardinality(r);
  if (n > 0 && roaring_bitmap_maximum(r) > (uint32_t)INT_MAX) {
    zro_abort("zuroar_error_value",
              "The bitmap holds %.0f, above .Machine$integer.max; use "
              "as.double() instead.",
              (double)roaring_bitmap_maximum(r));
  }
  SEXP out = PROTECT(Rf_allocVector(INTSXP, (R_xlen_t)n));
  /* Every value is at most INT_MAX, so its uint32_t bits are the int. */
  if (n > 0) roaring_bitmap_to_uint32_array(r, (uint32_t *)INTEGER(out));
  UNPROTECT(1);
  return out;
}

/* The first `n` values as doubles, for format(). */
SEXP zro_head_values(SEXP x, SEXP n_) {
  const roaring_bitmap_t *r = zro_get(x);
  uint64_t card = roaring_bitmap_get_cardinality(r);
  double want = Rf_asReal(n_);
  uint64_t n = (want > 0) ? (uint64_t)want : 0;
  if (n > card) n = card;
  if (n > ZRO_CHUNK) n = ZRO_CHUNK;
  uint32_t chunk[ZRO_CHUNK];
  if (n > 0) roaring_bitmap_range_uint32_array(r, 0, (size_t)n, chunk);
  SEXP out = PROTECT(Rf_allocVector(REALSXP, (R_xlen_t)n));
  for (uint64_t i = 0; i < n; i++) REAL(out)[i] = (double)chunk[i];
  UNPROTECT(1);
  return out;
}
