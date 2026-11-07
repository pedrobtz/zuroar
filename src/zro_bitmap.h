#ifndef ZRO_BITMAP_H
#define ZRO_BITMAP_H

#include "zro_roaring.h"

#define R_NO_REMAP
#include <R.h>
#include <Rinternals.h>
#include <R_ext/Rdynload.h>

/* Signals an R condition of class `cls` (which inherits from zuroar_error)
 * through the package's R-level zro_abort(). Never returns. Call it only
 * when no CRoaring state is held: free or attach every bitmap first. */
NORET void zro_abort(const char *cls, const char *fmt, ...);

/* A new zuroar object (an ALTREP vector, design §4) holding no bitmap yet.
 * Allocate it before any bitmap, so that a failed R allocation cannot leak
 * one, then attach the bitmap with zro_attach(). */
SEXP zro_shell(void);
/* Attaches `r` to `shell`, or frees nothing and signals
 * zuroar_error_memory when `r` is NULL. Enables copy-on-write. After this,
 * `r` is never modified again. */
void zro_attach(SEXP shell, roaring_bitmap_t *r);

/* The bitmap behind `x`. Signals zuroar_error when `x` is not a zuroar
 * bitmap. */
const roaring_bitmap_t *zro_get(SEXP x);

/* Registers the ALTREP class; called once from R_init_zuroar(). */
void zro_init_altrep(DllInfo *dll);

/* Copies the values in `v` (integer or double) into `out`, which holds
 * XLENGTH(v) slots. Signals zuroar_error_value naming the first element
 * that is NA, negative, fractional or above 2^32 - 1. No CRoaring state
 * may be held while it runs. */
void zro_values_u32(SEXP v, uint32_t *out);

#endif /* ZRO_BITMAP_H */
