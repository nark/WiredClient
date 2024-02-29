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
#include <wired/wi-array.h>
#include <wired/wi-host.h>
#include <wired/wi-pool.h>
#include <wired/wi-private.h>
#include <wired/wi-string.h>

struct _wi_host {
	wi_runtime_base_t					base;
	
	wi_string_t							*string;
};


static void								_wi_host_dealloc(wi_runtime_instance_t *);
static wi_runtime_instance_t *			_wi_host_copy(wi_runtime_instance_t *);
static wi_boolean_t						_wi_host_is_equal(wi_runtime_instance_t *, wi_runtime_instance_t *);
static wi_string_t *					_wi_host_description(wi_runtime_instance_t *);
static wi_hash_code_t					_wi_host_hash(wi_runtime_instance_t *);

static wi_array_t *						_wi_host_addresses_for_interface_string(wi_string_t *);
static wi_array_t *						_wi_host_addresses_for_host_string(wi_string_t *);


static wi_runtime_id_t					_wi_host_runtime_id = WI_RUNTIME_ID_NULL;
static wi_runtime_class_t				_wi_host_runtime_class = {
	"wi_host_t",
	_wi_host_dealloc,
	_wi_host_copy,
	_wi_host_is_equal,
	_wi_host_description,
	_wi_host_hash
};



void wi_host_register(void) {
	_wi_host_runtime_id = wi_runtime_register_class(&_wi_host_runtime_class);
}



void wi_host_initialize(void) {
}



#pragma mark -

wi_runtime_id_t wi_host_runtime_id(void) {
	return _wi_host_runtime_id;
}



#pragma mark -

wi_host_t * wi_host(void) {
	return wi_autorelease(wi_host_init(wi_host_alloc()));
}



wi_host_t * wi_host_with_string(wi_string_t *string) {
	return wi_autorelease(wi_host_init_with_string(wi_host_alloc(), string));
}



#pragma mark -

wi_host_t * wi_host_alloc(void) {
	return wi_runtime_create_instance(_wi_host_runtime_id, sizeof(wi_host_t));
}



wi_host_t * wi_host_init(wi_host_t *host) {
	return host;
}



wi_host_t * wi_host_init_with_string(wi_host_t *host, wi_string_t *string) {
	host->string = wi_retain(string);
	
	return host;
}



static void _wi_host_dealloc(wi_runtime_instance_t *instance) {
	wi_host_t		*host = instance;
	
	wi_release(host->string);
}



static wi_runtime_instance_t * _wi_host_copy(wi_runtime_instance_t *instance) {
	wi_host_t		*host = instance;
	
	return host->string
		? wi_host_init_with_string(wi_host_alloc(), host->string)
		: wi_host_init(wi_host_alloc());
}



static wi_boolean_t _wi_host_is_equal(wi_runtime_instance_t *instance1, wi_runtime_instance_t *instance2) {
	wi_host_t			*host1 = instance1;
	wi_host_t			*host2 = instance2;
	wi_enumerator_t		*enumerator;
	wi_array_t			*addresses1;
	wi_array_t			*addresses2;
	wi_address_t		*address;
	wi_boolean_t		equal = true;

	addresses1 = wi_host_addresses(host1);
	addresses2 = wi_host_addresses(host2);
	
	if(!addresses1 || !addresses2)
		return false;
	
	if(wi_array_count(addresses1) != wi_array_count(addresses2))
		return false;
	
	enumerator = wi_array_data_enumerator(addresses1);
	
	while((address = wi_enumerator_next_data(enumerator))) {
		if(!wi_array_contains_data(addresses2, address)) {
			equal = false;
			
			break;
		}
	}
	
	return equal;
}



static wi_string_t * _wi_host_description(wi_runtime_instance_t *instance) {
	wi_host_t		*host = instance;
	
	return wi_string_with_format(WI_STR("<%@ %p>{addresses = %@}"),
		wi_runtime_class_name(host),
		host,
		wi_host_addresses(host));
}



