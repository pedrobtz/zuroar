/* The 64-bit bindings, on CRoaring's roaring64 (design §2, §6.1). Values
 * cross the R boundary as canonical decimal text, or as doubles below 2^53
 * where every value fits exactly (D2, D14). roaring64 has no copy-on-write,
 * so every change copies the whole bitmap (D16). As for 32 bits, no R API
 * is called while CRoaring runs, and every bitmap is attached to a shell
 * or freed before anything can signal; roaring64 iterators are heap
 * objects, so each is freed before any R call that could signal. */
#include "zro_bitmap.h"
#include "zro_portable.h"

#include <inttypes.h>
#include <math.h>
#include <stdio.h>
#include <string.h>

#include "zro_init.h"

#define ZRO_2_53 9007199254740992.0
#define ZRO_U64_TEXT_MAX 20 /* digits in 18446744073709551615 */

/* --- External pointers -------------------------------------------------- */

static void zro64_finalize(SEXP ptr) {
  roaring64_bitmap_t *r = (roaring64_bitmap_t *)R_ExternalPtrAddr(ptr);
  if (r != NULL) {
    roaring64_bitmap_free(r);
    R_ClearExternalPtr(ptr);
  }
}

static SEXP zro64_shell(void) {
  SEXP ptr = PROTECT(R_MakeExternalPtr(NULL, R_NilValue, R_NilValue));
  R_RegisterCFinalizerEx(ptr, zro64_finalize, TRUE);
  SEXP cls = PROTECT(Rf_mkString("zuroar64"));
  Rf_setAttrib(ptr, R_ClassSymbol, cls);
  UNPROTECT(2);
  return ptr;
}

static void zro64_attach(SEXP shell, roaring64_bitmap_t *r) {
  if (r == NULL) {
    zro_abort("zuroar_error_memory", "CRoaring could not allocate memory.");
  }
  R_SetExternalPtrAddr(shell, r);
}

static const roaring64_bitmap_t *zro64_get(SEXP x) {
  if (TYPEOF(x) != EXTPTRSXP || !Rf_inherits(x, "zuroar64")) {
    zro_abort("zuroar_error", "Expected a zuroar64 bitmap.");
  }
  const roaring64_bitmap_t *r = (const roaring64_bitmap_t *)R_ExternalPtrAddr(x);
  if (r == NULL) {
    zro_abort("zuroar_error_pointer",
              "This zuroar64 bitmap's pointer is null. A 64-bit bitmap does "
              "not survive saveRDS(), readRDS() or a trip to a worker process "
              "without roar_serial_config(); save it with roar_serialize() "
              "and read it back with roar64_unserialize().");
  }
  return r;
}

/* Whether `x` is a zuroar64 whose pointer is null. Never signals, so
 * format() and print() can describe a dead bitmap instead of failing. */
SEXP zro64_is_null(SEXP x) {
  return Rf_ScalarLogical(TYPEOF(x) == EXTPTRSXP &&
                          R_ExternalPtrAddr(x) == NULL);
}

/* --- Values ------------------------------------------------------------- */

#define ZRO64_DOMAIN \
  "must be whole numbers from 0 to 18446744073709551615, as canonical "  \
  "decimal text or as doubles below 2^53"

/* Parses canonical decimal text: digits only, no sign, no leading zero
 * except "0" itself, at most 2^64 - 1. */
static bool zro64_parse(const char *s, uint64_t *out) {
  size_t n = strlen(s);
  if (n == 0 || n > ZRO_U64_TEXT_MAX) return false;
  if (n > 1 && s[0] == '0') return false;
  uint64_t v = 0;
  for (size_t i = 0; i < n; i++) {
    if (s[i] < '0' || s[i] > '9') return false;
    uint64_t d = (uint64_t)(s[i] - '0');
    if (v > (UINT64_MAX - d) / 10) return false;
    v = v * 10 + d;
  }
  *out = v;
  return true;
}

