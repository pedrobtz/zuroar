/* Set algebra on 32-bit bitmaps (design §6.3). Every operation returns a
 * new bitmap or a value; none modifies its arguments (D4). */
#include "zro_bitmap.h"

#include "zro_init.h"

enum { ZRO_OR = 1, ZRO_AND = 2, ZRO_XOR = 3, ZRO_ANDNOT = 4 };
enum { ZRO_EQ = 1, ZRO_SUBSET = 2, ZRO_STRICT = 3, ZRO_INTERSECTS = 4 };

SEXP zro_binop(SEXP x, SEXP y, SEXP op_) {
  const roaring_bitmap_t *a = zro_get(x);
  const roaring_bitmap_t *b = zro_get(y);
  int op = Rf_asInteger(op_);
  SEXP out = PROTECT(zro_shell());
  roaring_bitmap_t *r = NULL;
  switch (op) {
    case ZRO_OR: r = roaring_bitmap_or(a, b); break;
    case ZRO_AND: r = roaring_bitmap_and(a, b); break;
    case ZRO_XOR: r = roaring_bitmap_xor(a, b); break;
    case ZRO_ANDNOT: r = roaring_bitmap_andnot(a, b); break;
    default: zro_abort("zuroar_error", "Unknown operation %d.", op);
  }
  zro_attach(out, r);
  UNPROTECT(1);
  return out;
}

SEXP zro_binop_cardinality(SEXP x, SEXP y, SEXP op_) {
  const roaring_bitmap_t *a = zro_get(x);
  const roaring_bitmap_t *b = zro_get(y);
  int op = Rf_asInteger(op_);
  uint64_t n = 0;
  switch (op) {
    case ZRO_OR: n = roaring_bitmap_or_cardinality(a, b); break;
    case ZRO_AND: n = roaring_bitmap_and_cardinality(a, b); break;
    case ZRO_XOR: n = roaring_bitmap_xor_cardinality(a, b); break;
    case ZRO_ANDNOT: n = roaring_bitmap_andnot_cardinality(a, b); break;
    default: zro_abort("zuroar_error", "Unknown operation %d.", op);
  }
  return Rf_ScalarReal((double)n);
}

SEXP zro_compare(SEXP x, SEXP y, SEXP op_) {
  const roaring_bitmap_t *a = zro_get(x);
  const roaring_bitmap_t *b = zro_get(y);
  int op = Rf_asInteger(op_);
  bool res = false;
  switch (op) {
    case ZRO_EQ: res = roaring_bitmap_equals(a, b); break;
    case ZRO_SUBSET: res = roaring_bitmap_is_subset(a, b); break;
    case ZRO_STRICT: res = roaring_bitmap_is_strict_subset(a, b); break;
    case ZRO_INTERSECTS: res = roaring_bitmap_intersect(a, b); break;
    default: zro_abort("zuroar_error", "Unknown comparison %d.", op);
  }
  return Rf_ScalarLogical(res ? TRUE : FALSE);
}

SEXP zro_jaccard(SEXP x, SEXP y) {
  const roaring_bitmap_t *a = zro_get(x);
  const roaring_bitmap_t *b = zro_get(y);
  /* Undefined for two empty sets; CRoaring would divide 0 by 0. */
  if (roaring_bitmap_is_empty(a) && roaring_bitmap_is_empty(b)) {
    return Rf_ScalarReal(R_NaN);
  }
  return Rf_ScalarReal(roaring_bitmap_jaccard_index(a, b));
}

/* `xs` is a list of bitmaps, already checked by the R side to hold at
 * least one for "and". */
SEXP zro_many(SEXP xs, SEXP op_) {
  int op = Rf_asInteger(op_);
  R_xlen_t n = XLENGTH(xs);
  const roaring_bitmap_t **rs =
      (const roaring_bitmap_t **)R_alloc(n > 0 ? (size_t)n : 1, sizeof *rs);
  for (R_xlen_t i = 0; i < n; i++) rs[i] = zro_get(VECTOR_ELT(xs, i));

  SEXP out = PROTECT(zro_shell());
  roaring_bitmap_t *r = NULL;
  if (op == ZRO_OR) {
    r = roaring_bitmap_or_many((size_t)n, rs);
  } else if (op == ZRO_AND) {
    if (n == 0) zro_abort("zuroar_error", "Nothing to intersect.");
    r = roaring_bitmap_copy(rs[0]);
    for (R_xlen_t i = 1; r != NULL && i < n; i++) {
      roaring_bitmap_and_inplace(r, rs[i]);
    }
  } else {
    zro_abort("zuroar_error", "Unknown operation %d.", op);
  }
  zro_attach(out, r);
  UNPROTECT(1);
  return out;
}

/* `range` holds the inclusive ends, checked by the R side. */
SEXP zro_flip(SEXP x, SEXP range) {
  const roaring_bitmap_t *a = zro_get(x);
  uint32_t ends[2];
  if (XLENGTH(range) != 2) zro_abort("zuroar_error", "Expected two range ends.");
  zro_values_u32(range, ends);
  SEXP out = PROTECT(zro_shell());
  roaring_bitmap_t *r =
      roaring_bitmap_flip(a, (uint64_t)ends[0], (uint64_t)ends[1] + 1);
  zro_attach(out, r);
  UNPROTECT(1);
  return out;
}

/* Shifts every value by `by`, a whole number the R side has checked to lie
 * within +-(2^32 - 1). Values that leave the domain are dropped, so the R
 * side decides first whether that is allowed (D12). */
SEXP zro_shift(SEXP x, SEXP by) {
  const roaring_bitmap_t *a = zro_get(x);
  int64_t offset = (int64_t)Rf_asReal(by);
  SEXP out = PROTECT(zro_shell());
  roaring_bitmap_t *r = roaring_bitmap_add_offset(a, offset);
  zro_attach(out, r);
  UNPROTECT(1);
  return out;
}
