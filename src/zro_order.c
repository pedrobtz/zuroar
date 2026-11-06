/* Ordered queries, ranges and positional access on 32-bit bitmaps (design
 * §6.2, §6.6). R conventions at the boundary (D6): ranges arrive inclusive
 * and become CRoaring's half-open [min, max); positions arrive counting
 * from 1 and become CRoaring's ranks counting from 0. */
#include "zro_bitmap.h"

#include "zro_init.h"

/* Inclusive range ends from the R side, checked there to be whole numbers
 * in the domain with from <= to. */
static void zro_range_ends(SEXP range, uint32_t ends[2]) {
  if (XLENGTH(range) != 2) zro_abort("zuroar_error", "Expected two range ends.");
  zro_values_u32(range, ends);
}

/* --- Rank, select, next, previous -------------------------------------- */

SEXP zro_rank(SEXP x, SEXP v) {
  const roaring_bitmap_t *r = zro_get(x);
  R_xlen_t n = XLENGTH(v);
  uint32_t *buf = (uint32_t *)R_alloc(n > 0 ? (size_t)n : 1, sizeof *buf);
  zro_values_u32(v, buf);
  SEXP out = PROTECT(Rf_allocVector(REALSXP, n));
  double *o = REAL(out);
  for (R_xlen_t i = 0; i < n; i++) o[i] = (double)roaring_bitmap_rank(r, buf[i]);
  UNPROTECT(1);
  return out;
}

/* `k` holds positions counting from 1, checked by the R side to lie in
 * 1..length(x). */
SEXP zro_select(SEXP x, SEXP k) {
  const roaring_bitmap_t *r = zro_get(x);
  R_xlen_t n = XLENGTH(k);
  const double *kk = REAL(k);
  SEXP out = PROTECT(Rf_allocVector(REALSXP, n));
  double *o = REAL(out);
  for (R_xlen_t i = 0; i < n; i++) {
    uint32_t value = 0;
    if (roaring_bitmap_select(r, (uint32_t)(kk[i] - 1), &value)) {
      o[i] = (double)value;
    } else {
      o[i] = NA_REAL; /* not reached: positions are checked */
    }
  }
  UNPROTECT(1);
  return out;
}

/* The smallest value at or above each of `v`, or NA. */
SEXP zro_next(SEXP x, SEXP v) {
  const roaring_bitmap_t *r = zro_get(x);
  R_xlen_t n = XLENGTH(v);
  uint32_t *buf = (uint32_t *)R_alloc(n > 0 ? (size_t)n : 1, sizeof *buf);
  zro_values_u32(v, buf);
  SEXP out = PROTECT(Rf_allocVector(REALSXP, n));
  double *o = REAL(out);
  roaring_uint32_iterator_t it;
  for (R_xlen_t i = 0; i < n; i++) {
    roaring_iterator_init(r, &it);
    if (roaring_uint32_iterator_move_equalorlarger(&it, buf[i])) {
      o[i] = (double)it.current_value;
    } else {
      o[i] = NA_REAL;
    }
  }
  UNPROTECT(1);
  return out;
}

/* The largest value at or below each of `v`, or NA. */
SEXP zro_prev(SEXP x, SEXP v) {
  const roaring_bitmap_t *r = zro_get(x);
  R_xlen_t n = XLENGTH(v);
  uint32_t *buf = (uint32_t *)R_alloc(n > 0 ? (size_t)n : 1, sizeof *buf);
  zro_values_u32(v, buf);
  SEXP out = PROTECT(Rf_allocVector(REALSXP, n));
  double *o = REAL(out);
  for (R_xlen_t i = 0; i < n; i++) {
    uint64_t rank = roaring_bitmap_rank(r, buf[i]);
    uint32_t value = 0;
    if (rank > 0 && roaring_bitmap_select(r, (uint32_t)(rank - 1), &value)) {
      o[i] = (double)value;
    } else {
      o[i] = NA_REAL;
    }
  }
  UNPROTECT(1);
  return out;
}

/* --- Ranges ------------------------------------------------------------- */

