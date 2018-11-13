/* $Id$ */

/*
 *  Copyright (c) 2008-2009 Axel Andersson
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

#include <netdb.h>

#include <wired/wi-array.h>
#include <wired/wi-config.h>
#include <wired/wi-dictionary.h>
#include <wired/wi-file.h>
#include <wired/wi-lock.h>
#include <wired/wi-log.h>
#include <wired/wi-number.h>
#include <wired/wi-regexp.h>
#include <wired/wi-string.h>
#include <wired/wi-system.h>
#include <wired/wi-private.h>

struct _wi_config {
	wi_runtime_base_t				base;
	
	wi_lock_t						*lock;
	
	wi_string_t						*path;
	wi_dictionary_t					*types;
	wi_dictionary_t					*defaults;
	wi_uinteger_t					line;
	
	wi_mutable_dictionary_t			*values;
	wi_mutable_set_t				*changes;
};


static void							_wi_config_dealloc(wi_runtime_instance_t *);

static void							_wi_config_log_error(wi_config_t *, wi_string_t *);
static wi_boolean_t					_wi_config_parse_string(wi_config_t *, wi_string_t *, wi_string_t **, wi_string_t **);
static wi_runtime_instance_t *		_wi_config_instance_for_setting(wi_config_t *, wi_string_t *, wi_string_t *, wi_config_type_t *);
static wi_boolean_t					_wi_config_write_setting_to_file(wi_config_t *, wi_string_t *, wi_file_t *);


static wi_runtime_id_t				_wi_config_runtime_id = WI_RUNTIME_ID_NULL;
static wi_runtime_class_t			_wi_config_runtime_class = {
	"wi_config_t",
	_wi_config_dealloc,
	NULL,
	NULL,
	NULL,
	NULL
};



void wi_config_register(void) {
	_wi_config_runtime_id = wi_runtime_register_class(&_wi_config_runtime_class);
}



void wi_config_initialize(void) {
}



#pragma mark -

wi_runtime_id_t wi_config_runtime_id(void) {
	return _wi_config_runtime_id;
}



#pragma mark -

wi_config_t * wi_config_alloc(void) {
	return wi_runtime_create_instance(_wi_config_runtime_id, sizeof(wi_config_t));
}



wi_config_t * wi_config_init_with_path(wi_config_t *config, wi_string_t *path, wi_dictionary_t *types, wi_dictionary_t *defaults) {
	config->lock		= wi_lock_init(wi_lock_alloc());
	config->path		= wi_retain(path);
	config->types		= wi_retain(types);
	config->changes		= wi_set_init(wi_mutable_set_alloc());
	config->defaults	= wi_retain(defaults);
	
	return config;
}



static void _wi_config_dealloc(wi_runtime_instance_t *instance) {
	wi_config_t		*config = instance;
	
	wi_release(config->lock);
	wi_release(config->path);
	wi_release(config->types);
	wi_release(config->changes);
}



#pragma mark -

wi_boolean_t wi_config_read_file(wi_config_t *config) {
	wi_enumerator_t				*enumerator;
	wi_runtime_instance_t		*instance;
	wi_file_t					*file;
	wi_mutable_array_t			*array;
	wi_mutable_dictionary_t		*previous_values;
	wi_string_t					*string, *name, *value;
	wi_config_type_t			type;
	
	file = wi_file_for_reading(config->path);
	
	if(!file) {
		wi_log_error(WI_STR("Could not open %@: %m"),
			config->path);
		
		return false;
	}
	
	wi_log_info(WI_STR("Reading %@"), config->path);
	
	config->line = 0;
	
	wi_lock_lock(config->lock);
	
	previous_values = config->values;
	
	config->values = wi_dictionary_init(wi_mutable_dictionary_alloc());
	
	if(config->defaults) {
		enumerator = wi_dictionary_key_enumerator(config->defaults);
		
		while((name = wi_enumerator_next_data(enumerator))) {
			instance = wi_dictionary_data_for_key(config->defaults, name);
			
			if(wi_runtime_id(instance) == wi_array_runtime_id())
				instance = wi_autorelease(wi_mutable_copy(instance));
			
			wi_mutable_dictionary_set_data_for_key(config->values, instance, name);
		}
	}
	
	while((string = wi_file_read_line(file))) {
		config->line++;

		if(wi_string_length(string) > 0 && !wi_string_has_prefix(string, WI_STR("#"))) {
			if(_wi_config_parse_string(config, string, &name, &value)) {
				instance = _wi_config_instance_for_setting(config, name, value, &type);
				
				if(instance) {
					wi_log_debug(WI_STR("  %@ = %@"), name, value);
					
					if(type == WI_CONFIG_STRINGLIST) {
						array = wi_dictionary_data_for_key(config->values, name);
						
						if(!array) {
							array = wi_mutable_array();
							
							wi_mutable_dictionary_set_data_for_key(config->values, array, name);
						}
						
						wi_mutable_array_add_data(array, instance);
					} else {
						wi_mutable_dictionary_set_data_for_key(config->values, instance, name);
					}
				} else {
					_wi_config_log_error(config, name);
				}
			} else {
				wi_error_set_libwired_error(WI_ERROR_SETTINGS_SYNTAXERROR);
				
				_wi_config_log_error(config, string);
			}
		}
	}
	
	enumerator = wi_dictionary_key_enumerator(config->values);
	
	while((name = wi_enumerator_next_data(enumerator))) {
		instance = wi_dictionary_data_for_key(config->values, name);
		
		if(!previous_values || !wi_is_equal(instance, wi_dictionary_data_for_key(previous_values, name)))
			wi_mutable_set_add_data(config->changes, name);
	}
	
	wi_release(previous_values);

	wi_lock_unlock(config->lock);

	return true;
}



wi_boolean_t wi_config_write_file(wi_config_t *config) {
	wi_enumerator_t		*enumerator;
	wi_file_t			*file, *tmpfile;
	wi_string_t			*string, *name, *value;
	wi_mutable_set_t	*changedkeys, *writtenkeys;
	wi_boolean_t		write;
	
	file = wi_file_for_updating(config->path);
	
	if(!file) {
		wi_log_error(WI_STR("Could not open %@: %m"),
			config->path);
		
		return false;
	}
	
	tmpfile = wi_file_temporary_file();
	
	wi_lock_lock(config->lock);
	
	changedkeys = wi_autorelease(wi_mutable_copy(config->changes));
	writtenkeys = wi_mutable_set();

	while((string = wi_file_read_line(file))) {
		if(wi_string_length(string) == 0) {
			wi_file_write_format(tmpfile, WI_STR("\n"));
		}
		else if(wi_string_has_prefix(string, WI_STR("#"))) {
			write = true;
			string = wi_string_substring_from_index(string, 1);
			
			if(_wi_config_parse_string(config, string, &name, &value)) {
				if(wi_set_contains_data(changedkeys, name)) {
					if(_wi_config_write_setting_to_file(config, name, tmpfile)) {
						write = false;
						
						wi_mutable_set_add_data(writtenkeys, name);
						wi_mutable_set_remove_data(changedkeys, name);
					}
				}
				else if(wi_set_contains_data(writtenkeys, name)) {
					write = false;
				}
			}
			
			if(write)
				wi_file_write_format(tmpfile, WI_STR("#%@\n"), string);
		}
		else {
			write = true;
			
			if(_wi_config_parse_string(config, string, &name, &value)) {
				if(wi_set_contains_data(changedkeys, name)) {
					if(_wi_config_write_setting_to_file(config, name, tmpfile)) {
						write = false;
						
						wi_mutable_set_add_data(writtenkeys, name);
						wi_mutable_set_remove_data(changedkeys, name);
					}
				}
				else if(wi_set_contains_data(writtenkeys, name)) {
					write = false;
				}
			}

			if(write)
				wi_file_write_format(tmpfile, WI_STR("%@\n"), string);
		}
	}
	
	enumerator = wi_set_data_enumerator(changedkeys);
	
	while((name = wi_enumerator_next_data(enumerator)))
		_wi_config_write_setting_to_file(config, name, tmpfile);
	
	wi_mutable_set_remove_all_data(config->changes);

	wi_lock_unlock(config->lock);
	
	wi_file_truncate(file, 0);
	wi_file_seek(tmpfile, 0);
	
	while((string = wi_file_read_line(tmpfile)))
		wi_file_write_format(file, WI_STR("%@\n"), string);

	return true;
}



#pragma mark -

void wi_config_note_change(wi_config_t *config, wi_string_t *name) {
	wi_mutable_set_add_data(config->changes, name);
}



void wi_config_clear_changes(wi_config_t *config) {
	wi_mutable_set_remove_all_data(config->changes);
}



wi_set_t * wi_config_changes(wi_config_t *config) {
	return config->changes;
}



#pragma mark -

static void _wi_config_log_error(wi_config_t *config, wi_string_t *name) {
	wi_log_warn(WI_STR("Could not interpret the setting \"%@\" at %@ line %lu: %m"),
		name, config->path, config->line);
}



static wi_boolean_t _wi_config_parse_string(wi_config_t *config, wi_string_t *string, wi_string_t **name, wi_string_t **value) {
	wi_array_t		*array;
	
	array = wi_string_components_separated_by_string(string, WI_STR("="));
	
	if(wi_array_count(array) != 2)
		return false;
	
	*name = wi_string_by_deleting_surrounding_whitespace(WI_ARRAY(array, 0));
	*value = wi_string_by_deleting_surrounding_whitespace(WI_ARRAY(array, 1));
	
	return true;
}



static wi_runtime_instance_t * _wi_config_instance_for_setting(wi_config_t *config, wi_string_t *name, wi_string_t *value, wi_config_type_t *type) {
	struct passwd		*user;
	struct group		*group;
	struct servent		*servent;
	wi_uinteger_t		port;
	uint32_t			uid, gid;
	
	if(!wi_dictionary_contains_key(config->types, name)) {
		wi_error_set_libwired_error(WI_ERROR_SETTINGS_UNKNOWNSETTING);
		
		return NULL;
	}
	
	*type = wi_number_int32(wi_dictionary_data_for_key(config->types, name));
	
	switch(*type) {
		case WI_CONFIG_INTEGER:
			return wi_number_with_integer(wi_string_integer(value));
			break;
			
		case WI_CONFIG_BOOL:
			return wi_number_with_bool(wi_string_bool(value));
			break;
			
		case WI_CONFIG_STRING:
		case WI_CONFIG_STRINGLIST:
		case WI_CONFIG_PATH:
			return value;
			break;
			
		case WI_CONFIG_USER:
			user = getpwnam(wi_string_cstring(value));
			
			if(!user) {
				uid = wi_string_uint32(value);
				
				if(uid != 0 || wi_is_equal(value, WI_STR("0")))
					user = getpwuid(uid);
			}
			
			if(!user) {
				wi_error_set_libwired_error(WI_ERROR_SETTINGS_NOSUCHUSER);
				
				return NULL;
			}
			
			return wi_number_with_int32(user->pw_uid);
			break;
			
		case WI_CONFIG_GROUP:
			group = getgrnam(wi_string_cstring(value));
			
			if(!group) {
				gid = wi_string_uint32(value);
				
				if(gid != 0 || wi_is_equal(value, WI_STR("0")))
					group = getgrgid(gid);
			}
			
			if(!group) {
				wi_error_set_libwired_error(WI_ERROR_SETTINGS_NOSUCHGROUP);
				
				return NULL;
			}
			
			return wi_number_with_int32(group->gr_gid);
			break;
			
		case WI_CONFIG_PORT:
			port = wi_string_uinteger(value);
			
			if(port > 65535) {
				wi_error_set_libwired_error(WI_ERROR_SETTINGS_INVALIDPORT);
				
				return NULL;
			}
			
			if(port == 0) {
				servent = getservbyname(wi_string_cstring(value), "tcp");
				
				if(!servent) {
					wi_error_set_libwired_error(WI_ERROR_SETTINGS_NOSUCHSERVICE);
					
					return NULL;
				}
				
				port = servent->s_port;
			}
			
			return wi_number_with_int32(port);
			break;
			
		case WI_CONFIG_REGEXP:
			return wi_autorelease(wi_regexp_init_with_string(wi_regexp_alloc(), value));
			break;
			
		case WI_CONFIG_TIME_INTERVAL:
			return wi_number_with_double(wi_string_double(value));
			break;
	}
	
	return NULL;
}



static wi_boolean_t _wi_config_write_setting_to_file(wi_config_t *config, wi_string_t *name, wi_file_t *file) {
	wi_runtime_instance_t		*value;
	wi_config_type_t			type;
	struct passwd				*user;
	struct group				*group;
	wi_uinteger_t				i, count;
	
	if(!wi_dictionary_contains_key(config->types, name)) {
		wi_error_set_libwired_error(WI_ERROR_SETTINGS_UNKNOWNSETTING);

		return false;
	}
	
	type = wi_number_int32(wi_dictionary_data_for_key(config->types, name));
	value = wi_dictionary_data_for_key(config->values, name);
	
	if(!value)
		return false;
	
	switch(type) {
		case WI_CONFIG_INTEGER:
			wi_file_write_format(file, WI_STR("%@ = %d\n"), name, wi_number_integer(value));
			break;
			
		case WI_CONFIG_BOOL:
			wi_file_write_format(file, WI_STR("%@ = %@\n"), name, wi_number_bool(value) ? WI_STR("yes") : WI_STR("no"));
			break;
			
		case WI_CONFIG_STRING:
			wi_file_write_format(file, WI_STR("%@ = %@\n"), name, value);
			break;
			
		case WI_CONFIG_STRINGLIST:
			count = wi_array_count(value);
			
			for(i = 0; i < count; i++)
				wi_file_write_format(file, WI_STR("%@ = %@\n"), name, WI_ARRAY(value, i));
			break;
			
		case WI_CONFIG_PATH:
			wi_file_write_format(file, WI_STR("%@ = %@\n"), name, value);
			break;
			
		case WI_CONFIG_USER:
			user = getpwuid(wi_number_int32(value));
			
			if(user)
				wi_file_write_format(file, WI_STR("%@ = %s\n"), name, user->pw_name);
			else
				wi_file_write_format(file, WI_STR("%@ = %d\n"), name, wi_number_int32(value));
			break;
			
		case WI_CONFIG_GROUP:
			group = getgrgid(wi_number_int32(value));
			
			if(group)
				wi_file_write_format(file, WI_STR("%@ = %s\n"), name, group->gr_name);
			else
				wi_file_write_format(file, WI_STR("%@ = %d\n"), name, wi_number_int32(value));
			break;
			
		case WI_CONFIG_PORT:
			wi_file_write_format(file, WI_STR("%@ = %d\n"), name, wi_number_int32(value));
			break;
			
		case WI_CONFIG_REGEXP:
			wi_file_write_format(file, WI_STR("%@ = %@\n"), name, wi_regexp_string(value));
			break;
			
		case WI_CONFIG_TIME_INTERVAL:
			wi_file_write_format(file, WI_STR("%@ = %.2f\n"), name, wi_number_double(value));
			break;
	}
	
	return true;
}



#pragma mark -

void wi_config_set_instance_for_name(wi_config_t *config, wi_runtime_instance_t *instance, wi_string_t *name) {
	wi_runtime_instance_t		*copy;
	
	wi_lock_lock(config->lock);
	
	if(!wi_is_equal(instance, wi_dictionary_data_for_key(config->values, name)))
		wi_mutable_set_add_data(config->changes, name);
	
	copy = wi_copy(instance);
	wi_mutable_dictionary_set_data_for_key(config->values, copy, name);
	wi_release(copy);
	
	wi_lock_unlock(config->lock);
}



#pragma mark -

wi_integer_t wi_config_integer_for_name(wi_config_t *config, wi_string_t *name) {
	wi_number_t		*value;
	
	wi_lock_lock(config->lock);
	value = wi_autorelease(wi_retain(wi_dictionary_data_for_key(config->values, name)));
	wi_lock_unlock(config->lock);
	
	return value ? wi_number_integer(value) : 0;
}



wi_boolean_t wi_config_bool_for_name(wi_config_t *config, wi_string_t *name) {
	wi_number_t		*value;
	
	wi_lock_lock(config->lock);
	value = wi_autorelease(wi_retain(wi_dictionary_data_for_key(config->values, name)));
	wi_lock_unlock(config->lock);
	
	return value ? wi_number_bool(value) : 0;
}



wi_string_t * wi_config_string_for_name(wi_config_t *config, wi_string_t *name) {
	wi_string_t		*value;
	
	wi_lock_lock(config->lock);
	value = wi_autorelease(wi_retain(wi_dictionary_data_for_key(config->values, name)));
	wi_lock_unlock(config->lock);
	
	return value;
}



wi_array_t * wi_config_stringlist_for_name(wi_config_t *config, wi_string_t *name) {
	wi_array_t		*value;
	
	wi_lock_lock(config->lock);
	value = wi_autorelease(wi_retain(wi_dictionary_data_for_key(config->values, name)));
	wi_lock_unlock(config->lock);
	
	return value;
}



wi_string_t * wi_config_path_for_name(wi_config_t *config, wi_string_t *name) {
	wi_string_t		*value;
	
	wi_lock_lock(config->lock);
	value = wi_autorelease(wi_retain(wi_dictionary_data_for_key(config->values, name)));
	wi_lock_unlock(config->lock);
	
	return value;
}



uint32_t wi_config_uid_for_name(wi_config_t *config, wi_string_t *name) {
	wi_number_t		*value;
	
	wi_lock_lock(config->lock);
	value = wi_autorelease(wi_retain(wi_dictionary_data_for_key(config->values, name)));
	wi_lock_unlock(config->lock);
	
	return value ? wi_number_int32(value) : 0;
}



uint32_t wi_config_gid_for_name(wi_config_t *config, wi_string_t *name) {
	wi_number_t		*value;
	
	wi_lock_lock(config->lock);
	value = wi_autorelease(wi_retain(wi_dictionary_data_for_key(config->values, name)));
	wi_lock_unlock(config->lock);
	
	return value ? wi_number_int32(value) : 0;
}



wi_uinteger_t wi_config_port_for_name(wi_config_t *config, wi_string_t *name) {
	wi_number_t		*value;
	
	wi_lock_lock(config->lock);
	value = wi_autorelease(wi_retain(wi_dictionary_data_for_key(config->values, name)));
	wi_lock_unlock(config->lock);
	
	return value ? wi_number_integer(value) : 0;
}



wi_regexp_t * wi_config_regexp_for_name(wi_config_t *config, wi_string_t *name) {
	wi_regexp_t		*value;
	
	wi_lock_lock(config->lock);
	value = wi_autorelease(wi_retain(wi_dictionary_data_for_key(config->values, name)));
	wi_lock_unlock(config->lock);
	
	return value;
}



wi_time_interval_t wi_config_time_interval_for_name(wi_config_t *config, wi_string_t *name) {
	wi_number_t		*value;
	
	wi_lock_lock(config->lock);
	value = wi_autorelease(wi_retain(wi_dictionary_data_for_key(config->values, name)));
	wi_lock_unlock(config->lock);
	
	return value ? wi_number_double(value) : 0.0;
}
