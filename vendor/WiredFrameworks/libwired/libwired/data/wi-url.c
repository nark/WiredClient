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
#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <string.h>

#include <wired/wi-compat.h>
#include <wired/wi-macros.h>
#include <wired/wi-private.h>
#include <wired/wi-runtime.h>
#include <wired/wi-string.h>
#include <wired/wi-url.h>

struct _wi_url {
	wi_runtime_base_t					base;
	
	wi_string_t							*scheme;
	wi_string_t							*host;
	wi_uinteger_t						port;
	wi_string_t							*path;
	wi_string_t							*user;
	wi_string_t							*password;
	
	wi_mutable_string_t					*string;
};


static void								_wi_url_dealloc(wi_runtime_instance_t *);
static wi_runtime_instance_t *			_wi_url_copy(wi_runtime_instance_t *);
static wi_boolean_t						_wi_url_is_equal(wi_runtime_instance_t *, wi_runtime_instance_t *);
static wi_string_t *					_wi_url_description(wi_runtime_instance_t *);
static wi_hash_code_t					_wi_url_hash(wi_runtime_instance_t *);

static void								_wi_url_regenerate_string(wi_url_t *);


static wi_runtime_id_t					_wi_url_runtime_id = WI_RUNTIME_ID_NULL;
static wi_runtime_class_t				_wi_url_runtime_class = {
	"wi_url_t",
	_wi_url_dealloc,
	_wi_url_copy,
	_wi_url_is_equal,
	_wi_url_description,
	_wi_url_hash
};



void wi_url_register(void) {
	_wi_url_runtime_id = wi_runtime_register_class(&_wi_url_runtime_class);
}



void wi_url_initialize(void) {
}



#pragma mark -

wi_runtime_id_t wi_url_runtime_id(void) {
	return _wi_url_runtime_id;
}



#pragma mark -

wi_url_t * wi_url_with_string(wi_string_t *string) {
	return wi_autorelease(wi_url_init_with_string(wi_url_alloc(), string));
}



#pragma mark -

wi_url_t * wi_url_alloc(void) {
	return wi_runtime_create_instance_with_options(_wi_url_runtime_id, sizeof(wi_url_t), WI_RUNTIME_OPTION_IMMUTABLE);
}



wi_mutable_url_t * wi_mutable_url_alloc(void) {
	return wi_runtime_create_instance_with_options(_wi_url_runtime_id, sizeof(wi_url_t), WI_RUNTIME_OPTION_MUTABLE);
}



wi_url_t * wi_url_init(wi_url_t *url) {
	return url;
}



wi_url_t * wi_url_init_with_string(wi_url_t *url, wi_string_t *string) {
	wi_string_t		*userpassword;
	wi_range_t		range;
	
	range = wi_string_range_of_string(string, WI_STR("://"), 0);
	
	if(range.location != WI_NOT_FOUND) {
		url->scheme = wi_retain(wi_string_substring_to_index(string, range.location));
		
		if(range.location + range.length >= wi_string_length(string))
			goto end;
		else
			string = wi_string_substring_from_index(string, range.location + 3);
	}
	
	range = wi_string_range_of_string(string, WI_STR("/"), 0);
	
	if(range.location != WI_NOT_FOUND) {
		url->path	= wi_retain(wi_string_substring_from_index(string, range.location));
		string		= wi_string_substring_to_index(string, range.location);
	}
	
	range = wi_string_range_of_string(string, WI_STR("@"), 0);
	
	if(range.location != WI_NOT_FOUND) {
		userpassword = wi_string_substring_to_index(string, range.location);
		string = wi_string_substring_from_index(string, range.location + 1);

		range = wi_string_range_of_string(userpassword, WI_STR(":"), 0);
		
		if(range.location != WI_NOT_FOUND && range.location != wi_string_length(userpassword) - 1) {
			url->user = wi_retain(wi_string_substring_to_index(userpassword, range.location));
			url->password = wi_retain(wi_string_substring_from_index(userpassword, range.location + 1));
		} else {
			url->user = wi_retain(userpassword);
		}
	}
	
	if(wi_string_has_prefix(string, WI_STR("["))) {
		range = wi_string_range_of_string(string, WI_STR("]"), 0);
		
		if(range.location != WI_NOT_FOUND) {
			url->host = wi_retain(wi_string_substring_with_range(string, wi_make_range(1, range.location - 1)));
			string = wi_string_substring_from_index(string, range.location + 1);
			
			if(wi_string_has_prefix(string, WI_STR(":")) && wi_string_length(string) > 1)
				url->port = wi_string_uint32(wi_string_substring_from_index(string, 1));
		} else {
			url->host = wi_copy(string);
		}
	} else {
		range = wi_string_range_of_string(string, WI_STR(":"), 0);
		
		if(range.location == WI_NOT_FOUND ||
		   range.location + range.length >= wi_string_length(string) ||
		   wi_string_contains_string(wi_string_substring_from_index(string, range.location + 1), WI_STR(":"), 0)) {
			url->host = wi_copy(string);
		} else {
			url->host = wi_retain(wi_string_substring_to_index(string, range.location));
			url->port = wi_string_uint32(wi_string_substring_from_index(string, range.location + 1));
		}
	}
	
end:
	_wi_url_regenerate_string(url);
	
	return url;
}



