/* $Id$ */

/*
 *  Copyright (c) 2005-2009 Axel Andersson
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
 * @file wi-macros.h 
 * @brief Various common C macros
 * @author Axel Andersson, Rafaël Warnault
 * @version 2.0
 *
 */

#ifndef WI_MACROS_H
#define WI_MACROS_H 1

#ifndef INT8_MAX
#define INT8_MAX		127
#define INT16_MAX		32767
#define INT32_MAX		2147483647
#define INT64_MAX		9223372036854775807LL
#define INT32_MIN		(-INT32_MAX-1)
#define INT64_MIN		(-INT64_MAX-1)
#define UINT8_MAX		255
#define UINT16_MAX		65535
#define UINT32_MAX		4294967295U
#define UINT64_MAX		18446744073709551615ULL
#endif

#define WI_STMT_START \
	do {

#define WI_STMT_END \
	} while(0)

#define WI_ARRAY_SIZE(array) \
	(sizeof(array) / sizeof(*(array)))

#define WI_MIN(x, y) \
	((x) < (y) ? (x) : (y))

#define WI_MAX(x, y) \
	((x) > (y) ? (x) : (y))

#define WI_ABS(x) \
	((x) < 0 ? (-(x)) : (x))

#define WI_CLAMP(x, min, max) \
	(((x) > (max)) ? (max) : (((x) < (min)) ? (min) : (x)))

#endif /* WI_MACROS_H */
