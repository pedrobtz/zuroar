/* The wrapper unit: the only file that includes roaring.c, so CRoaring
 * compiles as one translation unit, in the environment zro_roaring.h sets
 * up and with its symbols hidden (design §4, §7.3). R does not compile
 * src/croaring/ on its own. */
#define ZRO_ROARING_UNIT 1
#include "zro_roaring.h"

#if ZRO_HIDE_CROARING
#pragma GCC visibility push(hidden)
#endif
#include "croaring/roaring.c"
#if ZRO_HIDE_CROARING
#pragma GCC visibility pop
#endif
#undef printf
#undef posix_memalign
