/* The zuroar representation (design §4, §14, D17): an ALTREP double vector
 * whose data1 is an external pointer to a zro_bitmap_t, which owns the
 * CRoaring bitmap and a read cursor. The vector's length is the
 * cardinality and its elements are the values in increasing order, read
 * through CRoaring; no method here expands the set. A data pointer is
 * refused, so base or third-party C that insists on one gets an error
 * (D11), and refusing Dataptr(writeable = TRUE) is what keeps a bitmap
 * immutable (D4). Serialisation writes the portable bytes on demand and
 * reads them back through the bounded path (D8), so saveRDS() and worker
 * processes need no hook.
 *
 * Invariant: once attached, a bitmap is never modified. Every binding
 * builds a new bitmap (D4), and a copy-on-write copy wraps the source's
 * containers in shared wrappers without moving them, so the cursor's
 * iterator stays valid for the bitmap's whole life. */
#include "zro_bitmap.h"

#include <R_ext/Altrep.h>

#include "zro_init.h"

#define ZRO_CHUNK 4096

typedef struct {
  roaring_bitmap_t *r;
  uint64_t card;                /* cached: the bitmap never changes */
  roaring_uint32_iterator_t it; /* cursor for sequential reads */
  uint64_t rank;                /* position, from 0, of the value `it` is at */
  bool cursor;                  /* whether `it` is positioned */
} zro_bitmap_t;

static R_altrep_class_t zro_class;

/* --- Lifetime ----------------------------------------------------------- */

static void zro_finalize(SEXP ptr) {
  zro_bitmap_t *b = (zro_bitmap_t *)R_ExternalPtrAddr(ptr);
  if (b != NULL) {
    if (b->r != NULL) roaring_bitmap_free(b->r);
    free(b);
    R_ClearExternalPtr(ptr);
  }
}

SEXP zro_shell(void) {
  SEXP ptr = PROTECT(R_MakeExternalPtr(NULL, R_NilValue, R_NilValue));
  R_RegisterCFinalizerEx(ptr, zro_finalize, TRUE);
  SEXP out = PROTECT(R_new_altrep(zro_class, ptr, R_NilValue));
  SEXP cls = PROTECT(Rf_mkString("zuroar"));
  Rf_setAttrib(out, R_ClassSymbol, cls);
  UNPROTECT(3);
  return out;
}

void zro_attach(SEXP shell, roaring_bitmap_t *r) {
  if (r == NULL) {
    zro_abort("zuroar_error_memory", "CRoaring could not allocate memory.");
  }
  zro_bitmap_t *b = (zro_bitmap_t *)malloc(sizeof *b);
  if (b == NULL) {
    roaring_bitmap_free(r);
    zro_abort("zuroar_error_memory", "Could not allocate memory for a bitmap.");
  }
  roaring_bitmap_set_copy_on_write(r, true);
  b->r = r;
  b->card = roaring_bitmap_get_cardinality(r);
  b->rank = 0;
  b->cursor = false;
  R_SetExternalPtrAddr(R_altrep_data1(shell), b);
}

/* The cell behind one of this class's own objects; NULL only for a shell
 * that was never attached, which no R code can see. */
static zro_bitmap_t *zro_cell(SEXP x) {
  return (zro_bitmap_t *)R_ExternalPtrAddr(R_altrep_data1(x));
}

const roaring_bitmap_t *zro_get(SEXP x) {
  /* R can hand a bitmap over inside one of its own wrapper ALTREP objects,
   * whose data1 is the wrapped vector; a chain of them ends at a non-ALTREP
   * value, so the walk terminates. */
  SEXP v = x;
  while (ALTREP(v) && !R_altrep_inherits(v, zro_class)) v = R_altrep_data1(v);
  if (!ALTREP(v)) {
    zro_abort("zuroar_error", "Expected a bitmap built by zuroar.");
  }
  zro_bitmap_t *b = zro_cell(v);
  if (b == NULL || b->r == NULL) {
    zro_abort("zuroar_error", "This bitmap holds no data.");
  }
  return b->r;
}

/* --- Reading ------------------------------------------------------------ */

static R_xlen_t zro_alt_length(SEXP x) {
  zro_bitmap_t *b = zro_cell(x);
  return b == NULL ? 0 : (R_xlen_t)b->card;
}

/* Values at positions i, i + 1, ... into `buf`, at most `n` of them. A
 * sequential caller (sum(), print(), match()'s hashing) continues from the
 * cursor; any other position re-seeks by rank, which costs one pass over
 * the container index. */
