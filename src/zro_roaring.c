/* The wrapper unit: the only file that includes roaring.c, so CRoaring
 * compiles as one translation unit, in the environment zro_roaring.h sets
 * up and with its symbols hidden (design §4, §7.3). R does not compile
 * src/croaring/ on its own. */
#define ZRO_ROARING_UNIT 1
#include "zro_roaring.h"

#if ZRO_HIDE_CROARING
/* roaring.c re-declares posix_memalign itself. GCC applies the hidden
 * visibility pragma to that re-declaration even though <stdlib.h> declared
 * it first, and the link then fails ("hidden symbol `posix_memalign' isn't
 * defined"); clang keeps the first declaration's visibility. Routing the
 * name to a static forwarder defined here, outside the hidden region,
 * gives CRoaring's extern declaration internal linkage (C11 6.2.2p4), so
 * there is no visibility to get wrong. Windows builds take CRoaring's
 * MinGW branch and never reach posix_memalign. */
static inline int zro_posix_memalign(void **memptr, size_t alignment,
                                     size_t size) {
  return posix_memalign(memptr, alignment, size);
}
#define posix_memalign zro_posix_memalign

#pragma GCC visibility push(hidden)
#endif
#include "croaring/roaring.c"
#if ZRO_HIDE_CROARING
#pragma GCC visibility pop
#undef posix_memalign
#endif
