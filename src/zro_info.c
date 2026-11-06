#include "zro_roaring.h"

#define R_NO_REMAP
#include <R.h>
#include <Rinternals.h>

#include "zro_init.h"

/* What CRoaring was compiled with and what this processor offers. The
 * CRoaring call comes first; R objects are built only after it returns. */
SEXP zro_info(void) {
#if defined(CROARING_IS_X64) || defined(CROARING_IS_ARM64)
  int hw = croaring_hardware_support();
#endif

  const char *compiled[3];
  int n_compiled = 0;
#if defined(CROARING_IS_X64)
  compiled[n_compiled++] = "avx2";
#if CROARING_COMPILER_SUPPORTS_AVX512
  compiled[n_compiled++] = "avx512";
#endif
#endif
#if defined(CROARING_USENEON)
  compiled[n_compiled++] = "neon";
#endif

  const char *runtime[4];
  int n_runtime = 0;
#if defined(CROARING_IS_X64) || defined(CROARING_IS_ARM64)
  if (hw & ROARING_SUPPORTS_AVX2) runtime[n_runtime++] = "avx2";
  if (hw & ROARING_SUPPORTS_AVX512) runtime[n_runtime++] = "avx512";
  if (hw & ROARING_SUPPORTS_SVE) runtime[n_runtime++] = "sve";
  if (hw & ROARING_SUPPORTS_SVE2) runtime[n_runtime++] = "sve2";
#endif

  SEXP out = PROTECT(Rf_allocVector(VECSXP, 3));
  SET_VECTOR_ELT(out, 0, Rf_mkString(ROARING_VERSION));

  SEXP comp = PROTECT(Rf_allocVector(STRSXP, n_compiled));
  for (int i = 0; i < n_compiled; i++) {
    SET_STRING_ELT(comp, i, Rf_mkChar(compiled[i]));
  }
  SET_VECTOR_ELT(out, 1, comp);

  SEXP run = PROTECT(Rf_allocVector(STRSXP, n_runtime));
  for (int i = 0; i < n_runtime; i++) {
    SET_STRING_ELT(run, i, Rf_mkChar(runtime[i]));
  }
  SET_VECTOR_ELT(out, 2, run);

  SEXP names = PROTECT(Rf_allocVector(STRSXP, 3));
  SET_STRING_ELT(names, 0, Rf_mkChar("croaring"));
  SET_STRING_ELT(names, 1, Rf_mkChar("compiled"));
  SET_STRING_ELT(names, 2, Rf_mkChar("runtime"));
  Rf_setAttrib(out, R_NamesSymbol, names);

  UNPROTECT(4);
  return out;
}