static wi_hash_code_t _wi_host_hash(wi_runtime_instance_t *instance) {
	wi_host_t		*host = instance;
	
	return wi_hash(wi_host_addresses(host));
}



#pragma mark -

static wi_array_t * _wi_host_addresses_for_interface_string(wi_string_t *string) {
#ifdef HAVE_GETIFADDRS
	wi_mutable_array_t		*array;
	wi_address_t			*address;
	struct ifaddrs			*ifap, *ifp;
	const char				*name;

	if(getifaddrs(&ifap) < 0) {
		wi_error_set_errno(errno);
		
		return NULL;
	}

	array		= wi_array_init(wi_mutable_array_alloc());
	name		= string ? wi_string_cstring(string) : NULL;

	for(ifp = ifap; ifp; ifp = ifp->ifa_next) {
		if(!ifp->ifa_addr)
			continue;
		
		if(ifp->ifa_addr->sa_family != AF_INET && ifp->ifa_addr->sa_family != AF_INET6)
			continue;

		if(!(ifp->ifa_flags & IFF_UP))
			continue;
		
		if(name && strcasecmp(ifp->ifa_name, name) != 0)
			continue;
		
		address = wi_address_init_with_sa(wi_address_alloc(), ifp->ifa_addr);
		wi_mutable_array_add_data(array, address);
		wi_release(address);
	}

	freeifaddrs(ifap);
	
	wi_mutable_array_sort(array, wi_address_compare_family);
	
	if(wi_array_count(array) == 0) {
		wi_error_set_libwired_error(WI_ERROR_HOST_NOAVAILABLEADDRESSES);
		
		wi_release(array);
		array = NULL;
	}
	
	wi_runtime_make_immutable(array);

	return wi_autorelease(array);
#else
	return wi_array_with_data(
		wi_address_wildcard_for_family(WI_ADDRESS_IPV6),
		wi_address_wildcard_for_family(WI_ADDRESS_IPV4),
		NULL);
#endif
}



static wi_array_t * _wi_host_addresses_for_host_string(wi_string_t *string) {
	wi_mutable_array_t		*array;
	wi_address_t			*address;
	struct addrinfo			*aiap, *aip;
	int						err;

	err = getaddrinfo(wi_string_cstring(string), NULL, NULL, &aiap);

	if(err != 0) {
		wi_error_set_error(WI_ERROR_DOMAIN_GAI, err);
		
		return NULL;
	}
	
	array = wi_array_init(wi_mutable_array_alloc());

	for(aip = aiap; aip; aip = aip->ai_next) {
		if(aip->ai_protocol != 0 && aip->ai_protocol != IPPROTO_TCP)
			continue;
		
		if(aip->ai_family != AF_INET && aip->ai_family != AF_INET6)
			continue;

		address = wi_address_init_with_sa(wi_address_alloc(), aip->ai_addr);

		if(!wi_array_contains_data(array, address))
			wi_mutable_array_add_data(array, address);

		wi_release(address);
	}

	freeaddrinfo(aiap);

	wi_mutable_array_sort(array, wi_address_compare_family);
	
	if(wi_array_count(array) == 0) {
		wi_error_set_libwired_error(WI_ERROR_HOST_NOAVAILABLEADDRESSES);
		
		wi_release(array);
		array = NULL;
	}
	
	wi_runtime_make_immutable(array);

	return wi_autorelease(array);
}



#pragma mark -

wi_address_t * wi_host_address(wi_host_t *host) {
	wi_array_t		*addresses;
	
	addresses = wi_host_addresses(host);

	if(!addresses)
		return NULL;
	
	return wi_array_first_data(addresses);
}



wi_array_t * wi_host_addresses(wi_host_t *host) {
	wi_array_t		*addresses;
	
	if(!host->string) {
		addresses = _wi_host_addresses_for_interface_string(NULL);
	} else {
		addresses = _wi_host_addresses_for_host_string(host->string);
		
		if(!addresses && wi_error_domain() == WI_ERROR_DOMAIN_GAI)
			addresses = _wi_host_addresses_for_interface_string(host->string);
	}
	
	return addresses;
}