SEXP zro_range_count(SEXP x, SEXP range) {
  const roaring_bitmap_t *r = zro_get(x);
  uint32_t e[2];
  zro_range_ends(range, e);
  return Rf_ScalarReal((double)roaring_bitmap_range_cardinality(
      r, (uint64_t)e[0], (uint64_t)e[1] + 1));
}

SEXP zro_contains_range(SEXP x, SEXP range) {
  const roaring_bitmap_t *r = zro_get(x);
  uint32_t e[2];
  zro_range_ends(range, e);
  bool all = roaring_bitmap_contains_range(r, (uint64_t)e[0], (uint64_t)e[1] + 1);
  return Rf_ScalarLogical(all ? TRUE : FALSE);
}

SEXP zro_change_range(SEXP x, SEXP range, SEXP add_) {
  const roaring_bitmap_t *src = zro_get(x);
  uint32_t e[2];
  zro_range_ends(range, e);
  bool add = Rf_asLogical(add_) == TRUE;
  SEXP out = PROTECT(zro_shell());
  roaring_bitmap_t *r = roaring_bitmap_copy(src);
  if (r != NULL) {
    if (add) {
      roaring_bitmap_add_range_closed(r, e[0], e[1]);
    } else {
      roaring_bitmap_remove_range_closed(r, e[0], e[1]);
    }
  }
  zro_attach(out, r);
  UNPROTECT(1);
  return out;
}

/* At most `n` values at or above `from`, as doubles or, when `as_int` and
 * every value fits, integers. The R side checks `n` and the type. */
SEXP zro_values(SEXP x, SEXP from_, SEXP n_, SEXP as_int_) {
  const roaring_bitmap_t *r = zro_get(x);
  uint32_t from;
  zro_values_u32(from_, &from);
  double nd = Rf_asReal(n_);
  bool as_int = Rf_asLogical(as_int_) == TRUE;

  uint64_t avail = roaring_bitmap_range_cardinality(r, (uint64_t)from,
                                                    (uint64_t)UINT32_MAX + 1);
  uint64_t n = (nd < (double)avail) ? (uint64_t)nd : avail;
  if (as_int && n > 0) {
    roaring_uint32_iterator_t it;
    roaring_iterator_init(r, &it);
    roaring_uint32_iterator_move_equalorlarger(&it, from);
    if (n > 1) roaring_uint32_iterator_skip(&it, (uint32_t)(n - 1));
    if (it.has_value && it.current_value > (uint32_t)INT_MAX) {
      zro_abort("zuroar_error_value",
                "A requested value is %.0f, above .Machine$integer.max; use "
                "type = \"double\".",
                (double)it.current_value);
    }
  }

  SEXP out = PROTECT(Rf_allocVector(as_int ? INTSXP : REALSXP, (R_xlen_t)n));
  enum { CHUNK = 4096 };
  uint32_t chunk[CHUNK];
  roaring_uint32_iterator_t it;
  roaring_iterator_init(r, &it);
  roaring_uint32_iterator_move_equalorlarger(&it, from);
  uint64_t done = 0;
  while (done < n) {
    uint64_t want = n - done;
    uint32_t got = roaring_uint32_iterator_read(
        &it, chunk, want < CHUNK ? (uint32_t)want : CHUNK);
    if (got == 0) break;
    if (as_int) {
      int *o = INTEGER(out);
      for (uint32_t i = 0; i < got; i++) o[done + i] = (int)chunk[i];
    } else {
      double *o = REAL(out);
      for (uint32_t i = 0; i < got; i++) o[done + i] = (double)chunk[i];
    }
    done += got;
  }
  UNPROTECT(1);
  return out;
}

/* --- Positions ---------------------------------------------------------- */

/* Runs of positions longer than this select through a range intersection
 * (design §6.6); shorter ones read the values with an iterator. */
#define ZRO_LONG_RUN 64

/* The values at the runs of positions [starts[i], ends[i]] (counting from
 * 1, sorted, disjoint, within 1..length(x), checked by the R side): kept
 * when `keep`, otherwise removed from a copy of `x`. */
