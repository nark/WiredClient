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

#ifndef WI_UUID_H
#define WI_UUID_H 1

#include <wired/wi-base.h>
#include <wired/wi-runtime.h>

#define WI_UUID_BUFFER_SIZE			16


typedef struct _wi_uuid				wi_uuid_t;


WI_EXPORT wi_runtime_id_t			wi_uuid_runtime_id(void);

WI_EXPORT wi_uuid_t *				wi_uuid(void);
WI_EXPORT wi_uuid_t *				wi_uuid_with_string(wi_string_t *);
WI_EXPORT wi_uuid_t *				wi_uuid_with_bytes(const void *);

WI_EXPORT wi_uuid_t *				wi_uuid_alloc(void);
WI_EXPORT wi_uuid_t *				wi_uuid_init(wi_uuid_t *);
WI_EXPORT wi_uuid_t *				wi_uuid_init_from_random_data(wi_uuid_t *);
WI_EXPORT wi_uuid_t *				wi_uuid_init_from_time(wi_uuid_t *);
WI_EXPORT wi_uuid_t *				wi_uuid_init_with_string(wi_uuid_t *, wi_string_t *);
WI_EXPORT wi_uuid_t *				wi_uuid_init_with_bytes(wi_uuid_t *, const void *);

WI_EXPORT wi_string_t *				wi_uuid_string(wi_uuid_t *);
WI_EXPORT void						wi_uuid_get_bytes(wi_uuid_t *, void *);

#endif /* WI_UUID_H */