static void zro64_values(SEXP v, uint64_t *out) {
  R_xlen_t n = XLENGTH(v);
  if (TYPEOF(v) == STRSXP) {
    for (R_xlen_t i = 0; i < n; i++) {
      SEXP el = STRING_ELT(v, i);
      if (el == NA_STRING) {
        zro_abort("zuroar_error_value",
                  "Element %.0f is NA; values " ZRO64_DOMAIN ".", (double)(i + 1));
      }
      if (!zro64_parse(CHAR(el), &out[i])) {
        zro_abort("zuroar_error_value",
                  "Element %.0f is \"%.40s\"; values " ZRO64_DOMAIN ".",
                  (double)(i + 1), CHAR(el));
      }
    }
  } else if (TYPEOF(v) == REALSXP) {
    const double *p = REAL(v);
    for (R_xlen_t i = 0; i < n; i++) {
      double d = p[i];
      if (ISNAN(d)) {
        zro_abort("zuroar_error_value",
                  "Element %.0f is NA; values " ZRO64_DOMAIN ".", (double)(i + 1));
      }
      if (!(d >= 0 && d < ZRO_2_53 && d == floor(d))) {
        zro_abort("zuroar_error_value",
                  "Element %.0f is %.17g; values " ZRO64_DOMAIN ".",
                  (double)(i + 1), d);
      }
      out[i] = (uint64_t)d;
    }
  } else if (TYPEOF(v) == INTSXP) {
    const int *p = INTEGER(v);
    for (R_xlen_t i = 0; i < n; i++) {
      if (p[i] == NA_INTEGER || p[i] < 0) {
        zro_abort("zuroar_error_value",
                  "Element %.0f is NA or negative; values " ZRO64_DOMAIN ".",
                  (double)(i + 1));
      }
      out[i] = (uint64_t)p[i];
    }
  } else {
    zro_abort("zuroar_error_value", "Values " ZRO64_DOMAIN ".");
  }
}

static uint64_t *zro64_buffer(R_xlen_t n) {
  return (uint64_t *)R_alloc(n > 0 ? (size_t)n : 1, sizeof(uint64_t));
}

static SEXP zro64_text(uint64_t v) {
  char buf[ZRO_U64_TEXT_MAX + 1];
  snprintf(buf, sizeof buf, "%" PRIu64, v);
  return Rf_mkChar(buf);
}

/* A count as a double, or a zuroar_error_value above 2^53 (D14). */
static SEXP zro64_count(uint64_t n, bool full) {
  if (full || (double)n > ZRO_2_53) {
    zro_abort("zuroar_error_value",
              "The count is above 2^53, where a double is no longer exact; "
              "use roar64_length() for the exact count as text.");
  }
  return Rf_ScalarReal((double)n);
}

/* roaring64's cardinality is a uint64_t, so a bitmap holding all 2^64
 * values reports 0; a zero cardinality on a non-empty bitmap is 2^64. */
static bool zro64_full(const roaring64_bitmap_t *r, uint64_t card) {
  return card == 0 && !roaring64_bitmap_is_empty(r);
}

/* --- Building ----------------------------------------------------------- */

SEXP zro64_from_values(SEXP v, SEXP optimize) {
  R_xlen_t n = XLENGTH(v);
  uint64_t *buf = zro64_buffer(n);
  zro64_values(v, buf);
  SEXP out = PROTECT(zro64_shell());
  roaring64_bitmap_t *r = roaring64_bitmap_of_ptr((size_t)n, buf);
  if (r != NULL && Rf_asLogical(optimize) == TRUE) {
    roaring64_bitmap_run_optimize(r);
    roaring64_bitmap_shrink_to_fit(r);
  }
  zro64_attach(out, r);
  UNPROTECT(1);
  return out;
}

static void zro64_ends(SEXP range, uint64_t e[2]) {
  if (XLENGTH(range) != 2) zro_abort("zuroar_error", "Expected two range ends.");
  zro64_values(range, e);
  if (e[0] > e[1]) {
    zro_abort("zuroar_error_value", "`from` must not be larger than `to`.");
  }
}

/* roaring64 keeps one container per 2^16 values, so a range of 2^64 values
 * would need 2^48 of them; the process would be killed for memory, not
 * signal. Ranges that add more than 2^40 values (2^24 containers) are
 * refused up front (design §6.1, amended 2026-11-06). */
#define ZRO64_MAX_RANGE_ADD ((uint64_t)1 << 40)

static void zro64_check_span(const uint64_t e[2]) {
  if (e[1] - e[0] >= ZRO64_MAX_RANGE_ADD) {
    zro_abort("zuroar_error_memory",
              "A range of more than 2^40 values would need more than 2^24 "
              "CRoaring containers; build it in parts, or keep the range "
              "as its two ends.");
  }
}

