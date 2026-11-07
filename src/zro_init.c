#define R_NO_REMAP
#include <R.h>
#include <Rinternals.h>
#include <R_ext/Rdynload.h>

#include "zro_bitmap.h"
#include "zro_init.h"

static const R_CallMethodDef zro_call_methods[] = {
    {"zro_info", (DL_FUNC)&zro_info, 0},
    {"zro_selftest", (DL_FUNC)&zro_selftest, 3},
    {"zro_from_values", (DL_FUNC)&zro_from_values, 2},
    {"zro_from_range", (DL_FUNC)&zro_from_range, 1},
    {"zro_add", (DL_FUNC)&zro_add, 2},
    {"zro_remove", (DL_FUNC)&zro_remove, 2},
    {"zro_contains", (DL_FUNC)&zro_contains, 2},
    {"zro_cardinality", (DL_FUNC)&zro_cardinality, 1},
    {"zro_min", (DL_FUNC)&zro_min, 1},
    {"zro_max", (DL_FUNC)&zro_max, 1},
    {"zro_to_double", (DL_FUNC)&zro_to_double, 1},
    {"zro_to_integer", (DL_FUNC)&zro_to_integer, 1},
    {"zro_head_values", (DL_FUNC)&zro_head_values, 2},
    {"zro_binop", (DL_FUNC)&zro_binop, 3},
    {"zro_binop_cardinality", (DL_FUNC)&zro_binop_cardinality, 3},
    {"zro_compare", (DL_FUNC)&zro_compare, 3},
    {"zro_jaccard", (DL_FUNC)&zro_jaccard, 2},
    {"zro_many", (DL_FUNC)&zro_many, 2},
    {"zro_flip", (DL_FUNC)&zro_flip, 2},
    {"zro_shift", (DL_FUNC)&zro_shift, 2},
    {"zro_sum", (DL_FUNC)&zro_sum, 1},
    {"zro_rank", (DL_FUNC)&zro_rank, 2},
    {"zro_select", (DL_FUNC)&zro_select, 2},
    {"zro_next", (DL_FUNC)&zro_next, 2},
    {"zro_prev", (DL_FUNC)&zro_prev, 2},
    {"zro_range_count", (DL_FUNC)&zro_range_count, 2},
    {"zro_contains_range", (DL_FUNC)&zro_contains_range, 2},
    {"zro_change_range", (DL_FUNC)&zro_change_range, 3},
    {"zro_values", (DL_FUNC)&zro_values, 4},
    {"zro_subset", (DL_FUNC)&zro_subset, 4},
    {"zro_optimize", (DL_FUNC)&zro_optimize, 1},
    {"zro_size", (DL_FUNC)&zro_size, 1},
    {"zro_stats", (DL_FUNC)&zro_stats, 1},
    {"zro_test_dataptr", (DL_FUNC)&zro_test_dataptr, 1},
    {"zro_test_state", (DL_FUNC)&zro_test_state, 1},
    {"zro_test_unserialize", (DL_FUNC)&zro_test_unserialize, 1},
    {NULL, NULL, 0}};

void R_init_zuroar(DllInfo *dll) {
  zro_init_altrep(dll);
  R_registerRoutines(dll, NULL, zro_call_methods, NULL, NULL);
  R_useDynamicSymbols(dll, FALSE);
  R_forceSymbols(dll, TRUE);
}
