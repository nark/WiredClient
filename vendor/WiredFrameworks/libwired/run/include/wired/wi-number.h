/* $Id$ */

/*
 *  Copyright (c) 2003-2009 Axel Andersson
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

#ifndef WI_NUMBER_H
#define WI_NUMBER_H 1

#include <inttypes.h>
#include <wired/wi-base.h>
#include <wired/wi-runtime.h>

#define WI_INT32(number) \
	wi_number_with_int32((number))


typedef struct _wi_number				wi_number_t;


enum _wi_number_type {
	WI_NUMBER_BOOL,
	WI_NUMBER_CHAR,
	WI_NUMBER_SHORT,
	WI_NUMBER_INT,
	WI_NUMBER_INT8,
	WI_NUMBER_INT16,
	WI_NUMBER_INT32,
	WI_NUMBER_INT64,
	WI_NUMBER_LONG,
	WI_NUMBER_LONG_LONG,
	WI_NUMBER_FLOAT,
	WI_NUMBER_DOUBLE
};
typedef enum _wi_number_type			wi_number_type_t;

enum _wi_number_storage_type {
	WI_NUMBER_STORAGE_INT8,
	WI_NUMBER_STORAGE_INT16,
	WI_NUMBER_STORAGE_INT32,
	WI_NUMBER_STORAGE_INT64,
	WI_NUMBER_STORAGE_FLOAT,
	WI_NUMBER_STORAGE_DOUBLE,
};
typedef enum _wi_number_storage_type	wi_number_storage_type_t;


WI_EXPORT wi_runtime_id_t				wi_number_runtime_id(void);

WI_EXPORT wi_number_t *					wi_number_with_value(wi_number_type_t, const void *);
WI_EXPORT wi_number_t *					wi_number_with_bool(wi_boolean_t);
WI_EXPORT wi_number_t *					wi_number_with_char(char);
WI_EXPORT wi_number_t *					wi_number_with_short(short);
WI_EXPORT wi_number_t *					wi_number_with_int(int);
WI_EXPORT wi_number_t *					wi_number_with_int32(int32_t);
WI_EXPORT wi_number_t *					wi_number_with_int64(int64_t);
WI_EXPORT wi_number_t *					wi_number_with_integer(wi_integer_t);
WI_EXPORT wi_number_t *					wi_number_with_long(long);
WI_EXPORT wi_number_t *					wi_number_with_long_long(long long);
WI_EXPORT wi_number_t *					wi_number_with_float(float);
WI_EXPORT wi_number_t *					wi_number_with_double(double);

WI_EXPORT wi_number_t *					wi_number_alloc(void);
WI_EXPORT wi_number_t *					wi_number_init_with_value(wi_number_t *, wi_number_type_t, const void *);
WI_EXPORT wi_number_t *					wi_number_init_with_bool(wi_number_t *, wi_boolean_t);
WI_EXPORT wi_number_t *					wi_number_init_with_char(wi_number_t *, char);
WI_EXPORT wi_number_t *					wi_number_init_with_short(wi_number_t *, short);
WI_EXPORT wi_number_t *					wi_number_init_with_int(wi_number_t *, int);
WI_EXPORT wi_number_t *					wi_number_init_with_int32(wi_number_t *, int32_t);
WI_EXPORT wi_number_t *					wi_number_init_with_int64(wi_number_t *, int64_t);
WI_EXPORT wi_number_t *					wi_number_init_with_integer(wi_number_t *, wi_integer_t);
WI_EXPORT wi_number_t *					wi_number_init_with_long(wi_number_t *, long);
WI_EXPORT wi_number_t *					wi_number_init_with_long_long(wi_number_t *, long long);
WI_EXPORT wi_number_t *					wi_number_init_with_float(wi_number_t *, float);
WI_EXPORT wi_number_t *					wi_number_init_with_double(wi_number_t *, double);

WI_EXPORT wi_integer_t					wi_number_compare(wi_runtime_instance_t *, wi_runtime_instance_t *);

WI_EXPORT wi_number_type_t				wi_number_type(wi_number_t *);
WI_EXPORT wi_number_storage_type_t		wi_number_storage_type(wi_number_t *);
WI_EXPORT void							wi_number_get_value(wi_number_t *, wi_number_type_t, void *);
WI_EXPORT wi_boolean_t					wi_number_bool(wi_number_t *);
WI_EXPORT char							wi_number_char(wi_number_t *);
WI_EXPORT short							wi_number_short(wi_number_t *);
WI_EXPORT int							wi_number_int(wi_number_t *);
WI_EXPORT int32_t						wi_number_int32(wi_number_t *);
WI_EXPORT int64_t						wi_number_int64(wi_number_t *);
WI_EXPORT wi_integer_t					wi_number_integer(wi_number_t *);
WI_EXPORT long							wi_number_long(wi_number_t *);
WI_EXPORT long long						wi_number_long_long(wi_number_t *);
WI_EXPORT float							wi_number_float(wi_number_t *);
WI_EXPORT double						wi_number_double(wi_number_t *);

WI_EXPORT wi_string_t *					wi_number_string(wi_number_t *);

#endif /* WI_NUMBER_H */