SEXP zro64_from_range(SEXP range) {
  uint64_t e[2];
  zro64_ends(range, e);
  zro64_check_span(e);
  SEXP out = PROTECT(zro64_shell());
  roaring64_bitmap_t *r = roaring64_bitmap_create();
  if (r != NULL) {
    roaring64_bitmap_add_range_closed(r, e[0], e[1]);
    roaring64_bitmap_run_optimize(r);
  }
  zro64_attach(out, r);
  UNPROTECT(1);
  return out;
}

/* Promotes a 32-bit bitmap; the 32-bit argument is copied first, because
 * roaring64_bitmap_move_from_roaring32() empties what it moves from. */
SEXP zro64_promote(SEXP x) {
  const roaring_bitmap_t *src = zro_get(x);
  SEXP out = PROTECT(zro64_shell());
  roaring_bitmap_t *copy = roaring_bitmap_copy(src);
  roaring64_bitmap_t *r = NULL;
  if (copy != NULL) {
    r = roaring64_bitmap_move_from_roaring32(copy);
    roaring_bitmap_free(copy);
  }
  zro64_attach(out, r);
  UNPROTECT(1);
  return out;
}

/* --- Changing a copy ---------------------------------------------------- */

static SEXP zro64_change(SEXP x, SEXP v, bool add) {
  const roaring64_bitmap_t *src = zro64_get(x);
  R_xlen_t n = XLENGTH(v);
  uint64_t *buf = zro64_buffer(n);
  zro64_values(v, buf);
  SEXP out = PROTECT(zro64_shell());
  roaring64_bitmap_t *r = roaring64_bitmap_copy(src);
  if (r != NULL) {
    if (add) {
      roaring64_bitmap_add_many(r, (size_t)n, buf);
    } else {
      roaring64_bitmap_remove_many(r, (size_t)n, buf);
    }
  }
  zro64_attach(out, r);
  UNPROTECT(1);
  return out;
}

SEXP zro64_add(SEXP x, SEXP v) { return zro64_change(x, v, true); }
SEXP zro64_remove(SEXP x, SEXP v) { return zro64_change(x, v, false); }

SEXP zro64_change_range(SEXP x, SEXP range, SEXP add_) {
  const roaring64_bitmap_t *src = zro64_get(x);
  uint64_t e[2];
  zro64_ends(range, e);
  bool add = Rf_asLogical(add_) == TRUE;
  if (add) zro64_check_span(e);
  SEXP out = PROTECT(zro64_shell());
  roaring64_bitmap_t *r = roaring64_bitmap_copy(src);
  if (r != NULL) {
    if (add) {
      roaring64_bitmap_add_range_closed(r, e[0], e[1]);
    } else {
      roaring64_bitmap_remove_range_closed(r, e[0], e[1]);
    }
  }
  zro64_attach(out, r);
  UNPROTECT(1);
  return out;
}

/* --- Queries ------------------------------------------------------------ */

SEXP zro64_contains(SEXP x, SEXP v) {
  const roaring64_bitmap_t *r = zro64_get(x);
  R_xlen_t n = XLENGTH(v);
  uint64_t *buf = zro64_buffer(n);
  zro64_values(v, buf);
  SEXP out = PROTECT(Rf_allocVector(LGLSXP, n));
  for (R_xlen_t i = 0; i < n; i++) {
    LOGICAL(out)[i] = roaring64_bitmap_contains(r, buf[i]) ? TRUE : FALSE;
  }
  UNPROTECT(1);
  return out;
}

SEXP zro64_cardinality(SEXP x) {
  const roaring64_bitmap_t *r = zro64_get(x);
  uint64_t card = roaring64_bitmap_get_cardinality(r);
  return zro64_count(card, zro64_full(r, card));
}

SEXP zro64_length_text(SEXP x) {
  const roaring64_bitmap_t *r = zro64_get(x);
  uint64_t card = roaring64_bitmap_get_cardinality(r);
  if (zro64_full(r, card)) return Rf_mkString("18446744073709551616");
  SEXP out = PROTECT(Rf_allocVector(STRSXP, 1));
  SET_STRING_ELT(out, 0, zro64_text(card));
  UNPROTECT(1);
  return out;
}

SEXP zro64_is_empty(SEXP x) {
  return Rf_ScalarLogical(roaring64_bitmap_is_empty(zro64_get(x)) ? TRUE : FALSE);
}

static SEXP zro64_text1(uint64_t v) {
  SEXP out = PROTECT(Rf_allocVector(STRSXP, 1));
  SET_STRING_ELT(out, 0, zro64_text(v));
  UNPROTECT(1);
  return out;
}

