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

#include <stdlib.h>
#include <stdarg.h>
#include <stdio.h>
#include <unistd.h>
#include <string.h>
#include <errno.h>
#include <pwd.h>
#include <grp.h>
#include <netdb.h>

#include <wired/wi-array.h>
#include <wired/wi-compat.h>
#include <wired/wi-date.h>
#include <wired/wi-file.h>
#include <wired/wi-log.h>
#include <wired/wi-private.h>
#include <wired/wi-settings.h>
#include <wired/wi-string.h>
#include <wired/wi-system.h>
#include <wired/wi-regexp.h>
#include <wired/wi-runtime.h>

struct _wi_settings {
	wi_runtime_base_t				base;
	
	wi_settings_spec_t				*spec;
	wi_uinteger_t					count;
	
	wi_string_t						*file;
	wi_uinteger_t					line;
};


static wi_boolean_t					_wi_settings_parse_setting(wi_settings_t *, wi_string_t *);
static wi_boolean_t					_wi_settings_set_value(wi_settings_t *, wi_string_t *, wi_string_t *);
static wi_uinteger_t				_wi_settings_index_of_name(wi_settings_t *, wi_string_t *);
static void							_wi_settings_log_error(wi_settings_t *, wi_string_t *);

static wi_boolean_t					_wi_settings_set_bool(wi_settings_t *, wi_uinteger_t, wi_string_t *, wi_string_t *);
static wi_boolean_t					_wi_settings_set_number(wi_settings_t *, wi_uinteger_t, wi_string_t *, wi_string_t *);
static wi_boolean_t					_wi_settings_set_string(wi_settings_t *, wi_uinteger_t, wi_string_t *, wi_string_t *);
static wi_boolean_t					_wi_settings_set_string_array(wi_settings_t *, wi_uinteger_t, wi_string_t *, wi_string_t *);
static wi_boolean_t					_wi_settings_set_path(wi_settings_t *, wi_uinteger_t, wi_string_t *, wi_string_t *);
static wi_boolean_t					_wi_settings_set_user(wi_settings_t *, wi_uinteger_t, wi_string_t *, wi_string_t *);
static wi_boolean_t					_wi_settings_set_group(wi_settings_t *, wi_uinteger_t, wi_string_t *, wi_string_t *);
static wi_boolean_t					_wi_settings_set_port(wi_settings_t *, wi_uinteger_t, wi_string_t *, wi_string_t *);
static wi_boolean_t					_wi_settings_set_regexp(wi_settings_t *, wi_uinteger_t, wi_string_t *, wi_string_t *);
static wi_boolean_t					_wi_settings_set_time_interval(wi_settings_t *, wi_uinteger_t, wi_string_t *, wi_string_t *);

static void							_wi_settings_clear(wi_settings_t *);
static void							_wi_settings_clear_bool(wi_settings_t *, wi_uinteger_t);
static void							_wi_settings_clear_number(wi_settings_t *, wi_uinteger_t);
static void							_wi_settings_clear_string(wi_settings_t *, wi_uinteger_t);
static void							_wi_settings_clear_string_array(wi_settings_t *, wi_uinteger_t);
static void							_wi_settings_clear_user(wi_settings_t *, wi_uinteger_t);
static void							_wi_settings_clear_group(wi_settings_t *, wi_uinteger_t);
static void							_wi_settings_clear_regexp(wi_settings_t *, wi_uinteger_t);
static void							_wi_settings_clear_time_interval(wi_settings_t *, wi_uinteger_t);


wi_string_t							*wi_settings_config_path = NULL;

static wi_runtime_id_t				_wi_settings_runtime_id = WI_RUNTIME_ID_NULL;
static wi_runtime_class_t			_wi_settings_runtime_class = {
	"wi_settings_t",
	NULL,
	NULL,
	NULL,
	NULL,
	NULL
};



void wi_settings_register(void) {
	_wi_settings_runtime_id = wi_runtime_register_class(&_wi_settings_runtime_class);
}



void wi_settings_initialize(void) {
}



#pragma mark -

