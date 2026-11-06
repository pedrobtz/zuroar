#define R_NO_REMAP
#include <R.h>
#include <Rinternals.h>
#include <R_ext/Rdynload.h>

#include "zro_init.h"

static const R_CallMethodDef zro_call_methods[] = {
    {"zro_info", (DL_FUNC)&zro_info, 0},
    {"zro_selftest", (DL_FUNC)&zro_selftest, 3},
    {NULL, NULL, 0}};

void R_init_zuroar(DllInfo *dll) {
  R_registerRoutines(dll, NULL, zro_call_methods, NULL, NULL);
  R_useDynamicSymbols(dll, FALSE);
  R_forceSymbols(dll, TRUE);
}
