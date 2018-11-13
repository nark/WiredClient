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
#include <stdlib.h>
#include <string.h>
#include <regex.h>

#include <wired/wi-assert.h>
#include <wired/wi-compat.h>
#include <wired/wi-private.h>
#include <wired/wi-regexp.h>
#include <wired/wi-runtime.h>
#include <wired/wi-string.h>

struct _wi_regexp {
	wi_runtime_base_t					base;
	
	wi_string_t							*string;
	regex_t								regex;
	wi_boolean_t						compiled;
	
	wi_hash_code_t						hash;
};


static void								_wi_regexp_dealloc(wi_runtime_instance_t *);
static wi_runtime_instance_t *			_wi_regexp_copy(wi_runtime_instance_t *);
static wi_boolean_t						_wi_regexp_is_equal(wi_runtime_instance_t *, wi_runtime_instance_t *);
static wi_string_t *					_wi_regexp_description(wi_runtime_instance_t *);
static wi_hash_code_t					_wi_regexp_hash(wi_runtime_instance_t *);

static wi_boolean_t						_wi_regexp_compile(wi_regexp_t *);


static wi_runtime_id_t					_wi_regexp_runtime_id = WI_RUNTIME_ID_NULL;
static wi_runtime_class_t				_wi_regexp_runtime_class = {
	"wi_regexp_t",
	_wi_regexp_dealloc,
	_wi_regexp_copy,
	_wi_regexp_is_equal,
	_wi_regexp_description,
	_wi_regexp_hash
};



void wi_regexp_register(void) {
	_wi_regexp_runtime_id = wi_runtime_register_class(&_wi_regexp_runtime_class);
}



void wi_regexp_initialize(void) {
}



#pragma mark -

wi_runtime_id_t wi_regexp_runtime_id(void) {
	return _wi_regexp_runtime_id;
}



#pragma mark -

wi_regexp_t * wi_regexp_with_string(wi_string_t *string) {
	return wi_autorelease(wi_regexp_init_with_string(wi_regexp_alloc(), string));
}



#pragma mark -

wi_regexp_t * wi_regexp_alloc(void) {
	return wi_runtime_create_instance(_wi_regexp_runtime_id, sizeof(wi_regexp_t));
}



wi_regexp_t * wi_regexp_init_with_string(wi_regexp_t *regexp, wi_string_t *string) {
	regexp->string = wi_copy(string);
	
	if(!_wi_regexp_compile(regexp)) {
		wi_release(regexp);
		
		return NULL;
	}
	
	return regexp;
}



static void _wi_regexp_dealloc(wi_runtime_instance_t *instance) {
	wi_regexp_t		*regexp = instance;
	
	if(regexp->compiled)
		regfree(&regexp->regex);

	wi_release(regexp->string);
}



static wi_runtime_instance_t * _wi_regexp_copy(wi_runtime_instance_t *instance) {
	wi_regexp_t		*regexp = instance;
	
	return wi_regexp_init_with_string(wi_regexp_alloc(), regexp->string);
}



static wi_boolean_t _wi_regexp_is_equal(wi_runtime_instance_t *instance1, wi_runtime_instance_t *instance2) {
	wi_regexp_t		*regexp1 = instance1;
	wi_regexp_t		*regexp2 = instance2;

	return wi_is_equal(regexp1->string, regexp2->string);
}



static wi_string_t * _wi_regexp_description(wi_runtime_instance_t *instance) {
	wi_regexp_t		*regexp = instance;
	
	return regexp->string;
}



static wi_hash_code_t _wi_regexp_hash(wi_runtime_instance_t *instance) {
	wi_regexp_t		*regexp = instance;
	
	if(regexp->hash == 0)
		regexp->hash = wi_hash(regexp->string);
	
	return regexp->hash;
}



#pragma mark -

static wi_boolean_t _wi_regexp_compile(wi_regexp_t *regexp) {
	const char		*cstring;
	char			*p, *s = NULL, *ss;
	int				options, err;
	wi_boolean_t	result = false;
	
	cstring = wi_string_cstring(regexp->string);

	if(cstring[0] != '/') {
		wi_error_set_error(WI_ERROR_DOMAIN_LIBWIRED, WI_ERROR_REGEXP_NOSLASH);

		goto end;
	}
	
	s = ss = strdup(cstring);
	ss++;

	if(!(p = strrchr(ss, '/'))) {
		wi_error_set_error(WI_ERROR_DOMAIN_LIBWIRED, WI_ERROR_REGEXP_NOSLASH);

		goto end;
	}

	*p = '\0';
	options = REG_EXTENDED;

	while(*++p) {
		switch(*p) {
			case 'i':
				options |= REG_ICASE;
				break;

			case 'm':
				options |= REG_NEWLINE;
				break;

			default:
				wi_error_set_error(WI_ERROR_DOMAIN_LIBWIRED, WI_ERROR_REGEXP_INVALIDOPTION);

				goto end;
				break;
		}
	}

	err = regcomp(&regexp->regex, ss, options);

	if(err != 0) {
		wi_error_set_regex_error(&regexp->regex, err);
		
		goto end;
	}

	result = true;
	regexp->compiled = true;

end:
	if(s)
		free(s);

	return result;
}



#pragma mark -

wi_string_t * wi_regexp_string(wi_regexp_t *regexp) {
	return regexp->string;
}



#pragma mark -

wi_boolean_t wi_regexp_matches_string(wi_regexp_t *regexp, wi_string_t *string) {
	return wi_regexp_matches_cstring(regexp, wi_string_cstring(string));
}



wi_boolean_t wi_regexp_matches_cstring(wi_regexp_t *regexp, const char *cstring) {
	return (regexec(&regexp->regex, cstring, 0, NULL, 0) == 0);
}



wi_string_t * wi_regexp_string_by_matching_string(wi_regexp_t *regexp, wi_string_t *string, wi_uinteger_t index) {
	regmatch_t		matches[32];

	if(index >= 32)
		return NULL;

	memset(matches, 0, sizeof(matches));

	if(regexec(&regexp->regex, wi_string_cstring(string), 32, matches, 0) != 0)
		return NULL;

	return wi_string_substring_with_range(string,
		wi_make_range(matches[index].rm_so, matches[index].rm_eo - matches[index].rm_so));
}
