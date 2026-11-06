/* An unexported self-test of the vendored build: runs CRoaring's pairwise
 * operations on two sets so the tests can compare every compiled SIMD path
 * with a base R oracle (design §7.4). Not part of the API; Stage 2 brings
 * the real bindings. */
#include "zro_roaring.h"

#define R_NO_REMAP
#include <R.h>
#include <Rinternals.h>

#include "zro_init.h"

static roaring_bitmap_t *zro_selftest_bitmap(const int *v, R_xlen_t n,
                                             bool optimize) {
  roaring_bitmap_t *r = roaring_bitmap_create();
  if (r == NULL) return NULL;
  for (R_xlen_t i = 0; i < n; i++) roaring_bitmap_add(r, (uint32_t)v[i]);
  if (optimize) roaring_bitmap_run_optimize(r);
  return r;
}

static SEXP zro_selftest_values(const roaring_bitmap_t *r) {
  uint64_t n = roaring_bitmap_get_cardinality(r);
  SEXP out = PROTECT(Rf_allocVector(INTSXP, (R_xlen_t)n));
  roaring_bitmap_to_uint32_array(r, (uint32_t *)INTEGER(out));
  UNPROTECT(1);
  return out;
}

SEXP zro_selftest(SEXP x, SEXP y, SEXP optimize) {
  if (TYPEOF(x) != INTSXP || TYPEOF(y) != INTSXP) {
    Rf_error("`x` and `y` must be integer vectors");
  }
  const int *xv = INTEGER(x), *yv = INTEGER(y);
  R_xlen_t nx = XLENGTH(x), ny = XLENGTH(y);
  for (R_xlen_t i = 0; i < nx; i++) {
    if (xv[i] < 0) Rf_error("`x` must be non-negative and not NA");
  }
  for (R_xlen_t i = 0; i < ny; i++) {
    if (yv[i] < 0) Rf_error("`y` must be non-negative and not NA");
  }
  bool opt = Rf_asLogical(optimize) == TRUE;

  /* CRoaring only, from here until every bitmap is freed. */
  roaring_bitmap_t *a = zro_selftest_bitmap(xv, nx, opt);
  roaring_bitmap_t *b = zro_selftest_bitmap(yv, ny, opt);
  roaring_bitmap_t *u = NULL, *n = NULL, *s = NULL, *d = NULL;
  if (a != NULL && b != NULL) {
    u = roaring_bitmap_or(a, b);
    n = roaring_bitmap_and(a, b);
    s = roaring_bitmap_xor(a, b);
    d = roaring_bitmap_andnot(a, b);
  }
  bool ok = u != NULL && n != NULL && s != NULL && d != NULL;
  double card[4] = {0, 0, 0, 0};
  bool valid = false;
  if (ok) {
    card[0] = (double)roaring_bitmap_or_cardinality(a, b);
    card[1] = (double)roaring_bitmap_and_cardinality(a, b);
    card[2] = (double)roaring_bitmap_xor_cardinality(a, b);
    card[3] = (double)roaring_bitmap_andnot_cardinality(a, b);
    const char *reason = NULL;
    valid = roaring_bitmap_internal_validate(u, &reason) &&
            roaring_bitmap_internal_validate(n, &reason) &&
            roaring_bitmap_internal_validate(s, &reason) &&
            roaring_bitmap_internal_validate(d, &reason);
  }
  roaring_bitmap_free(a);
  roaring_bitmap_free(b);
  if (!ok) {
    roaring_bitmap_free(u);
    roaring_bitmap_free(n);
    roaring_bitmap_free(s);
    roaring_bitmap_free(d);
    Rf_error("CRoaring could not allocate memory");
  }

  /* R objects. An allocation error here would leak u, n, s, d; this is a
   * test helper, and Stage 2's bindings own their bitmaps through
   * finalisers instead. */
  roaring_bitmap_t *res[4] = {u, n, s, d};
  SEXP out = PROTECT(Rf_allocVector(VECSXP, 6));
  for (int i = 0; i < 4; i++) {
    SET_VECTOR_ELT(out, i, zro_selftest_values(res[i]));
    roaring_bitmap_free(res[i]);
    res[i] = NULL;
  }
  SEXP cards = PROTECT(Rf_allocVector(REALSXP, 4));
  for (int i = 0; i < 4; i++) REAL(cards)[i] = card[i];
  SET_VECTOR_ELT(out, 4, cards);
  SET_VECTOR_ELT(out, 5, Rf_ScalarLogical(valid));

  SEXP names = PROTECT(Rf_allocVector(STRSXP, 6));
  const char *nm[6] = {"or", "and", "xor", "andnot", "cardinality", "valid"};
  for (int i = 0; i < 6; i++) SET_STRING_ELT(names, i, Rf_mkChar(nm[i]));
  Rf_setAttrib(out, R_NamesSymbol, names);
  UNPROTECT(3);
  return out;
}
