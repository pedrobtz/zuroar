#define R_NO_REMAP
#include <R.h>
#include <Rinternals.h>
#include <R_ext/Rdynload.h>

/* Routine registration. Later stages add their .Call entries here. */
static const R_CallMethodDef zro_call_methods[] = {{NULL, NULL, 0}};

void R_init_zuroar(DllInfo *dll) {
  R_registerRoutines(dll, NULL, zro_call_methods, NULL, NULL);
  R_useDynamicSymbols(dll, FALSE);
  R_forceSymbols(dll, TRUE);
}
