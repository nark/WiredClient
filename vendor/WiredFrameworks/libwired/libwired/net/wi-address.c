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

#include "config.h"

#include <sys/param.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <netdb.h>
#include <net/if.h>
#include <netinet/in.h>
#include <netinet/tcp.h>
#include <arpa/inet.h>
#include <errno.h>

#ifdef HAVE_IFADDRS_H
#include <ifaddrs.h>
#endif

#include <wired/wi-address.h>
#include <wired/wi-compat.h>
#include <wired/wi-private.h>
#include <wired/wi-runtime.h>
#include <wired/wi-string.h>

#ifndef SA_LEN  
#ifdef HAVE_STRUCT_SOCKADDR_SA_LEN  
#define SA_LEN(sa)						((sa)->sa_len)  
#else
static size_t sa_len(const struct sockaddr *sa) {  
	switch(sa->sa_family) {  
		case AF_INET:  
			return sizeof(struct sockaddr_in);
			break;
	                 
		case AF_INET6:
			return sizeof(struct sockaddr_in6);
			break;

		default:
			return sizeof(struct sockaddr);
			break;
	}  
}
#define SA_LEN(sa)						(sa_len(sa))
#endif 
#endif


struct _wi_address {
	wi_runtime_base_t					base;
	
	struct sockaddr_storage				ss;
};


static wi_runtime_instance_t *			_wi_address_copy(wi_runtime_instance_t *);
static wi_boolean_t						_wi_address_is_equal(wi_runtime_instance_t *, wi_runtime_instance_t *);
static wi_string_t *					_wi_address_description(wi_runtime_instance_t *);
static wi_hash_code_t					_wi_address_hash(wi_runtime_instance_t *);


static wi_runtime_id_t					_wi_address_runtime_id = WI_RUNTIME_ID_NULL;
static wi_runtime_class_t				_wi_address_runtime_class = {
	"wi_address_t",
	NULL,
	_wi_address_copy,
	_wi_address_is_equal,
	_wi_address_description,
	_wi_address_hash
};



void wi_address_register(void) {
	_wi_address_runtime_id = wi_runtime_register_class(&_wi_address_runtime_class);
}



void wi_address_initialize(void) {
}



#pragma mark -

wi_runtime_id_t wi_address_runtime_id(void) {
	return _wi_address_runtime_id;
}



#pragma mark -

wi_address_t * wi_address_wildcard_for_family(wi_address_family_t family) {
	return wi_autorelease(wi_address_init_wildcard_for_family(wi_address_alloc(), family));
}



#pragma mark -

wi_address_t * wi_address_alloc(void) {
	return wi_runtime_create_instance(_wi_address_runtime_id, sizeof(wi_address_t));
}



wi_address_t * wi_address_init_with_sa(wi_address_t *address, struct sockaddr *sa) {
	if(sa->sa_family != AF_INET && sa->sa_family != AF_INET6) {
		wi_error_set_error(WI_ERROR_DOMAIN_GAI, EAI_FAMILY);
		
		wi_release(address);
		
		return NULL;
	}
	
	memcpy(&address->ss, sa, SA_LEN(sa));

	return address;
}



wi_address_t * wi_address_init_wildcard_for_family(wi_address_t *address, wi_address_family_t family) {
	struct sockaddr_in      sa;
	struct sockaddr_in6     sa6;

	switch(family) {
		case WI_ADDRESS_IPV4:
			memset(&sa, 0, sizeof(sa));
			sa.sin_family       = AF_INET;
			sa.sin_addr.s_addr  = INADDR_ANY;
#ifdef HAVE_STRUCT_SOCKADDR_IN_SIN_LEN
			sa.sin_len          = sizeof(sa);
#endif

			return wi_address_init_with_sa(address, (struct sockaddr *) &sa);
			break;

		case WI_ADDRESS_IPV6:
			memset(&sa6, 0, sizeof(sa6));
			sa6.sin6_family     = AF_INET6;
			sa6.sin6_addr       = in6addr_any;
#ifdef HAVE_STRUCT_SOCKADDR_IN6_SIN6_LEN
			sa6.sin6_len        = sizeof(sa6);
#endif

			return wi_address_init_with_sa(address, (struct sockaddr *) &sa6);
			break;

		default:
			break;
	}

	return NULL;
}