SEXP zro_subset(SEXP x, SEXP starts, SEXP ends, SEXP keep_) {
  const roaring_bitmap_t *src = zro_get(x);
  R_xlen_t nruns = XLENGTH(starts);
  const double *s = REAL(starts), *e = REAL(ends);
  bool keep = Rf_asLogical(keep_) == TRUE;

  /* The first and last value of each run, read from `x` before any
   * change, so that removing one run cannot shift another. */
  uint32_t *lo = (uint32_t *)R_alloc(nruns > 0 ? (size_t)nruns : 1, sizeof *lo);
  uint32_t *hi = (uint32_t *)R_alloc(nruns > 0 ? (size_t)nruns : 1, sizeof *hi);
  uint32_t chunk[ZRO_LONG_RUN];

  SEXP out = PROTECT(zro_shell());
  bool ok = true;
  for (R_xlen_t i = 0; i < nruns && ok; i++) {
    ok = roaring_bitmap_select(src, (uint32_t)(s[i] - 1), &lo[i]) &&
         roaring_bitmap_select(src, (uint32_t)(e[i] - 1), &hi[i]);
  }
  roaring_bitmap_t *r = NULL;
  if (ok) r = keep ? roaring_bitmap_create() : roaring_bitmap_copy(src);
  for (R_xlen_t i = 0; r != NULL && i < nruns; i++) {
    double len = e[i] - s[i] + 1;
    if (len > ZRO_LONG_RUN) {
      if (keep) {
        roaring_bitmap_t *part =
            roaring_bitmap_from_range((uint64_t)lo[i], (uint64_t)hi[i] + 1, 1);
        if (part == NULL) {
          roaring_bitmap_free(r);
          r = NULL;
          break;
        }
        roaring_bitmap_and_inplace(part, src);
        roaring_bitmap_or_inplace(r, part);
        roaring_bitmap_free(part);
      } else {
        roaring_bitmap_remove_range_closed(r, lo[i], hi[i]);
      }
    } else {
      roaring_uint32_iterator_t it;
      roaring_iterator_init(src, &it);
      roaring_uint32_iterator_move_equalorlarger(&it, lo[i]);
      uint32_t got = roaring_uint32_iterator_read(&it, chunk, (uint32_t)len);
      if (keep) {
        roaring_bitmap_add_many(r, got, chunk);
      } else {
        roaring_bitmap_remove_many(r, got, chunk);
      }
    }
  }
  if (r != NULL) {
    roaring_bitmap_run_optimize(r);
  }
  if (!ok) {
    zro_abort("zuroar_error_index", "A position is past the end of the bitmap.");
  }
  zro_attach(out, r);
  UNPROTECT(1);
  return out;
}

/* --- Storage ------------------------------------------------------------ */

SEXP zro_optimize(SEXP x) {
  const roaring_bitmap_t *src = zro_get(x);
  SEXP out = PROTECT(zro_shell());
  roaring_bitmap_t *r = roaring_bitmap_copy(src);
  if (r != NULL) {
    roaring_bitmap_run_optimize(r);
    roaring_bitmap_shrink_to_fit(r);
  }
  zro_attach(out, r);
  UNPROTECT(1);
  return out;
}

SEXP zro_size(SEXP x) {
  const roaring_bitmap_t *r = zro_get(x);
  return Rf_ScalarReal((double)roaring_bitmap_portable_size_in_bytes(r));
}

SEXP zro_stats(SEXP x) {
  const roaring_bitmap_t *r = zro_get(x);
  roaring_statistics_t st;
  memset(&st, 0, sizeof st);
  roaring_bitmap_statistics(r, &st);
  uint64_t card = roaring_bitmap_get_cardinality(r);

  /* CRoaring counts values per kind in 32 bits, so a full run container
   * set (2^32 values) wraps; the run count is recovered from the exact
   * 64-bit total. */
  double v_array = (double)st.n_values_array_containers;
  double v_bitset = (double)st.n_values_bitset_containers;
  double v_run = (double)card - v_array - v_bitset;

  const char *names[] = {"containers", "values", "bytes"};
  const char *kinds[] = {"array", "bitset", "run"};
  double containers[] = {st.n_array_containers, st.n_bitset_containers,
                         st.n_run_containers};
  double values[] = {v_array, v_bitset, v_run};
  double bytes[] = {st.n_bytes_array_containers, st.n_bytes_bitset_containers,
                    st.n_bytes_run_containers};
  double *cols[] = {containers, values, bytes};

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