wi_runtime_id_t wi_settings_runtime_id(void) {
	return _wi_settings_runtime_id;
}



#pragma mark -

wi_settings_t * wi_settings_alloc(void) {
	return wi_runtime_create_instance(_wi_settings_runtime_id, sizeof(wi_settings_t));
}



wi_settings_t * wi_settings_init_with_spec(wi_settings_t *settings, wi_settings_spec_t *spec, wi_uinteger_t count) {
	settings->spec = spec;
	settings->count = count;
	
	return settings;
}



#pragma mark -

wi_boolean_t wi_settings_read_file(wi_settings_t *settings) {
	wi_file_t		*file;
	wi_string_t		*string;
	
	file = wi_file_for_reading(wi_settings_config_path);
	
	if(!file) {
		wi_log_error(WI_STR("Could not open %@: %s"),
			wi_settings_config_path, strerror(errno));
		
		return false;
	}
	
	wi_log_info(WI_STR("Reading %@"), wi_settings_config_path);
	_wi_settings_clear(settings);
	
	settings->file		= wi_settings_config_path;
	settings->line		= 0;
	
	while((string = wi_file_read_line(file))) {
		settings->line++;

		if(wi_string_length(string) > 0 && !wi_string_has_prefix(string, WI_STR("#")))
			_wi_settings_parse_setting(settings, string);
	}

	settings->file = NULL;

	return true;
}



#pragma mark -

static wi_boolean_t _wi_settings_parse_setting(wi_settings_t *settings, wi_string_t *string) {
	wi_array_t		*array;
	wi_string_t		*name, *value;
	wi_boolean_t	result = false;
	
	array = wi_string_components_separated_by_string(string, WI_STR("="));
	
	if(wi_array_count(array) != 2) {
		wi_error_set_libwired_error(WI_ERROR_SETTINGS_SYNTAXERROR);
		
		_wi_settings_log_error(settings, string);

		return false;
	}
	
	name	= wi_string_by_deleting_surrounding_whitespace(WI_ARRAY(array, 0));
	value	= wi_string_by_deleting_surrounding_whitespace(WI_ARRAY(array, 1));
	result	= _wi_settings_set_value(settings, name, value);
	
	if(!result)
		_wi_settings_log_error(settings, name);

	return result;
}



static wi_boolean_t _wi_settings_set_value(wi_settings_t *settings, wi_string_t *name, wi_string_t *value) {
	wi_uinteger_t	index;
	wi_boolean_t	result = false;
	
	index = _wi_settings_index_of_name(settings, name);
	
	if(index == WI_NOT_FOUND) {
		wi_error_set_libwired_error(WI_ERROR_SETTINGS_UNKNOWNSETTING);
		
		return false;
	}
	
	wi_log_debug(WI_STR("  %@ = %@"), name, value);
	
	switch(settings->spec[index].type) {
		case WI_SETTINGS_NUMBER:
			result = _wi_settings_set_number(settings, index, name, value);
			break;

		case WI_SETTINGS_BOOL:
			result = _wi_settings_set_bool(settings, index, name, value);
			break;

		case WI_SETTINGS_STRING:
			result = _wi_settings_set_string(settings, index, name, value);
			break;

		case WI_SETTINGS_STRING_ARRAY:
			result = _wi_settings_set_string_array(settings, index, name, value);
			break;

		case WI_SETTINGS_PATH:
			result = _wi_settings_set_path(settings, index, name, value);
			break;

		case WI_SETTINGS_USER:
			result = _wi_settings_set_user(settings, index, name, value);
			break;

		case WI_SETTINGS_GROUP:
			result = _wi_settings_set_group(settings, index, name, value);
			break;

		case WI_SETTINGS_PORT:
			result = _wi_settings_set_port(settings, index, name, value);
			break;
		
		case WI_SETTINGS_REGEXP:
			result = _wi_settings_set_regexp(settings, index, name, value);
			break;
		
		case WI_SETTINGS_TIME_INTERVAL:
			result = _wi_settings_set_time_interval(settings, index, name, value);
			break;
	}
	
	return result;
}