wi_address_t * wi_address_init_with_ipv4_address(wi_address_t *address, uint32_t ipv4_address) {
	struct sockaddr_in      sa;

	memset(&sa, 0, sizeof(sa));
	sa.sin_family       = AF_INET;
	sa.sin_addr.s_addr  = ipv4_address;
#ifdef HAVE_STRUCT_SOCKADDR_IN_SIN_LEN
	sa.sin_len          = sizeof(sa);
#endif
	
	return wi_address_init_with_sa(address, (struct sockaddr *) &sa);
}



static wi_runtime_instance_t * _wi_address_copy(wi_runtime_instance_t *instance) {
	wi_address_t		*address = instance;
	
	return wi_address_init_with_sa(wi_address_alloc(), (struct sockaddr *) &address->ss);
}



static wi_boolean_t _wi_address_is_equal(wi_runtime_instance_t *instance1, wi_runtime_instance_t *instance2) {
	wi_address_t		*address1 = instance1;
	wi_address_t		*address2 = instance2;
	
	return wi_is_equal(wi_address_string(address1), wi_address_string(address2));
}



static wi_string_t * _wi_address_description(wi_runtime_instance_t *instance) {
	wi_address_t			*address = instance;
	wi_string_t				*family;
	
	switch(wi_address_family(address)) {
		case WI_ADDRESS_IPV4:
			family = WI_STR("ipv4");
			break;

		case WI_ADDRESS_IPV6:
			family = WI_STR("ipv6");
			break;

		case WI_ADDRESS_NULL:
		default:
			family = WI_STR("none");
			break;
	}
	
	return wi_string_with_format(WI_STR("<%@ %p>{family = %@, address = %@, port = %lu}"),
	   wi_runtime_class_name(address),
	   address,
	   family,
	   wi_address_string(address),
	   wi_address_port(address));
}



static wi_hash_code_t _wi_address_hash(wi_runtime_instance_t *instance) {
	wi_address_t		*address = instance;
	
	return wi_hash(wi_address_string(address));
}



#pragma mark -

wi_integer_t wi_address_compare_family(wi_runtime_instance_t *instance1, wi_runtime_instance_t *instance2) {
	wi_address_t			*address1 = instance1;
	wi_address_t			*address2 = instance2;
	wi_address_family_t		family1;
	wi_address_family_t		family2;
	
	family1 = wi_address_family(address1);
	family2 = wi_address_family(address2);
	
	if(family1 == WI_ADDRESS_IPV4 && family2 == WI_ADDRESS_IPV6)
		return 1;
	else if(family1 == WI_ADDRESS_IPV6 && family2 == WI_ADDRESS_IPV4)
		return -1;
	
	return 0;
}



struct sockaddr * wi_address_sa(wi_address_t *address) {
	return (struct sockaddr *) &address->ss;
}



wi_uinteger_t wi_address_sa_length(wi_address_t *address) {
	return SA_LEN((struct sockaddr *) &address->ss);
}



wi_address_family_t wi_address_family(wi_address_t *address) {
	return (wi_address_family_t) address->ss.ss_family;
}



#pragma mark -

void wi_address_set_port(wi_address_t *address, wi_uinteger_t port) {
	if(address->ss.ss_family == AF_INET)
		((struct sockaddr_in *) &address->ss)->sin_port = htons(port);
	else if(address->ss.ss_family == AF_INET6)
		((struct sockaddr_in6 *) &address->ss)->sin6_port = htons(port);
}



wi_uinteger_t wi_address_port(wi_address_t *address) {
	if(address->ss.ss_family == AF_INET)
		return ntohs(((struct sockaddr_in *) &address->ss)->sin_port);
	else if(address->ss.ss_family == AF_INET6)
		return ntohs(((struct sockaddr_in6 *) &address->ss)->sin6_port);
	
	return 0;
}



#pragma mark -

wi_string_t * wi_address_string(wi_address_t *address) {
	char	string[NI_MAXHOST];
	int		err;
	
	err = getnameinfo(wi_address_sa(address), wi_address_sa_length(address), string, sizeof(string), NULL, 0, NI_NUMERICHOST);
	
	if(err != 0) {
		wi_error_set_error(WI_ERROR_DOMAIN_GAI, err);
		
		return NULL;
	}

	return wi_string_with_cstring(string);
}



wi_string_t * wi_address_hostname(wi_address_t *address) {
	char	string[NI_MAXHOST];
	int		err;
	
	err = getnameinfo(wi_address_sa(address), wi_address_sa_length(address), string, sizeof(string), NULL, 0, NI_NAMEREQD);
	
	if(err != 0) {
		wi_error_set_error(WI_ERROR_DOMAIN_GAI, err);
		
		return NULL;
	}

	return wi_string_with_cstring(string);
}
