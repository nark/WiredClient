/* $Id$ */

/*
 *  Copyright (c) 2006-2009 Axel Andersson
 *  All rights reserved.
 *
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions
 *  are met:
 *  1. Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 *  2. Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
 * ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

/**
 * @file wi-byteorder.h 
 * @brief Support for byte order
 * @author Axel Andersson, Rafaël Warnault
 * @version 2.0
 *  
 * Supports big and little endians
 *
 */

#ifndef WI_BYTEORDER_H
#define WI_BYTEORDER_H 1

#include <wired/wi-base.h>

#include <sys/param.h>
#include <inttypes.h>

#if defined(BYTE_ORDER) && defined(BIG_ENDIAN) && defined(LITTLE_ENDIAN)
#if BYTE_ORDER == BIG_ENDIAN
#define WI_BIG_ENDIAN                       1
#elif BYTE_ORDER == LITTLE_ENDIAN
#define WI_LITTLE_ENDIAN                    1
#else
#error Unknown byte order
#endif
#elif defined(__BIG_ENDIAN__) || defined(_BIG_ENDIAN)
#define WI_BIG_ENDIAN                       1
#elif defined(__LITTLE_ENDIAN__) || defined(_LITTLE_ENDIAN)
#define WI_LITTLE_ENDIAN                    1
#else
#error Unknown byte order
#endif


#define WI_SWAP_INT16(n)                                                \
((uint16_t) ((((uint16_t) (n) & 0xFF00) >> 8) |                        \
(((uint16_t) (n) & 0x00FF) << 8)))

#define WI_SWAP_INT32(n)                                                \
((uint32_t) ((((uint32_t) (n) & 0xFF000000) >> 24) |                \
(((uint32_t) (n) & 0x00FF0000) >>  8) |                \
(((uint32_t) (n) & 0x0000FF00) <<  8) |                \
(((uint32_t) (n) & 0x000000FF) << 24)))

#define WI_SWAP_INT64(n)                                                \
((uint64_t) ((((uint64_t) (n) & 0xFF00000000000000ULL) >> 56) |        \
(((uint64_t) (n) & 0x00FF000000000000ULL) >> 40) |        \
(((uint64_t) (n) & 0x0000FF0000000000ULL) >> 24) |        \
(((uint64_t) (n) & 0x000000FF00000000ULL) >>  8) |        \
(((uint64_t) (n) & 0x00000000FF000000ULL) <<  8) |        \
(((uint64_t) (n) & 0x0000000000FF0000ULL) << 24) |        \
(((uint64_t) (n) & 0x000000000000FF00ULL) << 40) |        \
(((uint64_t) (n) & 0x00000000000000FFULL) << 56)))


#ifdef WI_BIG_ENDIAN

#define WI_SWAP_HOST_TO_BIG_INT16(n)        (n)
#define WI_SWAP_HOST_TO_BIG_INT32(n)        (n)
#define WI_SWAP_HOST_TO_BIG_INT64(n)        (n)

#define WI_SWAP_HOST_TO_LITTLE_INT16(n)        WI_SWAP_INT16(n)
#define WI_SWAP_HOST_TO_LITTLE_INT32(n)        WI_SWAP_INT32(n)
#define WI_SWAP_HOST_TO_LITTLE_INT64(n)        WI_SWAP_INT64(n)

#define WI_SWAP_BIG_TO_HOST_INT16(n)        (n)
#define WI_SWAP_BIG_TO_HOST_INT32(n)        (n)
#define WI_SWAP_BIG_TO_HOST_INT64(n)        (n)

#define WI_SWAP_LITTLE_TO_HOST_INT16(n)        WI_SWAP_INT16(n)
#define WI_SWAP_LITTLE_TO_HOST_INT32(n)        WI_SWAP_INT32(n)
#define WI_SWAP_LITTLE_TO_HOST_INT64(n)        WI_SWAP_INT64(n)

#else

#define WI_SWAP_HOST_TO_BIG_INT16(n)        WI_SWAP_INT16(n)
#define WI_SWAP_HOST_TO_BIG_INT32(n)        WI_SWAP_INT32(n)
#define WI_SWAP_HOST_TO_BIG_INT64(n)        WI_SWAP_INT64(n)

#define WI_SWAP_HOST_TO_LITTLE_INT16(n)        (n)
#define WI_SWAP_HOST_TO_LITTLE_INT32(n)        (n)
#define WI_SWAP_HOST_TO_LITTLE_INT64(n)        (n)

#define WI_SWAP_BIG_TO_HOST_INT16(n)        WI_SWAP_INT16(n)
#define WI_SWAP_BIG_TO_HOST_INT32(n)        WI_SWAP_INT32(n)
#define WI_SWAP_BIG_TO_HOST_INT64(n)        WI_SWAP_INT64(n)

#define WI_SWAP_LITTLE_TO_HOST_INT16(n)        (n)
#define WI_SWAP_LITTLE_TO_HOST_INT32(n)        (n)
#define WI_SWAP_LITTLE_TO_HOST_INT64(n)        (n)

#endif


static inline uint16_t wi_read_swap_big_to_host_int16(void *base, uintptr_t offset) {
    uint16_t    n;
    
    n = *(uint16_t *) ((uintptr_t) base + offset);
    
    return WI_SWAP_BIG_TO_HOST_INT16(n);
}



static inline uint32_t wi_read_swap_big_to_host_int32(void *base, uintptr_t offset) {
    uint32_t    n;
    
    n = *(uint32_t *) ((uintptr_t) base + offset);
    
    return WI_SWAP_BIG_TO_HOST_INT32(n);
}



static inline uint64_t wi_read_swap_big_to_host_int64(void *base, uintptr_t offset) {
    uint64_t        n;
    
    n = *(uint64_t *) ((uintptr_t) base + offset);
    
    return WI_SWAP_BIG_TO_HOST_INT64(n);
}



static inline void wi_write_swap_host_to_big_int16(void *base, uintptr_t offset, uint16_t n) {
    *(uint16_t *) ((uintptr_t) base + offset) = WI_SWAP_HOST_TO_BIG_INT16(n);
}



static inline void wi_write_swap_host_to_big_int32(void *base, uintptr_t offset, uint32_t n) {
    *(uint32_t *) ((uintptr_t) base + offset) = WI_SWAP_HOST_TO_BIG_INT32(n);
}



static inline void wi_write_swap_host_to_big_int64(void *base, uintptr_t offset, uint64_t n) {
    *(uint64_t *) ((uintptr_t) base + offset) = WI_SWAP_HOST_TO_BIG_INT64(n);
}


WI_EXPORT double wi_read_double_from_ieee754(void *, uintptr_t);
WI_EXPORT void wi_write_double_to_ieee754(void *, uintptr_t, double);

#endif