/* Non-empty bitmaps only; the R side handles the empty one. */
SEXP zro64_min(SEXP x) { return zro64_text1(roaring64_bitmap_minimum(zro64_get(x))); }
SEXP zro64_max(SEXP x) { return zro64_text1(roaring64_bitmap_maximum(zro64_get(x))); }

/* --- Back to R ---------------------------------------------------------- */

#define ZRO64_CHUNK 4096

/* Every value as text, or as doubles when `as_double` (the R side has
 * checked that the maximum is below 2^53), or as integers. */
static SEXP zro64_out(const roaring64_bitmap_t *r, uint64_t from, uint64_t n,
                      int type) {
  SEXPTYPE t = type == 0 ? STRSXP : (type == 1 ? REALSXP : INTSXP);
  SEXP out = PROTECT(Rf_allocVector(t, (R_xlen_t)n));
  uint64_t chunk[ZRO64_CHUNK];
  uint64_t done = 0;
  while (done < n) {
    uint64_t want = n - done < ZRO64_CHUNK ? n - done : ZRO64_CHUNK;
    /* A fresh iterator per chunk, freed before any R allocation, so an R
     * error cannot leak it. */
    roaring64_iterator_t *it = roaring64_iterator_create(r);
    if (it == NULL) {
      zro_abort("zuroar_error_memory", "CRoaring could not allocate memory.");
    }
    uint64_t got = 0;
    if (roaring64_iterator_move_equalorlarger(it, from)) {
      if (done > 0) {
        /* `from` is the last value read, so step past it. */
        roaring64_iterator_advance(it);
      }
      got = roaring64_iterator_has_value(it) ? roaring64_iterator_read(it, chunk, want) : 0;
    }
    roaring64_iterator_free(it);
    if (got == 0) break;
    for (uint64_t i = 0; i < got; i++) {
      R_xlen_t k = (R_xlen_t)(done + i);
      if (t == STRSXP) {
        SET_STRING_ELT(out, k, zro64_text(chunk[i]));
      } else if (t == REALSXP) {
        REAL(out)[k] = (double)chunk[i];
      } else {
        INTEGER(out)[k] = (int)chunk[i];
      }
    }
    done += got;
    from = chunk[got - 1];
  }
  UNPROTECT(1);
  return out;
}

static uint64_t zro64_card_checked(const roaring64_bitmap_t *r) {
  uint64_t card = roaring64_bitmap_get_cardinality(r);
  if (zro64_full(r, card) || (double)card > 4503599627370496.0) {
    zro_abort("zuroar_error_value",
              "The bitmap holds too many values to return as a vector; use "
              "roar_values() for part of it.");
  }
  return card;
}

/* type: 0 text, 1 double, 2 integer. */
SEXP zro64_to_r(SEXP x, SEXP type_) {
  const roaring64_bitmap_t *r = zro64_get(x);
  int type = Rf_asInteger(type_);
  uint64_t n = zro64_card_checked(r);
  if (n > 0 && type == 1 && (double)roaring64_bitmap_maximum(r) >= ZRO_2_53) {
    zro_abort("zuroar_error_value",
              "The bitmap holds values at or above 2^53, which a double "
              "cannot hold exactly; use as.character().");
  }
  if (n > 0 && type == 2 && roaring64_bitmap_maximum(r) > (uint64_t)INT_MAX) {
    zro_abort("zuroar_error_value",
              "The bitmap holds values above .Machine$integer.max; use "
              "as.character().");
  }
  return zro64_out(r, 0, n, type);
}

/* At most `n` values at or above `from`; `type` as for zro64_to_r(). */
SEXP zro64_values_from(SEXP x, SEXP from_, SEXP n_, SEXP type_) {
  const roaring64_bitmap_t *r = zro64_get(x);
  uint64_t from;
  zro64_values(from_, &from);
  double nd = Rf_asReal(n_);
  int type = Rf_asInteger(type_);
  uint64_t avail = roaring64_bitmap_range_closed_cardinality(r, from, UINT64_MAX);
  if (avail == 0 && from == 0 && !roaring64_bitmap_is_empty(r)) avail = UINT64_MAX;
  uint64_t n = (nd < (double)avail) ? (uint64_t)nd : avail;
  if ((double)n > 4503599627370496.0) {
    zro_abort("zuroar_error_value", "Too many values to return as a vector.");
  }
  if (n > 0 && type != 0) {
    uint64_t last = 0;
    uint64_t rank = roaring64_bitmap_rank(r, from) -
                    (roaring64_bitmap_contains(r, from) ? 1 : 0);
    roaring64_bitmap_select(r, rank + n - 1, &last);
    if (type == 1 && (double)last >= ZRO_2_53) {
      zro_abort("zuroar_error_value",
                "A requested value is at or above 2^53; use type = \"character\".");
    }
    if (type == 2 && last > (uint64_t)INT_MAX) {
      zro_abort("zuroar_error_value",
                "A requested value is above .Machine$integer.max; use type = "
                "\"character\".");
    }
  }
  return zro64_out(r, from, n, type);
}