static R_xlen_t zro_alt_get_region(SEXP x, R_xlen_t i, R_xlen_t n,
                                   double *buf) {
  zro_bitmap_t *b = zro_cell(x);
  if (b == NULL || n <= 0 || i < 0 || (uint64_t)i >= b->card) return 0;
  if (!b->cursor || b->rank != (uint64_t)i) {
    uint32_t v;
    if (!roaring_bitmap_select(b->r, (uint32_t)i, &v)) return 0;
    roaring_iterator_init(b->r, &b->it);
    roaring_uint32_iterator_move_equalorlarger(&b->it, v);
    b->rank = (uint64_t)i;
    b->cursor = true;
  }
  uint32_t chunk[ZRO_CHUNK];
  R_xlen_t done = 0;
  while (done < n) {
    R_xlen_t left = n - done;
    uint32_t want = left > ZRO_CHUNK ? ZRO_CHUNK : (uint32_t)left;
    uint32_t got = roaring_uint32_iterator_read(&b->it, chunk, want);
    if (got == 0) break;
    for (uint32_t k = 0; k < got; k++) buf[done + k] = (double)chunk[k];
    done += got;
  }
  b->rank += (uint64_t)done;
  return done;
}

static double zro_alt_elt(SEXP x, R_xlen_t i) {
  double v;
  return zro_alt_get_region(x, i, 1, &v) == 1 ? v : NA_REAL;
}

/* sum(x): each run of consecutive values is an arithmetic series, so a
 * run-heavy bitmap costs one step per run. The total of any 32-bit set is
 * below 2^64, so it is exact in uint64_t and rounded once to a double. */
static SEXP zro_alt_sum(SEXP x, Rboolean narm) {
  (void)narm; /* a bitmap holds no NA */
  const roaring_bitmap_t *r = zro_get(x);
  roaring_uint32_range_closed_t ranges[ZRO_CHUNK];
  roaring_uint32_iterator_t it;
  roaring_iterator_init(r, &it);
  uint64_t total = 0;
  while (it.has_value) {
    size_t got = roaring_uint32_iterator_read_ranges(&it, ranges, ZRO_CHUNK);
    if (got == 0) break;
    for (size_t k = 0; k < got; k++) {
      uint64_t n = (uint64_t)ranges[k].max - ranges[k].min + 1;
      uint64_t ends = (uint64_t)ranges[k].min + ranges[k].max;
      /* n * ends is even: an odd n means min and max share a parity. */
      total += (n % 2 == 0) ? (n / 2) * ends : n * (ends / 2);
    }
  }
  return Rf_ScalarReal((double)total);
}

static void *zro_alt_dataptr(SEXP x, Rboolean writeable) {
  (void)x;
  (void)writeable;
  zro_abort("zuroar_error_unsupported",
            "This operation needs the bitmap as a plain vector, which "
            "zuroar never builds on its own. Use as.double(x) to expand "
            "it, or a bounded query such as head(x) or roar_contains().");
  return NULL; /* not reached */
}

static const void *zro_alt_dataptr_or_null(SEXP x) {
  (void)x;
  return NULL;
}

static int zro_alt_is_sorted(SEXP x) {
  (void)x;
  return SORTED_INCR;
}

static int zro_alt_no_na(SEXP x) {
  (void)x;
  return 1;
}

/* --- Copying and subsetting --------------------------------------------- */

/* R's default DuplicateEX copies the attributes onto the result. */
static SEXP zro_alt_duplicate(SEXP x, Rboolean deep) {
  (void)deep;
  const roaring_bitmap_t *r = zro_get(x);
  SEXP out = PROTECT(zro_shell());
  zro_attach(out, roaring_bitmap_copy(r));
  UNPROTECT(1);
  return out;
}

/* x[i] for the positions `indx`, which R has already made positive and
 * 1-based (negative and logical subscripts are resolved before this is
 * called). A contiguous run of positions is one intersection with a
 * range; any other index selects each position (design §6.6). */
static SEXP zro_alt_extract_subset(SEXP x, SEXP indx, SEXP call) {
  (void)call;
  const roaring_bitmap_t *r = zro_get(x);
  uint64_t card = roaring_bitmap_get_cardinality(r);
  R_xlen_t n = XLENGTH(indx);
  uint32_t *pos = (uint32_t *)R_alloc(n > 0 ? (size_t)n : 1, sizeof(uint32_t));
  bool contiguous = true;
  for (R_xlen_t k = 0; k < n; k++) {
    double p;
    if (TYPEOF(indx) == INTSXP) {
      int ip = INTEGER_ELT(indx, k);
      p = ip == NA_INTEGER ? NA_REAL : (double)ip;
    } else if (TYPEOF(indx) == REALSXP) {
      p = REAL_ELT(indx, k);
    } else {
      zro_abort("zuroar_error_index", "Positions must be whole numbers.");
    }
    if (ISNAN(p)) {
      zro_abort("zuroar_error_index",
                "Position %.0f is NA; a bitmap holds no NA.", (double)(k + 1));
    }
    if (!(p >= 1 && p <= (double)card)) {
      zro_abort("zuroar_error_index",
                "Position %.0f is outside 1 to %.0f, the positions of this "
                "bitmap.",
                p, (double)card);
    }
    pos[k] = (uint32_t)(p - 1);
    if (k > 0 && pos[k] != pos[k - 1] + 1) contiguous = false;
  }

  SEXP out = PROTECT(zro_shell());
  roaring_bitmap_t *res = NULL;
  if (n == 0) {
    res = roaring_bitmap_create();
  } else if (contiguous) {
    uint32_t lo, hi;
    roaring_bitmap_select(r, pos[0], &lo);
    roaring_bitmap_select(r, pos[n - 1], &hi);
    roaring_bitmap_t *range = roaring_bitmap_from_range(lo, (uint64_t)hi + 1, 1);
    if (range != NULL) {
      res = roaring_bitmap_and(r, range);
      roaring_bitmap_free(range);
    }
  } else {
    for (R_xlen_t k = 0; k < n; k++) roaring_bitmap_select(r, pos[k], &pos[k]);
    res = roaring_bitmap_of_ptr((size_t)n, pos);
    if (res != NULL) roaring_bitmap_run_optimize(res);
  }
  zro_attach(out, res);
  UNPROTECT(1);
  return out;
}

