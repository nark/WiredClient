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

#ifndef WI_ADDRESS_H
#define WI_ADDRESS_H 1

#include <sys/types.h>
#include <sys/param.h>
#include <sys/socket.h>
#include <netdb.h>

#include <wired/wi-base.h>
#include <wired/wi-runtime.h>

enum _wi_address_family {
	WI_ADDRESS_NULL					= AF_UNSPEC,
	WI_ADDRESS_IPV4					= AF_INET,
	WI_ADDRESS_IPV6					= AF_INET6
};
typedef enum _wi_address_family		wi_address_family_t;


WI_EXPORT wi_runtime_id_t			wi_address_runtime_id(void);

WI_EXPORT wi_address_t *			wi_address_wildcard_for_family(wi_address_family_t);

WI_EXPORT wi_address_t *			wi_address_alloc(void);
WI_EXPORT wi_address_t *			wi_address_init_with_sa(wi_address_t *, struct sockaddr *);
WI_EXPORT wi_address_t *			wi_address_init_wildcard_for_family(wi_address_t *, wi_address_family_t);
WI_EXPORT wi_address_t *			wi_address_init_with_ipv4_address(wi_address_t *, uint32_t);

WI_EXPORT wi_integer_t				wi_address_compare_family(wi_runtime_instance_t *, wi_runtime_instance_t *);

WI_EXPORT struct sockaddr *			wi_address_sa(wi_address_t *);
WI_EXPORT wi_uinteger_t				wi_address_sa_length(wi_address_t *);
WI_EXPORT wi_address_family_t		wi_address_family(wi_address_t *);

WI_EXPORT void						wi_address_set_port(wi_address_t *, wi_uinteger_t);
WI_EXPORT wi_uinteger_t				wi_address_port(wi_address_t *);

WI_EXPORT wi_string_t *				wi_address_string(wi_address_t *);
WI_EXPORT wi_string_t *				wi_address_hostname(wi_address_t *);

#endif /* WI_ADDRESS_H */
