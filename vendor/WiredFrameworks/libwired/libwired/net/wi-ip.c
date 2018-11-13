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

#include <sys/types.h>
#include <sys/socket.h>
#include <stdlib.h>
#include <stdio.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <string.h>
#include <math.h>

#include <wired/wi-array.h>
#include <wired/wi-compat.h>
#include <wired/wi-ip.h>
#include <wired/wi-string.h>

static wi_boolean_t				_wi_ipv4_match_wildcard(wi_string_t *, wi_string_t *);
static wi_boolean_t				_wi_ipv4_match_netmask(wi_string_t *, wi_string_t *);
static wi_boolean_t				_wi_ipv4_match_literal(wi_string_t *, wi_string_t *);
static wi_boolean_t				_wi_ipv6_match_literal(wi_string_t *, wi_string_t *);

static uint32_t					_wi_ipv4_uint32(wi_string_t *);
static wi_string_t *			_wi_ipv6_expanded_value(wi_string_t *);



wi_ip_version_t wi_ip_version(wi_string_t *ip) {
	struct sockaddr_in		sa_in;
	struct sockaddr_in6		sa_in6;

	if(wi_string_contains_string(ip, WI_STR("."), 0)) {
		if(inet_pton(AF_INET, wi_string_cstring(ip), &sa_in.sin_addr) > 0)
			return WI_IP_IPV4;
	}
	else if(wi_string_contains_string(ip, WI_STR(":"), 0)) {
		if(inet_pton(AF_INET6, wi_string_cstring(ip), &sa_in6.sin6_addr) > 0)
			return WI_IP_IPV6;
	}

	return WI_IP_NULL;
}



#pragma mark -

wi_boolean_t wi_ip_matches_string(wi_string_t *ip, wi_string_t *pattern) {
	switch(wi_ip_version(ip)) {
		case WI_IP_IPV4:
			if(wi_string_contains_string(pattern, WI_STR("*"), 0))
				return _wi_ipv4_match_wildcard(ip, pattern);
			else if(wi_string_contains_string(pattern, WI_STR("/"), 0))
				return _wi_ipv4_match_netmask(ip, pattern);
			else
				return _wi_ipv4_match_literal(ip, pattern);
			break;

		case WI_IP_IPV6:
			return _wi_ipv6_match_literal(ip, pattern);
			break;
			
		case WI_IP_NULL:
		default:
			return false;
			break;
	}
}



static wi_boolean_t _wi_ipv4_match_wildcard(wi_string_t *ip, wi_string_t *pattern) {
	wi_array_t		*ip_octets, *pattern_octets;
	wi_string_t		*ip_octet, *pattern_octet;
	wi_uinteger_t	i, count;
	
	count			= 0;
	ip_octets		= wi_string_components_separated_by_string(ip, WI_STR("."));
	pattern_octets	= wi_string_components_separated_by_string(pattern, WI_STR("."));
	
	if(wi_array_count(ip_octets) != 4)
		return false;
	
	if(wi_array_count(ip_octets) != wi_array_count(pattern_octets))
		return false;
	
	for(i = 0; i < 4; i++) {
		ip_octet		= WI_ARRAY(ip_octets, i);
		pattern_octet	= WI_ARRAY(pattern_octets, i);
		
		if(wi_is_equal(ip_octet, pattern_octet) || wi_is_equal(pattern_octet, WI_STR("*")))
			count++;
	}
	
	return (count == 4);
}



static wi_boolean_t _wi_ipv4_match_netmask(wi_string_t *ip, wi_string_t *pattern) {
	wi_string_t		*pattern_ip, *pattern_netmask;
	wi_array_t		*array;
	uint32_t		cidr, netmask;
	
	array = wi_string_components_separated_by_string(pattern, WI_STR("/"));
	
	if(wi_array_count(array) != 2)
		return false;
	
	pattern_ip		= WI_ARRAY(array, 0);
	pattern_netmask	= WI_ARRAY(array, 1);
	
	if(wi_string_contains_string(pattern_netmask, WI_STR("."), 0)) {
		netmask = _wi_ipv4_uint32(pattern_netmask);
	} else {
		cidr	= wi_string_uint32(pattern_netmask);
		netmask	= pow(2.0, 32.0) - pow(2.0, 32.0 - cidr);
	}
	
	return ((_wi_ipv4_uint32(ip) & netmask) ==
			(_wi_ipv4_uint32(pattern_ip) & netmask));
}



static wi_boolean_t _wi_ipv4_match_literal(wi_string_t *ip, wi_string_t *pattern) {
	return wi_is_equal(ip, pattern);
}



static wi_boolean_t _wi_ipv6_match_literal(wi_string_t *ip, wi_string_t *pattern) {
	wi_string_t		*ip_expanded, *pattern_expanded;
	
	ip_expanded			= _wi_ipv6_expanded_value(ip);
	pattern_expanded	= _wi_ipv6_expanded_value(pattern);
	
	return (ip_expanded && pattern_expanded && wi_is_equal(ip_expanded, pattern_expanded));
}



#pragma mark -

static uint32_t _wi_ipv4_uint32(wi_string_t *ip) {
	const char		*cstring;
	uint32_t		a, b, c, d;
	
	cstring = wi_string_cstring(ip);

	if(sscanf(cstring, "%u.%u.%u.%u", &a, &b, &c, &d) == 4)
		return (a << 24) + (b << 16) + (c << 8) + d;

	return 0;
}



static wi_string_t * _wi_ipv6_expanded_value(wi_string_t *ip) {
	wi_mutable_array_t		*octets;
	wi_mutable_string_t		*octet;
	wi_uinteger_t			i, count;
	
	octets		= wi_autorelease(wi_mutable_copy(wi_string_components_separated_by_string(ip, WI_STR(":"))));
	count		= wi_array_count(octets);
	
	if(count < 3)
		return NULL;
	
	while(count > 0 && wi_string_length(WI_ARRAY(octets, 0)) == 0) {
		wi_mutable_array_remove_data_at_index(octets, 0);
		count--;
	}
	
	for(i = 0; i < count; i++) {
		octet = wi_mutable_copy(WI_ARRAY(octets, i));
		
		while(wi_string_length(octet) < 4)
			wi_mutable_string_insert_string_at_index(octet, WI_STR("0"), 0);
		
		wi_mutable_array_replace_data_at_index(octets, octet, i);
		wi_release(octet);
	}
	
	while(count < 8) {
		if(count == 0)
			wi_mutable_array_add_data(octets, WI_STR("0000"));
		else
			wi_mutable_array_insert_data_at_index(octets, WI_STR("0000"), 0);

		count++;
	}
	
	return wi_array_components_joined_by_string(octets, WI_STR(":"));
}
