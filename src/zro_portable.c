#include "zro_portable.h"

roaring_bitmap_t *zro_portable_read(const char *buf, size_t len, size_t *used,
                                    const char **reason) {
  *used = 0;
  *reason = NULL;
  if (len == 0) {
    *reason = "no bytes to read";
    return NULL;
  }
  /* Bounded by len: how many bytes a well-formed header says the bitmap
   * takes, or 0 when the header is malformed or claims more than len. */
  size_t need = roaring_bitmap_portable_deserialize_size(buf, len);
  if (need == 0 || need > len) {
    *reason = "the bytes are not a complete portable Roaring bitmap "
              "(bad cookie, truncated, or a header that claims more bytes "
              "than there are)";
    return NULL;
  }
  roaring_bitmap_t *r = roaring_bitmap_portable_deserialize_safe(buf, need);
  if (r == NULL) {
    *reason = "CRoaring's safe deserialiser rejected the bytes";
    return NULL;
  }
  const char *why = NULL;
  if (!roaring_bitmap_internal_validate(r, &why)) {
    roaring_bitmap_free(r);
    *reason = (why != NULL) ? why : "the bitmap failed validation";
    return NULL;
  }
  *used = need;
  return r;
}

roaring64_bitmap_t *zro_portable_read64(const char *buf, size_t len,
                                        size_t *used, const char **reason) {
  *used = 0;
  *reason = NULL;
  if (len == 0) {
    *reason = "no bytes to read";
    return NULL;
  }
  size_t need = roaring64_bitmap_portable_deserialize_size(buf, len);
  if (need == 0 || need > len) {
    *reason = "the bytes are not a complete portable 64-bit Roaring bitmap "
              "(truncated, or a header that claims more bytes than there "
              "are)";
    return NULL;
  }
  roaring64_bitmap_t *r = roaring64_bitmap_portable_deserialize_safe(buf, need);
  if (r == NULL) {
    *reason = "CRoaring's safe deserialiser rejected the bytes";
    return NULL;
  }
  const char *why = NULL;
  if (!roaring64_bitmap_internal_validate(r, &why)) {
    roaring64_bitmap_free(r);
    *reason = (why != NULL) ? why : "the bitmap failed validation";
    return NULL;
  }
  *used = need;
  return r;
}
