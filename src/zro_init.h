#ifndef ZRO_INIT_H
#define ZRO_INIT_H

#define R_NO_REMAP
#include <Rinternals.h>

SEXP zro_info(void);
SEXP zro_selftest(SEXP x, SEXP y, SEXP optimize);

/* zro_bitmap.c */
SEXP zro_from_values(SEXP a0, SEXP a1);
SEXP zro_from_range(SEXP a0);
SEXP zro_add(SEXP a0, SEXP a1);
SEXP zro_remove(SEXP a0, SEXP a1);
SEXP zro_contains(SEXP a0, SEXP a1);
SEXP zro_cardinality(SEXP a0);
SEXP zro_min(SEXP a0);
SEXP zro_max(SEXP a0);
SEXP zro_to_double(SEXP a0);
SEXP zro_to_integer(SEXP a0);
SEXP zro_head_values(SEXP a0, SEXP a1);
SEXP zro_is_null(SEXP a0);

#endif /* ZRO_INIT_H */
