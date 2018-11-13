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

#ifndef WI_POOL_H
#define WI_POOL_H 1

#include <wired/wi-base.h>
#include <wired/wi-runtime.h>

#define wi_autorelease(instance)	_wi_autorelease((instance), __FILE__, __LINE__)


typedef struct _wi_pool				wi_pool_t;


WI_EXPORT wi_runtime_id_t			wi_pool_runtime_id(void);

WI_EXPORT wi_pool_t *				wi_pool_alloc(void);
WI_EXPORT wi_pool_t *				wi_pool_init(wi_pool_t *);
WI_EXPORT wi_pool_t *				wi_pool_init_with_debug(wi_pool_t *, wi_boolean_t);

WI_EXPORT void						wi_pool_drain(wi_pool_t *);
WI_EXPORT wi_uinteger_t				wi_pool_count(wi_pool_t *);

WI_EXPORT void						wi_pool_set_context(wi_pool_t *, wi_string_t *);

WI_EXPORT wi_runtime_instance_t *	_wi_autorelease(wi_runtime_instance_t *, const char *, wi_uinteger_t);


WI_EXPORT wi_boolean_t				wi_pool_debug;

#endif /* WI_POOL_H */