SEXP zro64_head_text(SEXP x, SEXP n_) {
  const roaring64_bitmap_t *r = zro64_get(x);
  double want = Rf_asReal(n_);
  uint64_t card = roaring64_bitmap_get_cardinality(r);
  if (zro64_full(r, card)) card = UINT64_MAX;
  uint64_t n = (want > 0) ? (uint64_t)want : 0;
  if (n > card) n = card;
  if (n > ZRO64_CHUNK) n = ZRO64_CHUNK;
  return zro64_out(r, 0, n, 0);
}

/* --- Algebra ------------------------------------------------------------ */

SEXP zro64_binop(SEXP x, SEXP y, SEXP op_) {
  const roaring64_bitmap_t *a = zro64_get(x), *b = zro64_get(y);
  int op = Rf_asInteger(op_);
  SEXP out = PROTECT(zro64_shell());
  roaring64_bitmap_t *r = NULL;
  switch (op) {
    case 1: r = roaring64_bitmap_or(a, b); break;
    case 2: r = roaring64_bitmap_and(a, b); break;
    case 3: r = roaring64_bitmap_xor(a, b); break;
    case 4: r = roaring64_bitmap_andnot(a, b); break;
    default: zro_abort("zuroar_error", "Unknown operation %d.", op);
  }
  zro64_attach(out, r);
  UNPROTECT(1);
  return out;
}

SEXP zro64_binop_cardinality(SEXP x, SEXP y, SEXP op_) {
  const roaring64_bitmap_t *a = zro64_get(x), *b = zro64_get(y);
  int op = Rf_asInteger(op_);
  uint64_t n = 0;
  switch (op) {
    case 1: n = roaring64_bitmap_or_cardinality(a, b); break;
    case 2: n = roaring64_bitmap_and_cardinality(a, b); break;
    case 3: n = roaring64_bitmap_xor_cardinality(a, b); break;
    case 4: n = roaring64_bitmap_andnot_cardinality(a, b); break;
    default: zro_abort("zuroar_error", "Unknown operation %d.", op);
  }
  return zro64_count(n, false);
}

SEXP zro64_compare(SEXP x, SEXP y, SEXP op_) {
  const roaring64_bitmap_t *a = zro64_get(x), *b = zro64_get(y);
  int op = Rf_asInteger(op_);
  bool res = false;
  switch (op) {
    case 1: res = roaring64_bitmap_equals(a, b); break;
    case 2: res = roaring64_bitmap_is_subset(a, b); break;
    case 3: res = roaring64_bitmap_is_strict_subset(a, b); break;
    case 4: res = roaring64_bitmap_intersect(a, b); break;
    default: zro_abort("zuroar_error", "Unknown comparison %d.", op);
  }
  return Rf_ScalarLogical(res ? TRUE : FALSE);
}

SEXP zro64_jaccard(SEXP x, SEXP y) {
  const roaring64_bitmap_t *a = zro64_get(x), *b = zro64_get(y);
  if (roaring64_bitmap_is_empty(a) && roaring64_bitmap_is_empty(b)) {
    return Rf_ScalarReal(R_NaN);
  }
  return Rf_ScalarReal(roaring64_bitmap_jaccard_index(a, b));
}

