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

#ifndef WI_HOST_H
#define WI_HOST_H 1

#include <wired/wi-base.h>
#include <wired/wi-runtime.h>

typedef struct _wi_host				wi_host_t;


WI_EXPORT wi_runtime_id_t			wi_host_runtime_id(void);

WI_EXPORT wi_host_t *				wi_host(void);
WI_EXPORT wi_host_t *				wi_host_with_string(wi_string_t *);

WI_EXPORT wi_host_t *				wi_host_alloc(void);
WI_EXPORT wi_host_t *				wi_host_init(wi_host_t *);
WI_EXPORT wi_host_t *				wi_host_init_with_string(wi_host_t *, wi_string_t *);

WI_EXPORT wi_address_t *			wi_host_address(wi_host_t *);
WI_EXPORT wi_array_t *				wi_host_addresses(wi_host_t *);

#endif /* WI_HOST_H */
