#ifndef ZRO_INIT_H
#define ZRO_INIT_H

#define R_NO_REMAP
#include <Rinternals.h>

SEXP zro_info(void);
SEXP zro_selftest(SEXP x, SEXP y, SEXP optimize);

#endif /* ZRO_INIT_H */
