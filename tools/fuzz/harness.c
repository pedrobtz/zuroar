/* libFuzzer target for roar_unserialize()'s reader (design §8, D8). It
 * compiles CRoaring and src/zro_portable.c directly, without R, with
 * -DZRO_FUZZ; the fuzz workflow builds it under ASan and UBSan.
 *
 * Every input goes through zro_portable_read(), the function the package
 * calls. When it accepts the bytes, the bitmap is exercised (cardinality,
 * iteration, a serialise round trip) so that a structure validation let
 * through still has to survive use. */
#include <assert.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#include "croaring/roaring.c"
#include "zro_portable.h"

/* The 64-bit reader: the same contract, on roaring64's portable format. */
static void fuzz64(const uint8_t *data, size_t size) {
  size_t used = 0;
  const char *reason = NULL;
  roaring64_bitmap_t *r = zro_portable_read64((const char *)data, size, &used, &reason);
  if (r == NULL) {
    if (reason == NULL) abort();
    return;
  }
  if (used == 0 || used > size) abort();
  size_t n = roaring64_bitmap_portable_size_in_bytes(r);
  char *buf = (char *)malloc(n > 0 ? n : 1);
  if (buf != NULL) {
    roaring64_bitmap_portable_serialize(r, buf);
    size_t used2 = 0;
    const char *reason2 = NULL;
    roaring64_bitmap_t *r2 = zro_portable_read64(buf, n, &used2, &reason2);
    if (r2 == NULL || !roaring64_bitmap_equals(r, r2)) abort();
    roaring64_bitmap_free(r2);
    free(buf);
  }
  roaring64_bitmap_free(r);
}

int LLVMFuzzerTestOneInput(const uint8_t *data, size_t size) {
  fuzz64(data, size);
  size_t used = 0;
  const char *reason = NULL;
  roaring_bitmap_t *r = zro_portable_read((const char *)data, size, &used, &reason);
  if (r == NULL) {
    if (reason == NULL) abort(); /* every rejection must say why */
    return 0;
  }
  if (used == 0 || used > size) abort();

  uint64_t card = roaring_bitmap_get_cardinality(r);
  uint64_t seen = 0;
  roaring_uint32_iterator_t it;
  roaring_iterator_init(r, &it);
  uint32_t prev = 0;
  while (it.has_value) {
    if (seen > 0 && it.current_value <= prev) abort(); /* must be sorted */
    prev = it.current_value;
    seen++;
    roaring_uint32_iterator_advance(&it);
  }
  if (seen != card) abort();

  size_t n = roaring_bitmap_portable_size_in_bytes(r);
  char *buf = (char *)malloc(n > 0 ? n : 1);
  if (buf != NULL) {
    roaring_bitmap_portable_serialize(r, buf);
    size_t used2 = 0;
    const char *reason2 = NULL;
    roaring_bitmap_t *r2 = zro_portable_read(buf, n, &used2, &reason2);
    if (r2 == NULL || !roaring_bitmap_equals(r, r2)) abort();
    roaring_bitmap_free(r2);
    free(buf);
  }
  roaring_bitmap_free(r);
  return 0;
}