SEXP zro64_many(SEXP xs, SEXP op_) {
  int op = Rf_asInteger(op_);
  R_xlen_t n = XLENGTH(xs);
  const roaring64_bitmap_t **rs =
      (const roaring64_bitmap_t **)R_alloc(n > 0 ? (size_t)n : 1, sizeof *rs);
  for (R_xlen_t i = 0; i < n; i++) rs[i] = zro64_get(VECTOR_ELT(xs, i));
  if (op == 2 && n == 0) zro_abort("zuroar_error", "Nothing to intersect.");
  SEXP out = PROTECT(zro64_shell());
  roaring64_bitmap_t *r = (op == 2) ? roaring64_bitmap_copy(rs[0]) : roaring64_bitmap_create();
  for (R_xlen_t i = (op == 2) ? 1 : 0; r != NULL && i < n; i++) {
    if (op == 2) {
      roaring64_bitmap_and_inplace(r, rs[i]);
    } else {
      roaring64_bitmap_or_inplace(r, rs[i]);
    }
  }
  zro64_attach(out, r);
  UNPROTECT(1);
  return out;
}

SEXP zro64_flip(SEXP x, SEXP range) {
  const roaring64_bitmap_t *a = zro64_get(x);
  uint64_t e[2];
  zro64_ends(range, e);
  zro64_check_span(e);
  SEXP out = PROTECT(zro64_shell());
  zro64_attach(out, roaring64_bitmap_flip_closed(a, e[0], e[1]));
  UNPROTECT(1);
  return out;
}

/* Shifts by `by`, a whole double with |by| < 2^53 checked by the R side.
 * Out of the domain is an error unless `drop` (D12). */
SEXP zro64_shift(SEXP x, SEXP by_, SEXP drop_) {
  const roaring64_bitmap_t *a = zro64_get(x);
  double by = Rf_asReal(by_);
  bool drop = Rf_asLogical(drop_) == TRUE;
  bool positive = by >= 0;
  uint64_t off = (uint64_t)(positive ? by : -by);
  if (!drop && off > 0 && !roaring64_bitmap_is_empty(a)) {
    uint64_t lo = roaring64_bitmap_minimum(a), hi = roaring64_bitmap_maximum(a);
    if ((positive && hi > UINT64_MAX - off) || (!positive && lo < off)) {
      zro_abort("zuroar_error_value",
                "Shifting by %.0f moves values outside 0 to "
                "18446744073709551615. Use roar_shift(drop = TRUE) to drop "
                "them.",
                by);
    }
  }
  SEXP out = PROTECT(zro64_shell());
  zro64_attach(out, roaring64_bitmap_add_offset_signed(a, positive, off));
  UNPROTECT(1);
  return out;
}

/* --- Order -------------------------------------------------------------- */

SEXP zro64_rank(SEXP x, SEXP v) {
  const roaring64_bitmap_t *r = zro64_get(x);
  R_xlen_t n = XLENGTH(v);
  uint64_t *buf = zro64_buffer(n);
  zro64_values(v, buf);
  SEXP out = PROTECT(Rf_allocVector(REALSXP, n));
  for (R_xlen_t i = 0; i < n; i++) {
    uint64_t k = roaring64_bitmap_rank(r, buf[i]);
    if ((double)k > ZRO_2_53) {
      zro_abort("zuroar_error_value", "A rank is above 2^53, where a double is no longer exact.");
    }
    REAL(out)[i] = (double)k;
  }
  UNPROTECT(1);
  return out;
}

/* Positions counting from 1, checked by the R side to lie in 1..length(x)
 * and below 2^53. */
SEXP zro64_select(SEXP x, SEXP k) {
  const roaring64_bitmap_t *r = zro64_get(x);
  R_xlen_t n = XLENGTH(k);
  SEXP out = PROTECT(Rf_allocVector(STRSXP, n));
  for (R_xlen_t i = 0; i < n; i++) {
    uint64_t v = 0;
    if (roaring64_bitmap_select(r, (uint64_t)REAL(k)[i] - 1, &v)) {
      SET_STRING_ELT(out, i, zro64_text(v));
    } else {
      SET_STRING_ELT(out, i, NA_STRING);
    }
  }
  UNPROTECT(1);
  return out;
}

