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

#ifndef WI_DATA_H
#define WI_DATA_H 1

#include <wired/wi-base.h>
#include <wired/wi-runtime.h>

typedef struct _wi_data					wi_data_t;
typedef struct _wi_data					wi_mutable_data_t;


WI_EXPORT wi_runtime_id_t				wi_data_runtime_id(void);

WI_EXPORT wi_data_t *					wi_data(void);
WI_EXPORT wi_data_t *					wi_data_with_bytes(const void *, wi_uinteger_t);
WI_EXPORT wi_data_t *					wi_data_with_bytes_no_copy(void *, wi_uinteger_t, wi_boolean_t);
WI_EXPORT wi_data_t *					wi_data_with_random_bytes(wi_uinteger_t);
WI_EXPORT wi_data_t *					wi_data_with_base64(wi_string_t *);
WI_EXPORT wi_data_t *					wi_data_with_contents_of_file(wi_string_t *);
WI_EXPORT wi_mutable_data_t *			wi_mutable_data(void);

WI_EXPORT wi_data_t *					wi_data_alloc(void);
WI_EXPORT wi_mutable_data_t *			wi_mutable_data_alloc(void);
WI_EXPORT wi_data_t *					wi_data_init(wi_data_t *);
WI_EXPORT wi_data_t *					wi_data_init_with_capacity(wi_data_t *, wi_uinteger_t);
WI_EXPORT wi_data_t *					wi_data_init_with_bytes(wi_data_t *, const void *, wi_uinteger_t);
WI_EXPORT wi_data_t *					wi_data_init_with_bytes_no_copy(wi_data_t *, void *, wi_uinteger_t, wi_boolean_t);
WI_EXPORT wi_data_t *					wi_data_init_with_random_bytes(wi_data_t *, wi_uinteger_t);
WI_EXPORT wi_data_t *					wi_data_init_with_base64(wi_data_t *, wi_string_t *);
WI_EXPORT wi_data_t *					wi_data_init_with_contents_of_file(wi_data_t *, wi_string_t *);

WI_EXPORT const void *					wi_data_bytes(wi_data_t *);
WI_EXPORT wi_uinteger_t					wi_data_length(wi_data_t *);
WI_EXPORT void							wi_data_get_bytes(wi_data_t *, void *, wi_uinteger_t);

WI_EXPORT wi_data_t *					wi_data_by_appending_data(wi_data_t *, wi_data_t *);
WI_EXPORT wi_data_t *					wi_data_by_appending_bytes(wi_data_t *, const void *, wi_uinteger_t);

WI_EXPORT wi_string_t *					wi_data_md5(wi_data_t *);
WI_EXPORT wi_string_t *					wi_data_sha1(wi_data_t *);
WI_EXPORT wi_string_t *					wi_data_sha256(wi_data_t *);
WI_EXPORT wi_string_t *					wi_data_base64(wi_data_t *);

WI_EXPORT wi_boolean_t					wi_data_write_to_file(wi_data_t *, wi_string_t *);

WI_EXPORT void							wi_mutable_data_append_data(wi_mutable_data_t *, wi_data_t *);
WI_EXPORT void							wi_mutable_data_append_bytes(wi_mutable_data_t *, const void *, wi_uinteger_t);

#endif /* WI_DATA_H */