static wi_uinteger_t _wi_settings_index_of_name(wi_settings_t *settings, wi_string_t *name) {
	const char		*cstring;
	wi_uinteger_t	i, min, max;
	int				cmp;

	cstring = wi_string_cstring(name);
	min = 0;
	max = settings->count - 1;

	do {
		i = (min + max) / 2;
		cmp	= strcasecmp(cstring, settings->spec[i].name);

		if(cmp == 0)
			return i;
		else if(cmp < 0 && max > 0)
			max = i - 1;
		else
			min = i + 1;
	} while(min <= max);

	return WI_NOT_FOUND;
}



static void _wi_settings_log_error(wi_settings_t *settings, wi_string_t *name) {
	wi_log_warn(WI_STR("Could not interpret the setting \"%@\" at %@ line %lu: %m"),
		name, settings->file, settings->line);
}



#pragma mark -

wi_boolean_t _wi_settings_set_bool(wi_settings_t *settings, wi_uinteger_t index, wi_string_t *name, wi_string_t *value) {
	*(wi_boolean_t *) settings->spec[index].setting = wi_string_bool(value);
	
	return true;
}



wi_boolean_t _wi_settings_set_number(wi_settings_t *settings, wi_uinteger_t index, wi_string_t *name, wi_string_t *value) {
	*(wi_uinteger_t *) settings->spec[index].setting = wi_string_uint32(value);
	
	return true;
}



wi_boolean_t _wi_settings_set_string(wi_settings_t *settings, wi_uinteger_t index, wi_string_t *name, wi_string_t *value) {
	wi_string_t		**string = (wi_string_t **) settings->spec[index].setting;

	wi_release(*string);
	*string = wi_retain(value);
	
	return true;
}



wi_boolean_t _wi_settings_set_string_array(wi_settings_t *settings, wi_uinteger_t index, wi_string_t *name, wi_string_t *value) {
	wi_mutable_array_t		**array = (wi_mutable_array_t **) settings->spec[index].setting;

	wi_mutable_array_add_data(*array, value);

	return true;
}



wi_boolean_t _wi_settings_set_path(wi_settings_t *settings, wi_uinteger_t index, wi_string_t *name, wi_string_t *value) {
	wi_string_t		**string = (wi_string_t **) settings->spec[index].setting;
	
	if(*string)
		wi_release(*string);

	*string = wi_retain(value);
	
	return true;
}



wi_boolean_t _wi_settings_set_user(wi_settings_t *settings, wi_uinteger_t index, wi_string_t *name, wi_string_t *value) {
	struct passwd		*user;
	uint32_t			uid;
	
	user = getpwnam(wi_string_cstring(value));
	
	if(!user) {
		uid = wi_string_uint32(value);
		
		if(uid != 0 || wi_is_equal(value, WI_STR("0")))
			user = getpwuid(uid);
	}
	
	if(!user) {
		wi_error_set_libwired_error(WI_ERROR_SETTINGS_NOSUCHUSER);
		
		return false;
	}

	*(uid_t *) settings->spec[index].setting = user->pw_uid;
	
	return true;
}



wi_boolean_t _wi_settings_set_group(wi_settings_t *settings, wi_uinteger_t index, wi_string_t *name, wi_string_t *value) {
	struct group		*group;
	uint32_t			gid;
	
	group = getgrnam(wi_string_cstring(value));
	
	if(!group) {
		gid = wi_string_uint32(value);
		
		if(gid != 0 || wi_is_equal(value, WI_STR("0")))
			group = getgrgid(wi_string_uint32(value));
	}

	if(!group) {
		wi_error_set_libwired_error(WI_ERROR_SETTINGS_NOSUCHGROUP);

		return false;
	}

	*(gid_t *) settings->spec[index].setting = group->gr_gid;
	
	return true;
}



