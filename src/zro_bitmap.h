#ifndef ZRO_BITMAP_H
#define ZRO_BITMAP_H

#include "zro_roaring.h"

#define R_NO_REMAP
#include <R.h>
#include <Rinternals.h>

/* Signals an R condition of class `cls` (which inherits from zuroar_error)
 * through the package's R-level zro_abort(). Never returns. Call it only
 * when no CRoaring state is held: free or attach every bitmap first. */
NORET void zro_abort(const char *cls, const char *fmt, ...);

/* A new, empty external pointer of class "zuroar" with its finaliser.
 * Allocate it before any bitmap, so that a failed R allocation cannot leak
 * one, then attach the bitmap with zro_attach(). */
SEXP zro_shell(void);
/* Attaches `r` to `shell`, or frees nothing and signals
 * zuroar_error_memory when `r` is NULL. Enables copy-on-write. */
void zro_attach(SEXP shell, roaring_bitmap_t *r);

/* The bitmap behind `x`. Signals zuroar_error_pointer when the pointer is
 * null (after readRDS() or a worker round trip) and zuroar_error when `x`
 * is not a zuroar bitmap at all. */
const roaring_bitmap_t *zro_get(SEXP x);

/* Copies the values in `v` (integer or double) into `out`, which holds
 * XLENGTH(v) slots. Signals zuroar_error_value naming the first element
 * that is NA, negative, fractional or above 2^32 - 1. No CRoaring state
 * may be held while it runs. */
void zro_values_u32(SEXP v, uint32_t *out);

#endif /* ZRO_BITMAP_H */