static void _wi_url_dealloc(wi_runtime_instance_t *instance) {
	wi_url_t		*url = instance;
	
	wi_release(url->scheme);
	wi_release(url->host);
	wi_release(url->path);
	wi_release(url->user);
	wi_release(url->password);

	wi_release(url->string);
}



static wi_runtime_instance_t * _wi_url_copy(wi_runtime_instance_t *instance) {
	wi_mutable_url_t		*url_copy;
	wi_url_t				*url = instance;
	
	url_copy = wi_url_init(wi_mutable_url_alloc());
	
	if(url->scheme)
		wi_mutable_url_set_scheme(url_copy, url->scheme);
	
	if(url->host)
		wi_mutable_url_set_host(url_copy, url->host);

	if(url->port > 0)
		wi_mutable_url_set_port(url_copy, url->port);
	
	if(url->path)
		wi_mutable_url_set_path(url_copy, url->path);
	
	if(url->user)
		wi_mutable_url_set_user(url_copy, url->user);
	
	if(url->password)
		wi_mutable_url_set_password(url_copy, url->password);
	
	return url_copy;
}



static wi_boolean_t _wi_url_is_equal(wi_runtime_instance_t *instance1, wi_runtime_instance_t *instance2) {
	wi_url_t		*url1 = instance1;
	wi_url_t		*url2 = instance2;
	
	return (wi_is_equal(url1->string, url2->string));
}



static wi_string_t * _wi_url_description(wi_runtime_instance_t *instance) {
	wi_url_t		*url = instance;
	
	return wi_url_string(url);
}



static wi_hash_code_t _wi_url_hash(wi_runtime_instance_t *instance) {
	wi_url_t		*url = instance;
	
	return wi_hash(url->string);
}



#pragma mark -

void _wi_url_regenerate_string(wi_url_t *url) {
	wi_release(url->string);
	
	url->string = wi_string_init_with_format(wi_mutable_string_alloc(), WI_STR("%#@://"), url->scheme);
	
	if(url->user && wi_string_length(url->user) > 0) {
		wi_mutable_string_append_format(url->string, WI_STR("%#@"), url->user);
		
		if(url->password && wi_string_length(url->password) > 0)
			wi_mutable_string_append_format(url->string, WI_STR(":%#@"), url->password);
	
		wi_mutable_string_append_string(url->string, WI_STR("@"));
	}
	wi_mutable_string_append_format(url->string, WI_STR("%#@"), url->host);
	
	if(url->port > 0)
		wi_mutable_string_append_format(url->string, WI_STR(":%lu"), url->port);
	
	if(url->path)
		wi_mutable_string_append_string(url->string, url->path);
	else
		wi_mutable_string_append_string(url->string, WI_STR("/"));
}



#pragma mark -

wi_string_t * wi_url_scheme(wi_url_t *url) {
	return url->scheme;
}



wi_string_t * wi_url_host(wi_url_t *url) {
	return url->host;
}



wi_uinteger_t wi_url_port(wi_url_t *url) {
	return url->port;
}



wi_string_t * wi_url_path(wi_url_t *url) {
	return url->path;
}



wi_string_t * wi_url_user(wi_url_t *url) {
	return url->user;
}



wi_string_t * wi_url_password(wi_url_t *url) {
	return url->password;
}



#pragma mark -

wi_boolean_t wi_url_is_valid(wi_url_t *url) {
	return (url->scheme && url->host);
}



wi_string_t * wi_url_string(wi_url_t *url) {
	return url->string;
}



#pragma mark -

void wi_mutable_url_set_scheme(wi_mutable_url_t *url, wi_string_t *scheme) {
	WI_RUNTIME_ASSERT_MUTABLE(url);
	
	wi_retain(scheme);
	wi_release(url->scheme);
	
	url->scheme = scheme;
	
	_wi_url_regenerate_string(url);
}



void wi_mutable_url_set_host(wi_mutable_url_t *url, wi_string_t *host) {
	WI_RUNTIME_ASSERT_MUTABLE(url);
	
	wi_retain(host);
	wi_release(url->host);
	
	url->host = host;
	
	_wi_url_regenerate_string(url);
}



void wi_mutable_url_set_port(wi_mutable_url_t *url, wi_uinteger_t port) {
	WI_RUNTIME_ASSERT_MUTABLE(url);
	
	url->port = port;
	
	_wi_url_regenerate_string(url);
}



void wi_mutable_url_set_path(wi_mutable_url_t *url, wi_string_t *path) {
	WI_RUNTIME_ASSERT_MUTABLE(url);
	
	wi_retain(path);
	wi_release(url->path);
	
	url->path = path;
	
	_wi_url_regenerate_string(url);
}



void wi_mutable_url_set_user(wi_mutable_url_t *url, wi_string_t *user) {
	WI_RUNTIME_ASSERT_MUTABLE(url);
	
	wi_retain(user);
	wi_release(url->user);
	
	url->user = user;
	
	_wi_url_regenerate_string(url);
}



void wi_mutable_url_set_password(wi_mutable_url_t *url, wi_string_t *password) {
	WI_RUNTIME_ASSERT_MUTABLE(url);
	
	wi_retain(password);
	wi_release(url->password);
	
	url->password = password;
	
	_wi_url_regenerate_string(url);
}
