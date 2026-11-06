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

/* zro_altrep.c */
SEXP zro_sum(SEXP a0);
/* zro_altrep.c, test hooks */
SEXP zro_test_dataptr(SEXP a0);
SEXP zro_test_state(SEXP a0);
SEXP zro_test_unserialize(SEXP a0);

/* zro_algebra.c */
SEXP zro_binop(SEXP a0, SEXP a1, SEXP a2);
SEXP zro_binop_cardinality(SEXP a0, SEXP a1, SEXP a2);
SEXP zro_compare(SEXP a0, SEXP a1, SEXP a2);
SEXP zro_jaccard(SEXP a0, SEXP a1);
SEXP zro_many(SEXP a0, SEXP a1);
SEXP zro_flip(SEXP a0, SEXP a1);
SEXP zro_shift(SEXP a0, SEXP a1);

/* zro_order.c */
SEXP zro_rank(SEXP a0, SEXP a1);
SEXP zro_select(SEXP a0, SEXP a1);
SEXP zro_next(SEXP a0, SEXP a1);
SEXP zro_prev(SEXP a0, SEXP a1);
SEXP zro_range_count(SEXP a0, SEXP a1);
SEXP zro_contains_range(SEXP a0, SEXP a1);
SEXP zro_change_range(SEXP a0, SEXP a1, SEXP a2);
SEXP zro_values(SEXP a0, SEXP a1, SEXP a2, SEXP a3);
SEXP zro_subset(SEXP a0, SEXP a1, SEXP a2, SEXP a3);
SEXP zro_optimize(SEXP a0);
SEXP zro_size(SEXP a0);
SEXP zro_stats(SEXP a0);

/* zro_serial.c */
SEXP zro_serialize(SEXP a0, SEXP a1);
SEXP zro_unserialize(SEXP a0, SEXP a1);

/* zro_bitmap64.c */
SEXP zro64_is_null(SEXP a0);
SEXP zro64_from_values(SEXP a0, SEXP a1);
SEXP zro64_from_range(SEXP a0);
SEXP zro64_promote(SEXP a0);
SEXP zro64_add(SEXP a0, SEXP a1);
SEXP zro64_remove(SEXP a0, SEXP a1);
SEXP zro64_change_range(SEXP a0, SEXP a1, SEXP a2);
SEXP zro64_contains(SEXP a0, SEXP a1);
SEXP zro64_cardinality(SEXP a0);
SEXP zro64_length_text(SEXP a0);
SEXP zro64_is_empty(SEXP a0);
SEXP zro64_min(SEXP a0);
SEXP zro64_max(SEXP a0);
SEXP zro64_to_r(SEXP a0, SEXP a1);
SEXP zro64_values_from(SEXP a0, SEXP a1, SEXP a2, SEXP a3);
SEXP zro64_head_text(SEXP a0, SEXP a1);
SEXP zro64_binop(SEXP a0, SEXP a1, SEXP a2);
SEXP zro64_binop_cardinality(SEXP a0, SEXP a1, SEXP a2);
SEXP zro64_compare(SEXP a0, SEXP a1, SEXP a2);
SEXP zro64_jaccard(SEXP a0, SEXP a1);
SEXP zro64_many(SEXP a0, SEXP a1);
SEXP zro64_flip(SEXP a0, SEXP a1);
SEXP zro64_shift(SEXP a0, SEXP a1, SEXP a2);
SEXP zro64_rank(SEXP a0, SEXP a1);
SEXP zro64_select(SEXP a0, SEXP a1);
SEXP zro64_next(SEXP a0, SEXP a1);
SEXP zro64_prev(SEXP a0, SEXP a1);
SEXP zro64_range_count(SEXP a0, SEXP a1);
SEXP zro64_contains_range(SEXP a0, SEXP a1);
SEXP zro64_subset(SEXP a0, SEXP a1, SEXP a2, SEXP a3);
SEXP zro64_optimize(SEXP a0);
SEXP zro64_size(SEXP a0);
SEXP zro64_stats(SEXP a0);
SEXP zro64_serialize(SEXP a0, SEXP a1);
SEXP zro64_unserialize(SEXP a0, SEXP a1);

#endif /* ZRO_INIT_H */