/* --- Serialisation ------------------------------------------------------ */

static SEXP zro_alt_serialized_state(SEXP x) {
  const roaring_bitmap_t *r = zro_get(x);
  size_t n = roaring_bitmap_portable_size_in_bytes(r);
  SEXP bytes = PROTECT(Rf_allocVector(RAWSXP, (R_xlen_t)n));
  roaring_bitmap_portable_serialize(r, (char *)RAW(bytes));
  UNPROTECT(1);
  return bytes;
}

/* R restores the attributes it saved after this returns. */
static SEXP zro_alt_unserialize(SEXP class, SEXP state) {
  (void)class;
  if (TYPEOF(state) != RAWSXP) {
    zro_abort("zuroar_error_format",
              "The saved bitmap's state is not a raw vector.");
  }
  SEXP out = PROTECT(zro_shell());
  size_t len = (size_t)XLENGTH(state);
  size_t used = 0;
  const char *reason = NULL;
  roaring_bitmap_t *r = zro_portable_read(RAW(state), len, &used, &reason);
  if (r == NULL) {
    zro_abort("zuroar_error_format",
              "The saved bytes are not a valid portable Roaring bitmap: %s.",
              reason);
  }
  if (used != len) {
    roaring_bitmap_free(r);
    zro_abort("zuroar_error_format",
              "The saved bytes hold %.0f bytes after the bitmap's %.0f.",
              (double)(len - used), (double)used);
  }
  zro_attach(out, r);
  UNPROTECT(1);
  return out;
}

static Rboolean zro_alt_inspect(SEXP x, int pre, int deep, int pvec,
                                void (*inspect_subtree)(SEXP, int, int, int)) {
  (void)pre;
  (void)deep;
  (void)pvec;
  (void)inspect_subtree;
  zro_bitmap_t *b = zro_cell(x);
  if (b == NULL || b->r == NULL) {
    Rprintf("zuroar bitmap (not attached)\n");
    return TRUE;
  }
  roaring_statistics_t st;
  roaring_bitmap_statistics(b->r, &st);
  Rprintf("zuroar bitmap: %.0f values in %u containers (%u array, %u bitset, "
          "%u run)\n",
          (double)b->card, (unsigned)st.n_containers,
          (unsigned)st.n_array_containers, (unsigned)st.n_bitset_containers,
          (unsigned)st.n_run_containers);
  return TRUE;
}

/* --- Test hooks --------------------------------------------------------- */

/* Asks R for the data pointer, as base or third-party C would. */
SEXP zro_test_dataptr(SEXP x) {
  const double *p = REAL(x);
  return Rf_ScalarReal(p == NULL ? NA_REAL : p[0]);
}

SEXP zro_test_state(SEXP x) { return zro_alt_serialized_state(x); }

SEXP zro_test_unserialize(SEXP state) {
  return zro_alt_unserialize(R_NilValue, state);
}

/* --- Registration ------------------------------------------------------- */

void zro_init_altrep(DllInfo *dll) {
  zro_class = R_make_altreal_class("zuroar", "zuroar", dll);
  R_set_altrep_Length_method(zro_class, zro_alt_length);
  R_set_altrep_Inspect_method(zro_class, zro_alt_inspect);
  R_set_altrep_Duplicate_method(zro_class, zro_alt_duplicate);
  R_set_altrep_Serialized_state_method(zro_class, zro_alt_serialized_state);
  R_set_altrep_Unserialize_method(zro_class, zro_alt_unserialize);
  R_set_altvec_Dataptr_method(zro_class, zro_alt_dataptr);
  R_set_altvec_Dataptr_or_null_method(zro_class, zro_alt_dataptr_or_null);
  R_set_altvec_Extract_subset_method(zro_class, zro_alt_extract_subset);
  R_set_altreal_Elt_method(zro_class, zro_alt_elt);
  R_set_altreal_Get_region_method(zro_class, zro_alt_get_region);
  R_set_altreal_Sum_method(zro_class, zro_alt_sum);
  R_set_altreal_Is_sorted_method(zro_class, zro_alt_is_sorted);
  R_set_altreal_No_NA_method(zro_class, zro_alt_no_na);
}
