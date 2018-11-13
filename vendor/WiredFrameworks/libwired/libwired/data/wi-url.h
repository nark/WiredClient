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

#ifndef WI_URL_H
#define WI_URL_H 1

#include <wired/wi-base.h>
#include <wired/wi-runtime.h>

typedef struct _wi_url			wi_url_t;
typedef struct _wi_url			wi_mutable_url_t;


WI_EXPORT wi_runtime_id_t		wi_url_runtime_id(void);

WI_EXPORT wi_url_t *			wi_url_with_string(wi_string_t *);

WI_EXPORT wi_url_t *			wi_url_alloc(void);
WI_EXPORT wi_mutable_url_t *	wi_mutable_url_alloc(void);
WI_EXPORT wi_url_t *			wi_url_init(wi_url_t *);
WI_EXPORT wi_url_t *			wi_url_init_with_string(wi_url_t *, wi_string_t *);

WI_EXPORT wi_string_t *			wi_url_scheme(wi_url_t *);
WI_EXPORT wi_string_t *			wi_url_host(wi_url_t *);
WI_EXPORT wi_uinteger_t			wi_url_port(wi_url_t *);
WI_EXPORT wi_string_t *			wi_url_path(wi_url_t *);
WI_EXPORT wi_string_t *			wi_url_user(wi_url_t *);
WI_EXPORT wi_string_t *			wi_url_password(wi_url_t *);

WI_EXPORT wi_boolean_t			wi_url_is_valid(wi_url_t *);
WI_EXPORT wi_string_t *			wi_url_string(wi_url_t *);

WI_EXPORT void					wi_mutable_url_set_scheme(wi_mutable_url_t *, wi_string_t *);
WI_EXPORT void					wi_mutable_url_set_host(wi_mutable_url_t *, wi_string_t *);
WI_EXPORT void					wi_mutable_url_set_port(wi_mutable_url_t *, wi_uinteger_t);
WI_EXPORT void					wi_mutable_url_set_path(wi_mutable_url_t *, wi_string_t *);
WI_EXPORT void					wi_mutable_url_set_user(wi_mutable_url_t *, wi_string_t *);
WI_EXPORT void					wi_mutable_url_set_password(wi_mutable_url_t *, wi_string_t *);

#endif /* WI_URL_H */
