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

static inline uint16_t wi_read_swap_big_to_host_int16(void *base, uintptr_t offset) {
	uint16_t	n = 0;
	uint8_t	*p = base;
	n |= p[offset + 0] << 8;
	n |= p[offset + 1] << 0;
	
	return n;
}



static inline uint32_t wi_read_swap_big_to_host_int32(void *base, uintptr_t offset) {
	uint32_t	n = 0;
	uint8_t	*p = base;
	n |= p[offset + 0] << 24;
	n |= p[offset + 1] << 16;
	n |= p[offset + 2] << 8;
	n |= p[offset + 3] << 0;
	
	return n;
}



static inline uint64_t wi_read_swap_big_to_host_int64(void *base, uintptr_t offset) {
	uint64_t	n = 0;
	uint8_t	*p = base;
	n |= (uint64_t)(p[offset + 0]) << 56;
	n |= (uint64_t)(p[offset + 1]) << 48;
	n |= (uint64_t)(p[offset + 2]) << 40;
	n |= (uint64_t)(p[offset + 3]) << 32;
	n |= (uint64_t)(p[offset + 4]) << 24;
	n |= (uint64_t)(p[offset + 5]) << 16;
	n |= (uint64_t)(p[offset + 6]) <<  8;
	n |= (uint64_t)(p[offset + 7]) <<  0;

	return n;
}



static inline void wi_write_swap_host_to_big_int16(void *base, uintptr_t offset, uint16_t n) {
	uint8_t	*p = base;
	p[offset + 0] = (0xFF00 & n) >> 8;
	p[offset + 1] = (0x00FF & n) >> 0;
}



static inline void wi_write_swap_host_to_big_int32(void *base, uintptr_t offset, uint32_t n) {
	uint8_t	*p = base;
	p[offset + 0] = (0xFF000000 & n) >> 24;
	p[offset + 1] = (0x00FF0000 & n) >> 16;
	p[offset + 2] = (0x0000FF00 & n) >>  8;
	p[offset + 3] = (0x000000FF & n) >>  0;
}



static inline void wi_write_swap_host_to_big_int64(void *base, uintptr_t offset, uint64_t n) {
	uint8_t	*p = base;
	p[offset + 0] = (n & 0xFF00000000000000ULL) >> 56;
	p[offset + 1] = (n & 0x00FF000000000000ULL) >> 48;
	p[offset + 2] = (n & 0x0000FF0000000000ULL) >> 40;
	p[offset + 3] = (n & 0x000000FF00000000ULL) >> 32;
	p[offset + 4] = (n & 0x00000000FF000000ULL) << 24;
	p[offset + 5] = (n & 0x0000000000FF0000ULL) << 16;
	p[offset + 6] = (n & 0x000000000000FF00ULL) <<  8;
	p[offset + 7] = (n & 0x00000000000000FFULL) <<  0;
}


WI_EXPORT double wi_read_double_from_ieee754(void *, uintptr_t);
WI_EXPORT void wi_write_double_to_ieee754(void *, uintptr_t, double);

#endif