static SEXP zro64_neighbour(SEXP x, SEXP v, bool next) {
  const roaring64_bitmap_t *r = zro64_get(x);
  R_xlen_t n = XLENGTH(v);
  uint64_t *buf = zro64_buffer(n);
  zro64_values(v, buf);
  /* Results into C first, so that no R call runs between CRoaring
   * calls. */
  uint64_t *res = zro64_buffer(n);
  int *found = (int *)R_alloc(n > 0 ? (size_t)n : 1, sizeof(int));
  for (R_xlen_t i = 0; i < n; i++) {
    found[i] = 0;
    if (next) {
      roaring64_iterator_t *it = roaring64_iterator_create(r);
      if (it != NULL) {
        if (roaring64_iterator_move_equalorlarger(it, buf[i])) {
          res[i] = roaring64_iterator_value(it);
          found[i] = 1;
        }
        roaring64_iterator_free(it);
      } else {
        found[i] = -1;
      }
    } else {
      uint64_t rank = roaring64_bitmap_rank(r, buf[i]);
      if (rank > 0 && roaring64_bitmap_select(r, rank - 1, &res[i])) found[i] = 1;
    }
  }
  SEXP out = PROTECT(Rf_allocVector(STRSXP, n));
  for (R_xlen_t i = 0; i < n; i++) {
    if (found[i] < 0) {
      zro_abort("zuroar_error_memory", "CRoaring could not allocate memory.");
    }
    SET_STRING_ELT(out, i, found[i] ? zro64_text(res[i]) : NA_STRING);
  }
  UNPROTECT(1);
  return out;
}

SEXP zro64_next(SEXP x, SEXP v) { return zro64_neighbour(x, v, true); }
SEXP zro64_prev(SEXP x, SEXP v) { return zro64_neighbour(x, v, false); }

SEXP zro64_range_count(SEXP x, SEXP range) {
  const roaring64_bitmap_t *r = zro64_get(x);
  uint64_t e[2];
  zro64_ends(range, e);
  uint64_t n = roaring64_bitmap_range_closed_cardinality(r, e[0], e[1]);
  /* The whole domain wraps to 0 like the cardinality does. */
  bool full = n == 0 && e[0] == 0 && e[1] == UINT64_MAX && !roaring64_bitmap_is_empty(r);
  return zro64_count(n, full);
}

SEXP zro64_contains_range(SEXP x, SEXP range) {
  const roaring64_bitmap_t *r = zro64_get(x);
  uint64_t e[2];
  zro64_ends(range, e);
  return Rf_ScalarLogical(roaring64_bitmap_contains_range_closed(r, e[0], e[1]) ? TRUE : FALSE);
}

/* Runs of positions as for zro_subset(), all below 2^53. */
SEXP zro64_subset(SEXP x, SEXP starts, SEXP ends, SEXP keep_) {
  const roaring64_bitmap_t *src = zro64_get(x);
  R_xlen_t nruns = XLENGTH(starts);
  const double *s = REAL(starts), *e = REAL(ends);
  bool keep = Rf_asLogical(keep_) == TRUE;
  uint64_t *lo = zro64_buffer(nruns), *hi = zro64_buffer(nruns);
  bool ok = true;
  for (R_xlen_t i = 0; i < nruns && ok; i++) {
    ok = roaring64_bitmap_select(src, (uint64_t)s[i] - 1, &lo[i]) &&
         roaring64_bitmap_select(src, (uint64_t)e[i] - 1, &hi[i]);
  }
  if (!ok) zro_abort("zuroar_error_index", "A position is past the end of the bitmap.");
  SEXP out = PROTECT(zro64_shell());
  roaring64_bitmap_t *r = keep ? roaring64_bitmap_create() : roaring64_bitmap_copy(src);
  uint64_t chunk[ZRO64_CHUNK];
  for (R_xlen_t i = 0; r != NULL && i < nruns; i++) {
    if (keep) {
      /* Read the run's values: two neighbouring 64-bit values can be 2^64
       * apart, so a range between them must never be built. */
      roaring64_iterator_t *it = roaring64_iterator_create(src);
      if (it == NULL) {
        roaring64_bitmap_free(r);
        r = NULL;
        break;
      }
      roaring64_iterator_move_equalorlarger(it, lo[i]);
      uint64_t left = (uint64_t)(e[i] - s[i]) + 1;
      while (left > 0 && roaring64_iterator_has_value(it)) {
        uint64_t want = left < ZRO64_CHUNK ? left : ZRO64_CHUNK;
        uint64_t got = roaring64_iterator_read(it, chunk, want);
        if (got == 0) break;
        roaring64_bitmap_add_many(r, (size_t)got, chunk);
        left -= got;
      }
      roaring64_iterator_free(it);
    } else {
      /* Removing a range allocates nothing, whatever its span. */
      roaring64_bitmap_remove_range_closed(r, lo[i], hi[i]);
    }
  }
  if (r != NULL) roaring64_bitmap_run_optimize(r);
  zro64_attach(out, r);
  UNPROTECT(1);
  return out;
}

/* --- Storage and bytes -------------------------------------------------- */

