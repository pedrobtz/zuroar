/* The one way first-party code includes CRoaring (design §4, §7.3).
 *
 * It fixes the build environment before roaring.h is seen:
 * - NDEBUG, so CRoaring's assert() calls compile out without a Makevars
 *   flag;
 * - printf as Rprintf while CRoaring is parsed, so its debugging
 *   printers never reference stdout. The macro is undefined again after
 *   roaring.h, except in the wrapper unit, so it cannot rewrite the
 *   format(printf, ...) attributes in R's headers;
 * - every system header CRoaring uses is included first, outside the
 *   hidden-visibility region, so libc and compiler declarations keep
 *   their default visibility;
 * - CRoaring's own declarations are hidden, so no roaring_* symbol is
 *   exported from zuroar.so to clash with a sibling's vendored copy.
 */
#ifndef ZRO_ROARING_H
#define ZRO_ROARING_H

#ifndef NDEBUG
#define NDEBUG 1
#endif

#include <assert.h>
#include <inttypes.h>
#include <limits.h>
#include <stdarg.h>
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#if !defined(__STDC_NO_ATOMICS__)
#include <stdatomic.h>
#endif
#if !defined(__STDC_VERSION__) || __STDC_VERSION__ < 202311L
#include <stdalign.h>
#endif
#ifdef __GLIBC__
#include <malloc.h>
#endif
#if defined(__linux__) || defined(__CYGWIN__)
#include <byteswap.h>
#include <endian.h>
#endif
/* roaring.h includes <x86intrin.h> on every x86-64 build, even with
 * ROARING_DISABLE_X64, and GCC's <mm_malloc.h> under it declares
 * posix_memalign. So it goes here unconditionally. */
#if defined(__x86_64__) || defined(_M_AMD64)
#include <x86intrin.h>
#if defined(__GNUC__)
#include <cpuid.h>
#endif
#endif
#if defined(__ARM_NEON) && !defined(DISABLENEON)
#include <arm_neon.h>
#endif
#if (defined(__aarch64__) || defined(_M_ARM64)) && defined(__linux__)
#include <sys/auxv.h>
#endif

#include <R_ext/Print.h>
#undef printf
#define printf Rprintf

#if defined(__GNUC__) && !defined(_WIN32)
#define ZRO_HIDE_CROARING 1
#else
/* PE/COFF DLLs export per DLL; no session-wide clash to prevent. */
#define ZRO_HIDE_CROARING 0
#endif

#if ZRO_HIDE_CROARING
/* GCC applies the hidden visibility pragma even to a re-declaration of a
 * function <stdlib.h> already declared, and roaring.c re-declares
 * posix_memalign; the link then fails with "hidden symbol `posix_memalign'
 * isn't defined" (clang keeps the first declaration's visibility). Inside
 * both hidden regions the name is routed to this static forwarder, defined
 * outside them, so any declaration there has internal linkage (C11
 * 6.2.2p4) and no visibility to get wrong. Windows builds take CRoaring's
 * MinGW branch and never reach posix_memalign. */
static inline int zro_posix_memalign(void **memptr, size_t alignment,
                                     size_t size) {
  return posix_memalign(memptr, alignment, size);
}
#define posix_memalign zro_posix_memalign
#pragma GCC visibility push(hidden)
#endif
#include "croaring/roaring.h"
#if ZRO_HIDE_CROARING
#pragma GCC visibility pop
#endif

/* The wrapper unit undefines both after roaring.c. */
#ifndef ZRO_ROARING_UNIT
#undef printf
#undef posix_memalign
#endif

#endif /* ZRO_ROARING_H */
