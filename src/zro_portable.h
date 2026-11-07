/* The bounded reader of portable bytes (design §6.4, D8), in plain C with
 * no R API, so that tools/fuzz/harness.c fuzzes exactly the code the
 * package runs. Built with -DZRO_FUZZ, it includes CRoaring directly. */
#ifndef ZRO_PORTABLE_H
#define ZRO_PORTABLE_H

#include <stddef.h>

#ifdef ZRO_FUZZ
#include "croaring/roaring.h"
#else
#include "zro_roaring.h"
#endif

/* Reads one 32-bit bitmap from the first `len` bytes of `buf`, through the
 * size check, CRoaring's safe deserialiser and structural validation, in
 * that order. Never reads past `buf + len`. On success, returns the bitmap
 * and stores the number of bytes it used in `*used`. On failure, returns
 * NULL and points `*reason` at a static string saying why. */
roaring_bitmap_t *zro_portable_read(const char *buf, size_t len, size_t *used,
                                    const char **reason);

#endif /* ZRO_PORTABLE_H */