SEXP zro64_optimize(SEXP x) {
  const roaring64_bitmap_t *src = zro64_get(x);
  SEXP out = PROTECT(zro64_shell());
  roaring64_bitmap_t *r = roaring64_bitmap_copy(src);
  if (r != NULL) {
    roaring64_bitmap_run_optimize(r);
    roaring64_bitmap_shrink_to_fit(r);
  }
  zro64_attach(out, r);
  UNPROTECT(1);
  return out;
}

SEXP zro64_size(SEXP x) {
  return Rf_ScalarReal((double)roaring64_bitmap_portable_size_in_bytes(zro64_get(x)));
}

SEXP zro64_stats(SEXP x) {
  const roaring64_bitmap_t *r = zro64_get(x);
  roaring64_statistics_t st;
  memset(&st, 0, sizeof st);
  roaring64_bitmap_statistics(r, &st);
  double cols[3][3] = {
      {(double)st.n_array_containers, (double)st.n_bitset_containers,
       (double)st.n_run_containers},
      {(double)st.n_values_array_containers, (double)st.n_values_bitset_containers,
       (double)st.n_values_run_containers},
      {(double)st.n_bytes_array_containers, (double)st.n_bytes_bitset_containers,
       (double)st.n_bytes_run_containers}};
  const char *names[] = {"containers", "values", "bytes"};
  const char *kinds[] = {"array", "bitset", "run"};
  SEXP out = PROTECT(Rf_allocVector(VECSXP, 3));
  for (int j = 0; j < 3; j++) {
    SEXP col = PROTECT(Rf_allocVector(REALSXP, 3));
    for (int i = 0; i < 3; i++) REAL(col)[i] = cols[j][i];
    SET_VECTOR_ELT(out, j, col);
    UNPROTECT(1);
  }
  SEXP nm = PROTECT(Rf_allocVector(STRSXP, 3));
  for (int j = 0; j < 3; j++) SET_STRING_ELT(nm, j, Rf_mkChar(names[j]));
  Rf_setAttrib(out, R_NamesSymbol, nm);
  SEXP kind = PROTECT(Rf_allocVector(STRSXP, 3));
  for (int i = 0; i < 3; i++) SET_STRING_ELT(kind, i, Rf_mkChar(kinds[i]));
  Rf_setAttrib(out, Rf_install("kind"), kind);
  UNPROTECT(3);
  return out;
}

SEXP zro64_serialize(SEXP x, SEXP optimize) {
  const roaring64_bitmap_t *src = zro64_get(x);
  const roaring64_bitmap_t *r = src;
  SEXP holder = PROTECT(zro64_shell());
  if (Rf_asLogical(optimize) == TRUE) {
    roaring64_bitmap_t *copy = roaring64_bitmap_copy(src);
    if (copy != NULL) roaring64_bitmap_run_optimize(copy);
    zro64_attach(holder, copy);
    r = copy;
  }
  size_t n = roaring64_bitmap_portable_size_in_bytes(r);
  SEXP out = PROTECT(Rf_allocVector(RAWSXP, (R_xlen_t)n));
  size_t written = roaring64_bitmap_portable_serialize(r, (char *)RAW(out));
  if (written != n) {
    zro_abort("zuroar_error", "CRoaring wrote %.0f bytes where %.0f were expected.",
              (double)written, (double)n);
  }
  UNPROTECT(2);
  return out;
}

SEXP zro64_unserialize(SEXP bytes, SEXP ignore_trailing) {
  if (TYPEOF(bytes) != RAWSXP) {
    zro_abort("zuroar_error_format", "Expected a raw vector of portable bytes.");
  }
  size_t len = (size_t)XLENGTH(bytes);
  bool ignore = Rf_asLogical(ignore_trailing) == TRUE;
  SEXP out = PROTECT(zro64_shell());
  size_t used = 0;
  const char *reason = NULL;
  roaring64_bitmap_t *r =
      zro_portable_read64((const char *)RAW(bytes), len, &used, &reason);
  if (r == NULL) {
    zro_abort("zuroar_error_format", "Cannot read the 64-bit bitmap: %s.", reason);
  }
  if (used < len && !ignore) {
    roaring64_bitmap_free(r);
    zro_abort("zuroar_error_format",
              "The bitmap ends after %.0f of %.0f bytes; pass trailing = "
              "\"ignore\" to read it anyway.",
              (double)used, (double)len);
  }
  zro64_attach(out, r);
  UNPROTECT(1);
  return out;
}