static wi_boolean_t _wi_settings_set_port(wi_settings_t *settings, wi_uinteger_t index, wi_string_t *name, wi_string_t *value) {
	struct servent		*servent;
	wi_uinteger_t		port;
	
	port = wi_string_uinteger(value);
	
	if(port > 65535) {
		wi_error_set_libwired_error(WI_ERROR_SETTINGS_INVALIDPORT);
		
		return false;
	}
	
	if(port == 0) {
		servent = getservbyname(wi_string_cstring(value), "tcp");
		
		if(!servent) {
			wi_error_set_libwired_error(WI_ERROR_SETTINGS_NOSUCHSERVICE);

			return false;
		}
		
		port = servent->s_port;
	}
	
	*(wi_uinteger_t *) settings->spec[index].setting = port;
	
	return true;
}



wi_boolean_t _wi_settings_set_regexp(wi_settings_t *settings, wi_uinteger_t index, wi_string_t *name, wi_string_t *value) {
	wi_regexp_t		**regexp = (wi_regexp_t **) settings->spec[index].setting;
	
	*regexp = wi_regexp_init_with_string(wi_regexp_alloc(), value);

	return (*regexp != NULL);
}



wi_boolean_t _wi_settings_set_time_interval(wi_settings_t *settings, wi_uinteger_t index, wi_string_t *name, wi_string_t *value) {
	*(wi_time_interval_t *) settings->spec[index].setting = wi_string_double(value);
	
	return true;
}



#pragma mark -

static void _wi_settings_clear(wi_settings_t *settings) {
	wi_uinteger_t	i;
	
	for(i = 0; i < settings->count; i++) {
		switch(settings->spec[i].type) {
			case WI_SETTINGS_NUMBER:
			case WI_SETTINGS_PORT:
				_wi_settings_clear_number(settings, i);
				break;
				
			case WI_SETTINGS_BOOL:
				_wi_settings_clear_bool(settings, i);
				break;
				
			case WI_SETTINGS_STRING:
			case WI_SETTINGS_PATH:
				_wi_settings_clear_string(settings, i);
				break;
				
			case WI_SETTINGS_STRING_ARRAY:
				_wi_settings_clear_string_array(settings, i);
				break;
				
			case WI_SETTINGS_USER:
				_wi_settings_clear_user(settings, i);
				break;
				
			case WI_SETTINGS_GROUP:
				_wi_settings_clear_group(settings, i);
				break;
				
			case WI_SETTINGS_REGEXP:
				_wi_settings_clear_regexp(settings, i);
				break;
				
			case WI_SETTINGS_TIME_INTERVAL:
				_wi_settings_clear_time_interval(settings, i);
				break;
		}
	}
}



static void _wi_settings_clear_bool(wi_settings_t *settings, wi_uinteger_t index) {
	*(wi_boolean_t *) settings->spec[index].setting = false;
}



static void _wi_settings_clear_number(wi_settings_t *settings, wi_uinteger_t index) {
	*(wi_uinteger_t *) settings->spec[index].setting = 0;
}



static void _wi_settings_clear_string(wi_settings_t *settings, wi_uinteger_t index) {
	wi_string_t		**string = (wi_string_t **) settings->spec[index].setting;
				
	wi_release(*string);
	*string = NULL;
}



static void _wi_settings_clear_string_array(wi_settings_t *settings, wi_uinteger_t index) {
	wi_mutable_array_t		**array = (wi_mutable_array_t **) settings->spec[index].setting;
		
	wi_release(*array);
	*array = wi_array_init(wi_mutable_array_alloc());
}



static void _wi_settings_clear_user(wi_settings_t *settings, wi_uinteger_t index) {
	*(uid_t *) settings->spec[index].setting = geteuid();
}



static void _wi_settings_clear_group(wi_settings_t *settings, wi_uinteger_t index) {
	*(gid_t *) settings->spec[index].setting = getegid();
}



static void _wi_settings_clear_regexp(wi_settings_t *settings, wi_uinteger_t index) {
	wi_regexp_t		**regexp = (wi_regexp_t **) settings->spec[index].setting;
		
	wi_release(*regexp);
	*regexp = NULL;
}



static void _wi_settings_clear_time_interval(wi_settings_t *settings, wi_uinteger_t index) {
	*(wi_time_interval_t *) settings->spec[index].setting = 0.0;
}
