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

#ifdef HAVE_CARBON_CARBON_H
#include <Carbon/Carbon.h>
#endif

#include <sys/types.h>
#include <sys/time.h>
#include <sys/stat.h>
#include <stdarg.h>
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <limits.h>
#include <float.h>
#include <time.h>
#include <pwd.h>
#include <ctype.h>
#include <errno.h>

#ifdef HAVE_INTTYPES_H
#include <inttypes.h>
#endif

#ifdef WI_ICONV
#include <iconv.h>
#endif

#include <wired/wi-array.h>
#include <wired/wi-assert.h>
#include <wired/wi-compat.h>
#include <wired/wi-data.h>
#include <wired/wi-dictionary.h>
#include <wired/wi-digest.h>
#include <wired/wi-file.h>
#include <wired/wi-lock.h>
#include <wired/wi-macros.h>
#include <wired/wi-private.h>
#include <wired/wi-random.h>
#include <wired/wi-runtime.h>
#include <wired/wi-string.h>
#include <wired/wi-system.h>

#define _WI_STRING_MIN_SIZE				256
#define _WI_STRING_FORMAT_BUFSIZ		64

#define _WI_STRING_GROW(string, n)												\
	WI_STMT_START																\
		if((string)->length + (n) >= (string)->capacity)						\
			_wi_string_grow((string), (string)->length + (n));					\
	WI_STMT_END

#define _WI_STRING_RANGE_ASSERT(string, range)									\
	WI_STMT_START																\
		_WI_STRING_INDEX_ASSERT((string), (range).location);					\
		_WI_STRING_INDEX_ASSERT((string), (range).location + (range).length);	\
	WI_STMT_END

#define _WI_STRING_INDEX_ASSERT(string, index)									\
	WI_ASSERT((index) <= (string)->length,										\
		"index %d out of range (length %d) in \"%@\"",							\
		(index), (string)->length, (string))


/**
 * @struct _wi_string wi-string.h WI_STRING_H
 * @brief Size Structure 
 * 
 * String class.
 */
struct _wi_string {
	wi_runtime_base_t					base;
	
	char								*string;
	wi_uinteger_t						length;
	wi_uinteger_t						capacity;
	wi_boolean_t						free;
};


static void								_wi_string_dealloc(wi_runtime_instance_t *);
static wi_runtime_instance_t *			_wi_string_copy(wi_runtime_instance_t *);
static wi_boolean_t						_wi_string_is_equal(wi_runtime_instance_t *, wi_runtime_instance_t *);
static wi_string_t *					_wi_string_description(wi_runtime_instance_t *);
static wi_hash_code_t					_wi_string_hash(wi_runtime_instance_t *);

static void								_wi_string_grow(wi_string_t *, wi_uinteger_t);
static void								_wi_string_append_arguments(wi_string_t *, const char *, va_list);
static void								_wi_string_append_cstring(wi_string_t *, const char *);
static void								_wi_string_append_bytes(wi_string_t *, const void *, wi_uinteger_t);

static wi_string_t *					_wi_string_sqlite3_escaped_string(wi_string_t *);

static wi_boolean_t						_wi_mutable_string_char_is_whitespace(char);

static wi_mutable_array_t *				_wi_string_path_components(wi_string_t *);

#ifdef HAVE_CARBON_CARBON_H
static void								_wi_mutable_string_resolve_mac_alias_in_path(wi_string_t *);
#endif


static wi_lock_t						*_wi_string_constant_string_lock;
static wi_dictionary_t					*_wi_string_constant_string_table;

static wi_runtime_id_t					_wi_string_runtime_id = WI_RUNTIME_ID_NULL;
static wi_runtime_class_t				_wi_string_runtime_class = {
	"wi_string_t",
	_wi_string_dealloc,
	_wi_string_copy,
	_wi_string_is_equal,
	_wi_string_description,
	_wi_string_hash
};



#ifdef WI_ICONV

struct _wi_string_encoding {
	wi_runtime_base_t					base;
	
	wi_string_t							*charset;
	wi_mutable_string_t					*encoding;

	wi_uinteger_t						options;
};


static void								_wi_string_encoding_dealloc(wi_runtime_instance_t *);
static wi_string_t *					_wi_string_encoding_description(wi_runtime_instance_t *);


static wi_runtime_id_t					_wi_string_encoding_runtime_id = WI_RUNTIME_ID_NULL;
static wi_runtime_class_t				_wi_string_encoding_runtime_class = {
	"wi_string_encoding_t",
	_wi_string_encoding_dealloc,
	NULL,
	NULL,
	_wi_string_encoding_description,
	NULL
};

#endif



void wi_string_register(void) {
	_wi_string_runtime_id = wi_runtime_register_class(&_wi_string_runtime_class);
	
#ifdef WI_ICONV
	_wi_string_encoding_runtime_id = wi_runtime_register_class(&_wi_string_encoding_runtime_class);
#endif
}



void wi_string_initialize(void) {
	_wi_string_constant_string_lock = wi_lock_init(wi_lock_alloc());
	_wi_string_constant_string_table = wi_dictionary_init_with_capacity_and_callbacks(wi_mutable_dictionary_alloc(),
		2000, wi_dictionary_null_key_callbacks, wi_dictionary_default_value_callbacks);
}



#pragma mark -

wi_runtime_id_t wi_string_runtime_id(void) {
	return _wi_string_runtime_id;
}



#pragma mark -

wi_string_t * wi_string(void) {
	return wi_autorelease(wi_string_init(wi_string_alloc()));
}



wi_string_t * wi_string_with_cstring(const char *cstring) {
	return wi_autorelease(wi_string_init_with_cstring(wi_string_alloc(), cstring));
}



wi_string_t * wi_string_with_cstring_no_copy(char *cstring, wi_boolean_t free) {
	return wi_autorelease(wi_string_init_with_cstring_no_copy(wi_string_alloc(), cstring, free));
}



wi_string_t * wi_string_with_format(wi_string_t *fmt, ...) {
	wi_string_t		*string;
	va_list			ap;
	
	va_start(ap, fmt);
	string = wi_string_init_with_format_and_arguments(wi_string_alloc(), fmt, ap);
	va_end(ap);
	
	return wi_autorelease(string);
}



wi_string_t * wi_string_with_format_and_arguments(wi_string_t *fmt, va_list ap) {
	return wi_autorelease(wi_string_init_with_format_and_arguments(wi_string_alloc(), fmt, ap));
}



wi_string_t * wi_string_with_data(wi_data_t *data) {
	return wi_autorelease(wi_string_init_with_data(wi_string_alloc(), data));
}



wi_string_t * wi_string_with_bytes(const void *buffer, wi_uinteger_t size) {
	return wi_autorelease(wi_string_init_with_bytes(wi_string_alloc(), buffer, size));
}



wi_string_t * wi_string_with_bytes_no_copy(void *buffer, wi_uinteger_t size, wi_boolean_t free) {
	return wi_autorelease(wi_string_init_with_bytes_no_copy(wi_string_alloc(), buffer, size, free));
}



wi_string_t * wi_string_with_base64(wi_string_t *base64) {
	return wi_autorelease(wi_string_init_with_base64(wi_string_alloc(), base64));
}



wi_mutable_string_t * wi_mutable_string(void) {
	return wi_autorelease(wi_string_init(wi_mutable_string_alloc()));
}



wi_mutable_string_t * wi_mutable_string_with_format(wi_string_t *fmt, ...) {
	wi_mutable_string_t		*string;
	va_list					ap;
	
	va_start(ap, fmt);
	string = wi_string_init_with_format_and_arguments(wi_mutable_string_alloc(), fmt, ap);
	va_end(ap);
	
	return wi_autorelease(string);
}



#pragma mark -

wi_string_t * wi_string_alloc(void) {
	return wi_runtime_create_instance_with_options(_wi_string_runtime_id, sizeof(wi_string_t), WI_RUNTIME_OPTION_IMMUTABLE);
}



wi_mutable_string_t * wi_mutable_string_alloc(void) {
	return wi_runtime_create_instance_with_options(_wi_string_runtime_id, sizeof(wi_string_t), WI_RUNTIME_OPTION_MUTABLE);
}



wi_string_t * wi_string_init(wi_string_t *string) {
	return wi_string_init_with_capacity(string, 0);
}



wi_string_t * wi_string_init_with_capacity(wi_string_t *string, wi_uinteger_t capacity) {
	string->capacity	= WI_MAX(wi_exp2m1(wi_log2(capacity) + 1), _WI_STRING_MIN_SIZE);
	string->string		= wi_malloc(string->capacity);
	string->length		= 0;
	string->free		= true;
	
	return string;
}



wi_string_t * wi_string_init_with_cstring_no_copy(wi_string_t *string, char *cstring, wi_boolean_t free) {
	string->length		= strlen(cstring);
	string->capacity	= string->length + 1;
	string->string		= cstring;
	string->free		= free;
	
	return string;
}



wi_string_t * wi_string_init_with_cstring(wi_string_t *string, const char *cstring) {
	string = wi_string_init_with_capacity(string, strlen(cstring));
	
	_wi_string_append_cstring(string, cstring);

	return string;
}



wi_string_t * wi_string_init_with_data(wi_string_t *string, wi_data_t *data) {
	return wi_string_init_with_bytes(string, wi_data_bytes(data), wi_data_length(data));
}



wi_string_t * wi_string_init_with_bytes(wi_string_t *string, const void *buffer, wi_uinteger_t size) {
	string = wi_string_init_with_capacity(string, size);
	
	_wi_string_append_bytes(string, buffer, size);

	return string;
}



wi_string_t * wi_string_init_with_bytes_no_copy(wi_string_t *string, void *buffer, wi_uinteger_t size, wi_boolean_t free) {
	string->length		= size;
	string->capacity	= string->length + 1;
	string->string		= buffer;
	string->free		= free;
	
	return string;
}



wi_string_t * wi_string_init_with_random_bytes(wi_string_t *string, wi_uinteger_t length) {
	string = wi_string_init_with_capacity(string, length);
	
	wi_random_get_bytes(string->string, length);
	
	string->length = length;
	
	return string;
}



wi_string_t * wi_string_init_with_format(wi_string_t *string, wi_string_t *fmt, ...) {
	va_list		ap;
	
	va_start(ap, fmt);
	string = wi_string_init_with_format_and_arguments(string, fmt, ap);
	va_end(ap);
	
	return string;
}



wi_string_t * wi_string_init_with_format_and_arguments(wi_string_t *string, wi_string_t *fmt, va_list ap) {
	string = wi_string_init(string);
	
	_wi_string_append_arguments(string, wi_string_cstring(fmt), ap);
	
	return string;
}



wi_string_t * wi_string_init_with_base64(wi_string_t *string, wi_string_t *base64) {
	return wi_string_init_with_data(string, wi_data_from_base64_string(base64));
}



wi_string_t * wi_string_init_with_contents_of_file(wi_string_t *string, wi_string_t *path) {
	wi_file_t       *file;
	
	wi_release(string);
		
	file = wi_file_for_reading(path);
	
	if(!file)
		return NULL;
	
	string = wi_file_read_to_end_of_file(file);
	
	wi_file_close(file);
	
	return wi_retain(string);
}



static void _wi_string_dealloc(wi_runtime_instance_t *instance) {
	wi_string_t		*string = instance;
	
	if(string->string && string->free)
		wi_free(string->string);
}



static wi_runtime_instance_t * _wi_string_copy(wi_runtime_instance_t *instance) {
	wi_string_t		*string = instance;
	
	return wi_string_init_with_cstring(wi_string_alloc(), string->string);
}



static wi_boolean_t _wi_string_is_equal(wi_runtime_instance_t *instance1, wi_runtime_instance_t *instance2) {
	return (wi_string_compare(instance1, instance2) == 0);
}



static wi_string_t * _wi_string_description(wi_runtime_instance_t *instance) {
	wi_string_t		*string = instance;

	return string;
}



static wi_hash_code_t _wi_string_hash(wi_runtime_instance_t *instance) {
	wi_string_t		*string = instance;
	
	return wi_hash_cstring(string->string, string->length);
}



#pragma mark -


wi_integer_t wi_string_compare(wi_runtime_instance_t *instance1, wi_runtime_instance_t *instance2) {
	wi_string_t		*string1 = instance1;
	wi_string_t		*string2 = instance2;

	return strcmp(string1->string, string2->string);
}



wi_integer_t wi_string_case_insensitive_compare(wi_runtime_instance_t *instance1, wi_runtime_instance_t *instance2) {
	wi_string_t		*string1 = instance1;
	wi_string_t		*string2 = instance2;

	return strcasecmp(string1->string, string2->string);
}



#pragma mark -

wi_uinteger_t wi_string_length(wi_string_t *string) {
	return string ? string->length : 0;
}



const char * wi_string_cstring(wi_string_t *string) {
	return string->string;
}



char wi_string_character_at_index(wi_string_t *string, wi_uinteger_t index) {
	_WI_STRING_INDEX_ASSERT(string, index);

	return string->string[index];
}



#pragma mark -

wi_string_t * _wi_string_constant_string(const char *cstring) {
	wi_string_t			*string;
	    
	wi_lock_lock(_wi_string_constant_string_lock);
	string = wi_dictionary_data_for_key(_wi_string_constant_string_table, (void *) cstring);
	
	if(!string) {
		string = wi_string_init_with_cstring(wi_string_alloc(), cstring);
		wi_mutable_dictionary_set_data_for_key(_wi_string_constant_string_table, string, (void *) cstring);
		wi_release(string);
	}
	
	wi_lock_unlock(_wi_string_constant_string_lock);

	return string;
}



#pragma mark -

static void _wi_string_grow(wi_string_t *string, wi_uinteger_t capacity) {
	capacity = WI_MAX(wi_exp2m1(wi_log2(capacity) + 1), _WI_STRING_MIN_SIZE);

	if(string->free) {
		string->string = wi_realloc(string->string, capacity);
	} else {
		string->string = wi_malloc(capacity);
		string->free = true;
	}

	string->capacity = capacity;
}



static void _wi_string_append_arguments(wi_string_t *string, const char *fmt, va_list ap) {
	wi_string_t			*description;
	const char			*p, *pfmt;
	char				*s, *vbuffer, cfmt[_WI_STRING_FORMAT_BUFSIZ], buffer[_WI_STRING_FORMAT_BUFSIZ];
	wi_uinteger_t		i, size, totalsize;
	int					ch, length;
	wi_boolean_t		alt, star, h, hh, j, t, l, ll, L, z;
	
	pfmt = fmt;
	
	while(true) {
		i = totalsize = length = 0;
		p = pfmt;
		
		while(*pfmt && *pfmt != '%')
			pfmt++;

		size = pfmt - p;
		
		if(size > 0)
			_wi_string_append_bytes(string, p, size);
		
		if(!*pfmt)
			return;
		
		alt = star = h = hh = j = t = l = ll = L = z = false;
		
		ch			= *pfmt++;
		cfmt[i++]	= ch;

nextflag:
		ch			= *pfmt++;
		cfmt[i++]	= ch;
		cfmt[i]		= '\0';

		switch(ch) {
			case '#':
				alt = true;
				
				goto nextflag;
				break;
				
			case '@':
				description = wi_description(va_arg(ap, wi_runtime_instance_t *));
				
				if(description) {
					_wi_string_append_cstring(string, description->string);
					totalsize += description->length;
				}
				else if(!alt) {
					_wi_string_append_cstring(string, "(null)");
					totalsize += 6;
				}
				break;
			
			case 'q':
				description = wi_description(va_arg(ap, wi_runtime_instance_t *));
				
				if(description) {
					description = _wi_string_sqlite3_escaped_string(description);
					_wi_string_append_cstring(string, description->string);
					totalsize += description->length;
				} else {
					_wi_string_append_cstring(string, "'(null)'");
					totalsize += 8;
				}
				break;
				
			case 'Q':
				description = wi_description(va_arg(ap, wi_runtime_instance_t *));
				
				if(description) {
					description = _wi_string_sqlite3_escaped_string(description);
					_wi_string_append_cstring(string, "'");
					_wi_string_append_cstring(string, description->string);
					_wi_string_append_cstring(string, "'");
					totalsize += description->length + 2;
				} else {
					_wi_string_append_cstring(string, "NULL");
					totalsize += 4;
				}
				break;
			
			case ' ':
			case '-':
			case '+':
			case '.':
			case '\'':
			case '0':
			case '1':
			case '2':
			case '3':
			case '4':
			case '5':
			case '6':
			case '7':
			case '8':
			case '9':
				goto nextflag;
				break;
			
			case '*':
				star = true;
				length = va_arg(ap, int);
				
				goto nextflag;
				break;
				
			case 'h':
				if(h)
					hh = true;
				else
					h = true;

				goto nextflag;
				break;
				
			case 'j':
				j = true;
				
				goto nextflag;
				break;
			
			case 't':
				t = true;
				
				goto nextflag;
				break;
			
			case 'l':
				if(l)
					ll = true;
				else
					l = true;

				goto nextflag;
				break;

			case 'L':
				L = true;
				
				goto nextflag;
				break;
			
			case 'a':
			case 'A':
			case 'e':
			case 'E':
			case 'f':
			case 'g':
			case 'G':
				if(L)
					size = snprintf(buffer, sizeof(buffer), cfmt, va_arg(ap, long double));
				else
					size = snprintf(buffer, sizeof(buffer), cfmt, va_arg(ap, double));
				
				_wi_string_append_bytes(string, buffer, size);
				totalsize += size;
				break;
				
			case 'c':
			case 'D':
			case 'd':
			case 'i':
			case 'O':
			case 'o':
			case 'p':
			case 'U':
			case 'u':
			case 'X':
			case 'x':
				if(ll)
					size = snprintf(buffer, sizeof(buffer), cfmt, va_arg(ap, long long));
				else if(l || ch == 'D' || ch == 'O' || ch == 'U')
					size = snprintf(buffer, sizeof(buffer), cfmt, va_arg(ap, long));
				else if(ch == 'p')
					size = snprintf(buffer, sizeof(buffer), cfmt, va_arg(ap, void *));
#ifdef HAVE_INTMAX_T
				else if(j)
					size = snprintf(buffer, sizeof(buffer), cfmt, va_arg(ap, intmax_t));
#endif
#ifdef HAVE_PTRDIFF_T
				else if(t)
					size = snprintf(buffer, sizeof(buffer), cfmt, va_arg(ap, ptrdiff_t));
#endif
				else if(z)
					size = snprintf(buffer, sizeof(buffer), cfmt, va_arg(ap, size_t));
				else
					size = snprintf(buffer, sizeof(buffer), cfmt, va_arg(ap, int));
				
				_wi_string_append_bytes(string, buffer, size);
				totalsize += size;
				break;
			
			case 'm':
				description = wi_error_string();
				_wi_string_append_cstring(string, description->string);
				totalsize += description->length;
				break;
			
			case 'n':
				if(hh)
					*(va_arg(ap, signed char *)) = totalsize;
				else if(h)
					*(va_arg(ap, short *)) = totalsize;
				if(ll)
					*(va_arg(ap, long long *)) = totalsize;
				else if(l)
					*(va_arg(ap, long *)) = totalsize;
#ifdef HAVE_INTMAX_T
				else if(j)
					*(va_arg(ap, intmax_t *)) = totalsize;
#endif
#ifdef HAVE_PTRDIFF_T
				else if(t)
					*(va_arg(ap, ptrdiff_t *)) = totalsize;
#endif
				else if(z)
					*(va_arg(ap, size_t *)) = totalsize;
				break;
			
			case 's':
				s = va_arg(ap, char *);
				
				if(s) {
					if(star)
						size = wi_asprintf(&vbuffer, cfmt, length, s);
					else
						size = wi_asprintf(&vbuffer, cfmt, s);
					
					if(size > 0 && vbuffer) {
						_wi_string_append_bytes(string, vbuffer, size);
						totalsize += size;
						free(vbuffer);
					}
				}
				else if(!alt) {
					_wi_string_append_cstring(string, "(null)");
					totalsize += 6;
				}
				break;
			
			case 'z':
				z = true;
				
				goto nextflag;
				break;
				
			default:
				if(ch == '\0')
					return;
				
				buffer[0] = ch;

				_wi_string_append_bytes(string, buffer, 1);
				totalsize += 1;
				break;
		}
	}
}



static void _wi_string_append_cstring(wi_string_t *string, const char *cstring) {
	_wi_string_append_bytes(string, cstring, strlen(cstring));
}



static void _wi_string_append_bytes(wi_string_t *string, const void *buffer, wi_uinteger_t length) {
	_WI_STRING_GROW(string, length);
	
	memmove(string->string + string->length, buffer, length);
	
	string->length += length;
	string->string[string->length] = '\0';
}



#pragma mark -

static wi_string_t * _wi_string_sqlite3_escaped_string(wi_string_t *string) {
	wi_mutable_string_t		*newstring;
	wi_range_t				range, searchrange;
	
	newstring		= wi_mutable_copy(string);
	searchrange		= wi_make_range(0, wi_string_length(newstring));
	
	while((range = wi_string_range_of_string_in_range(newstring, WI_STR("'"), 0, searchrange)).location != WI_NOT_FOUND) {
		wi_mutable_string_replace_characters_in_range_with_string(newstring, range, WI_STR("''"));
		
		searchrange.location	= range.location + 2;
		searchrange.length		= wi_string_length(newstring) - searchrange.location;
	}
	
	wi_runtime_make_immutable(newstring);
	
	return wi_autorelease(newstring);
}



#pragma mark -

wi_string_t * wi_string_by_appending_cstring(wi_string_t *string, const char *cstring) {
	wi_mutable_string_t		*newstring;
	
	newstring = wi_mutable_copy(string);
	
	wi_mutable_string_append_cstring(newstring, cstring);
	
	wi_runtime_make_immutable(newstring);
	
	return wi_autorelease(newstring);
}



wi_string_t * wi_string_by_appending_bytes(wi_string_t *string, const void *buffer, wi_uinteger_t length) {
	wi_mutable_string_t		*newstring;
	
	newstring = wi_mutable_copy(string);

	wi_mutable_string_append_bytes(newstring, buffer, length);
	
	wi_runtime_make_immutable(newstring);
	
	return wi_autorelease(newstring);
}



wi_string_t * wi_string_by_appending_string(wi_string_t *string, wi_string_t *otherstring) {
	wi_mutable_string_t		*newstring;
	
	newstring = wi_mutable_copy(string);

	wi_mutable_string_append_cstring(newstring, otherstring->string);
	
	wi_runtime_make_immutable(newstring);
	
	return wi_autorelease(newstring);
}



wi_string_t * wi_string_by_appending_format(wi_string_t *string, wi_string_t *fmt, ...) {
	wi_mutable_string_t		*newstring;
	va_list					ap;
	
	newstring = wi_mutable_copy(string);

	va_start(ap, fmt);
	wi_mutable_string_append_format_and_arguments(newstring, fmt, ap);
	va_end(ap);
	
	wi_runtime_make_immutable(newstring);
	
	return wi_autorelease(newstring);
}



wi_string_t * wi_string_by_appending_format_and_arguments(wi_string_t *string, wi_string_t *fmt, va_list ap) {
	wi_mutable_string_t		*newstring;
	
	newstring = wi_mutable_copy(string);

	wi_mutable_string_append_format_and_arguments(newstring, fmt, ap);
	
	wi_runtime_make_immutable(newstring);
	
	return wi_autorelease(newstring);
}



#pragma mark -

wi_string_t * wi_string_by_inserting_string_at_index(wi_string_t *string, wi_string_t *otherstring, wi_uinteger_t index) {
	wi_mutable_string_t		*newstring;
	
	newstring = wi_mutable_copy(string);

	wi_mutable_string_insert_string_at_index(newstring, otherstring, index);
	
	wi_runtime_make_immutable(newstring);
	
	return wi_autorelease(newstring);
}



#pragma mark -

wi_string_t * wi_string_by_replacing_characters_in_range_with_string(wi_string_t *string, wi_range_t range, wi_string_t *replacement) {
	wi_mutable_string_t		*newstring;
	
	newstring = wi_mutable_copy(string);
	
	wi_mutable_string_replace_characters_in_range_with_string(newstring, range, replacement);
	
	wi_runtime_make_immutable(newstring);
	
	return wi_autorelease(newstring);
}



wi_string_t * wi_string_by_replacing_string_with_string(wi_string_t *string, wi_string_t *target, wi_string_t *replacement, wi_uinteger_t options) {
	wi_mutable_string_t		*newstring;
	
	newstring = wi_mutable_copy(string);

	wi_mutable_string_replace_string_with_string(newstring, target, replacement, options);
	
	wi_runtime_make_immutable(newstring);
	
	return wi_autorelease(newstring);
}



#pragma mark -

wi_string_t * wi_string_by_deleting_characters_in_range(wi_string_t *string, wi_range_t range) {
	wi_string_t		*newstring;
	
	newstring = wi_mutable_copy(string);

	wi_mutable_string_delete_characters_in_range(newstring, range);
	
	wi_runtime_make_immutable(newstring);
	
	return wi_autorelease(newstring);
}



wi_string_t * wi_string_by_deleting_characters_from_index(wi_string_t *string, wi_uinteger_t index) {
	wi_string_t		*newstring;
	
	newstring = wi_mutable_copy(string);

	wi_mutable_string_delete_characters_from_index(newstring, index);
	
	wi_runtime_make_immutable(newstring);
	
	return wi_autorelease(newstring);
}



wi_string_t * wi_string_by_deleting_characters_to_index(wi_string_t *string, wi_uinteger_t index) {
	wi_string_t		*newstring;
	
	newstring = wi_mutable_copy(string);

	wi_mutable_string_delete_characters_to_index(newstring, index);
	
	wi_runtime_make_immutable(newstring);
	
	return wi_autorelease(newstring);
}



wi_string_t * wi_string_by_deleting_surrounding_whitespace(wi_string_t *string) {
	wi_string_t		*newstring;
	
	newstring = wi_mutable_copy(string);

	wi_mutable_string_delete_surrounding_whitespace(newstring);
	
	wi_runtime_make_immutable(newstring);
	
	return wi_autorelease(newstring);
}



#pragma mark -

wi_string_t * wi_string_substring_with_range(wi_string_t *string, wi_range_t range) {
	_WI_STRING_RANGE_ASSERT(string, range);
	
	return wi_autorelease(wi_string_init_with_bytes(wi_string_alloc(), string->string + range.location, range.length));
}



wi_string_t * wi_string_substring_from_index(wi_string_t *string, wi_uinteger_t index) {
	return wi_string_substring_with_range(string, wi_make_range(index, string->length - index));
}



wi_string_t * wi_string_substring_to_index(wi_string_t *string, wi_uinteger_t index) {
	return wi_string_substring_with_range(string, wi_make_range(0, index));
}



wi_array_t * wi_string_components_separated_by_string(wi_string_t *string, wi_string_t *separator) {
	wi_string_t		*component;
	wi_array_t		*array;
	const char		*cstring;
	char			*s, *ss, *ap;
	
	array		= wi_array_init(wi_mutable_array_alloc());
	cstring		= wi_string_cstring(separator);
	
	s = ss = strdup(string->string);
	
	while((ap = wi_strsep(&s, cstring))) {
		component = wi_string_init_with_cstring(wi_string_alloc(), ap);
		wi_mutable_array_add_data(array, component);
		wi_release(component);
	}
	
	free(ss);
	
	wi_runtime_make_immutable(array);
	
	return wi_autorelease(array);
}



#pragma mark -

wi_range_t wi_string_range_of_string(wi_string_t *string, wi_string_t *otherstring, wi_uinteger_t options) {
	return wi_string_range_of_string_in_range(string, otherstring, options, wi_make_range(0, string->length));
}



wi_range_t wi_string_range_of_string_in_range(wi_string_t *string, wi_string_t *otherstring, wi_uinteger_t options, wi_range_t inrange) {
	wi_range_t		range;
	
	range.location = wi_string_index_of_string_in_range(string, otherstring, options, inrange);
	
	if(range.location == WI_NOT_FOUND)
		range.length = 0;
	else
		range.length = otherstring->length;
	
	return range;
}



wi_uinteger_t wi_string_index_of_string(wi_string_t *string, wi_string_t *otherstring, wi_uinteger_t options) {
	return wi_string_index_of_string_in_range(string, otherstring, options, wi_make_range(0, string->length));
}



wi_uinteger_t wi_string_index_of_string_in_range(wi_string_t *string, wi_string_t *otherstring, wi_uinteger_t options, wi_range_t range) {
	char			*p;
	wi_uinteger_t	i, index;
	wi_boolean_t	insensitive = false;

	_WI_STRING_RANGE_ASSERT(string, range);
	
	if(range.length == 0)
		return WI_NOT_FOUND;

	if(options & WI_STRING_CASE_INSENSITIVE) {
		insensitive = true;
	}
	else if(options & WI_STRING_SMART_CASE_INSENSITIVE) {
		insensitive = true;
		
		for(i = 0; i < otherstring->length; i++) {
			if(isupper(otherstring->string[i])) {
				insensitive = false;
				
				break;
			}
		}
	}

	if(options & WI_STRING_BACKWARDS) {
		if(insensitive)
			p = wi_strrncasestr(string->string + range.location, otherstring->string, range.length);
		else
			p = wi_strrnstr(string->string + range.location, otherstring->string, range.length);
	} else {
		if(insensitive)
			p = wi_strncasestr(string->string + range.location, otherstring->string, range.length);
		else
			p = wi_strnstr(string->string + range.location, otherstring->string, range.length);
	}
	
	if(!p)
		return WI_NOT_FOUND;
	
	index = p - string->string;
	
	if(index > range.location + range.length)
		return WI_NOT_FOUND;
	
	return index;
}



wi_uinteger_t wi_string_index_of_char(wi_string_t *string, int ch, wi_uinteger_t options) {
	wi_uinteger_t	i, index = WI_NOT_FOUND;
	char			*p;
	int				c;
	wi_boolean_t	insensitive = false;

	if((options & WI_STRING_CASE_INSENSITIVE) ||
	   (options & WI_STRING_SMART_CASE_INSENSITIVE && isupper(ch))) {
		insensitive = true;
		ch = tolower((unsigned int) ch);
	}

	p = string->string;
	
	for(i = 0; *p; p++, i++) {
		c = insensitive ? tolower((unsigned int) *p) : *p;
		
		if(c == ch) {
			index = i;

			if(!(options & WI_STRING_BACKWARDS))
				break;
		}
	}
	
	return index;
}

 

wi_boolean_t wi_string_contains_string(wi_string_t *string, wi_string_t *otherstring, wi_uinteger_t options) {
	return (wi_string_index_of_string(string, otherstring, options) != WI_NOT_FOUND);
}



wi_boolean_t wi_string_has_prefix(wi_string_t *string, wi_string_t *prefix) {
	return (strncmp(string->string, prefix->string, prefix->length) == 0);
}



wi_boolean_t wi_string_has_suffix(wi_string_t *string, wi_string_t *suffix) {
	wi_integer_t	offset;

	offset = string->length - suffix->length;

	if(offset < 0)
		return false;

	return (strcmp(string->string + offset, suffix->string) == 0);
}



#pragma mark -

wi_string_t * wi_string_lowercase_string(wi_string_t *string) {
	wi_mutable_string_t		*newstring;
	wi_uinteger_t			i;
	
	newstring = wi_mutable_copy(string);
	
	for(i = 0; i < newstring->length; i++)
		newstring->string[i] = tolower((unsigned int) newstring->string[i]);
	
	wi_runtime_make_immutable(newstring);
	
	return wi_autorelease(newstring);
}



wi_string_t * wi_string_uppercase_string(wi_string_t *string) {
	wi_mutable_string_t		*newstring;
	wi_uinteger_t			i;
	
	newstring = wi_mutable_copy(string);
	
	for(i = 0; i < newstring->length; i++)
		newstring->string[i] = toupper((unsigned int) newstring->string[i]);
	
	wi_runtime_make_immutable(newstring);
	
	return wi_autorelease(newstring);
}



#pragma mark -

static wi_mutable_array_t * _wi_string_path_components(wi_string_t *path) {
	wi_array_t		*array, *components;
	wi_string_t		*component;
	wi_uinteger_t	i, count;
	
	components	= wi_string_components_separated_by_string(path, WI_STR("/"));
	count		= wi_array_count(components);
	array		= wi_array_init_with_capacity(wi_mutable_array_alloc(), count);

	for(i = 0; i < count; i++) {
		component = WI_ARRAY(components, i);

		if(wi_string_length(component) > 0)
			wi_mutable_array_add_data(array, component);
		else if(i == 0)
			wi_mutable_array_add_data(array, WI_STR("/"));
	}

	return wi_autorelease(array);
}



wi_array_t * wi_string_path_components(wi_string_t *path) {
	wi_mutable_array_t		*array;

	array = _wi_string_path_components(path);
	
	wi_runtime_make_immutable(array);

	return array;
}



wi_string_t * wi_string_by_normalizing_path(wi_string_t *path) {
	wi_mutable_string_t		*string;
	
	string = wi_mutable_copy(path);
	
	wi_mutable_string_normalize_path(string);
	
	wi_runtime_make_immutable(string);
	
	return wi_autorelease(string);
}



wi_string_t * wi_string_by_resolving_aliases_in_path(wi_string_t *path) {
	wi_mutable_string_t		*string;
	
	string = wi_mutable_copy(path);
	
	wi_mutable_string_resolve_aliases_in_path(string);
	
	wi_runtime_make_immutable(string);
	
	return wi_autorelease(string);
}



wi_string_t * wi_string_by_expanding_tilde_in_path(wi_string_t *path) {
	wi_mutable_string_t		*string;
	
	string = wi_mutable_copy(path);
	
	wi_mutable_string_expand_tilde_in_path(string);
	
	wi_runtime_make_immutable(string);
	
	return wi_autorelease(string);
}



wi_string_t * wi_string_by_appending_path_component(wi_string_t *path, wi_string_t *component) {
	wi_mutable_string_t		*string;
	
	string = wi_mutable_copy(path);
	
	wi_mutable_string_append_path_component(string, component);
	
	wi_runtime_make_immutable(string);
	
	return wi_autorelease(string);
}



wi_string_t * wi_string_by_appending_path_components(wi_string_t *path, wi_array_t *components) {
	wi_mutable_string_t		*string;
	
	string = wi_mutable_copy(path);
	
	wi_mutable_string_append_path_components(string, components);
	
	wi_runtime_make_immutable(string);
	
	return wi_autorelease(string);
}



wi_string_t * wi_string_last_path_component(wi_string_t *path) {
	wi_range_t			range;
	wi_uinteger_t		length, index;

	if(wi_is_equal(path, WI_STR("/")))
		return path;

	length	= wi_string_length(path);
	range 	= wi_make_range(0, length);

	while(true) {
		index = wi_string_index_of_string_in_range(path, WI_STR("/"), WI_STRING_BACKWARDS, range);

		if(index == WI_NOT_FOUND) {
			return path;
		}
		else if(index == length - 1) {
			range.length--;

			if(range.length == 0)
				return WI_STR("/");

			continue;
		}

		return wi_string_substring_with_range(path, wi_make_range(index + 1, range.length - index - 1));
	}
}



wi_string_t * wi_string_by_appending_path_extension(wi_string_t *path, wi_string_t *extension) {
	wi_mutable_string_t		*string;
	
	string = wi_mutable_copy(path);
	
	wi_mutable_string_append_path_extension(string, extension);
	
	wi_runtime_make_immutable(string);
	
	return wi_autorelease(string);
}



wi_string_t * wi_string_path_extension(wi_string_t *path) {
	wi_uinteger_t	index;
	
	index = wi_string_index_of_char(path, '.', WI_STRING_BACKWARDS);

	if(index != WI_NOT_FOUND && index + 1 < path->length)
		return wi_string_by_deleting_characters_to_index(path, index + 1);
	
	return WI_STR("");
}



wi_string_t * wi_string_by_deleting_last_path_component(wi_string_t *path) {
	wi_mutable_string_t		*string;
	
	string = wi_mutable_copy(path);
	
	wi_mutable_string_delete_last_path_component(string);
	
	wi_runtime_make_immutable(string);
	
	return wi_autorelease(string);
}



wi_string_t * wi_string_by_deleting_path_extension(wi_string_t *path) {
	wi_mutable_string_t		*string;
	
	string = wi_mutable_copy(path);
	
	wi_mutable_string_delete_path_extension(string);
	
	wi_runtime_make_immutable(string);
	
	return wi_autorelease(string);
}



#pragma mark -

wi_boolean_t wi_string_bool(wi_string_t *string) {
	if(strcasecmp(string->string, "yes") == 0)
		return true;
	
	return (wi_string_int32(string) > 0);
}



int32_t wi_string_int32(wi_string_t *string) {
	long		l;
	char		*ep;
	
	errno = 0;
	l = strtol(string->string, &ep, 0);
	
	if(string->string == ep || *ep != '\0' || errno == ERANGE)
		return 0;
	
	if(l > INT32_MAX || l < INT32_MIN)
		return 0;
	
	return (int32_t) l;
}



uint32_t wi_string_uint32(wi_string_t *string) {
	unsigned long	ul;
	char			*ep;
	
	errno = 0;
	ul = strtoul(string->string, &ep, 0);
	
	if(string->string == ep || *ep != '\0' || errno == ERANGE)
		return 0;
	
	if(ul > UINT32_MAX)
		return 0;
	
	return (uint32_t) ul;
}



int64_t wi_string_int64(wi_string_t *string) {
	long long	ll;
	char		*ep;
	
	errno = 0;
	ll = strtoll(string->string, &ep, 0);
	
	if(string->string == ep || *ep != '\0' || errno == ERANGE)
		return 0;
	
	return (int64_t) ll;
}



uint64_t wi_string_uint64(wi_string_t *string) {
	unsigned long long	ull;
	char				*ep;
	
	errno = 0;
	ull = strtoull(string->string, &ep, 0);
	
	if(string->string == ep || *ep != '\0' || errno == ERANGE)
		return 0ULL;
	
	return (uint64_t) ull;
}



wi_integer_t wi_string_integer(wi_string_t *string) {
#if WI_32
	return (wi_integer_t) wi_string_int32(string);
#else
	return (wi_integer_t) wi_string_int64(string);
#endif
}



wi_uinteger_t wi_string_uinteger(wi_string_t *string) {
#if WI_32
	return (wi_uinteger_t) wi_string_uint32(string);
#else
	return (wi_uinteger_t) wi_string_uint64(string);
#endif
}



float wi_string_float(wi_string_t *string) {
	double		d;
	char		*ep;
	
	errno = 0;
	d = strtod(string->string, &ep);
	
	if(string->string == ep || *ep != '\0' || errno == ERANGE)
		return 0.0;
	
	if(d > FLT_MAX || d < FLT_MIN)
		return 0.0;
	
	return (float) d;
}



double wi_string_double(wi_string_t *string) {
	double		d;
	char		*ep;
	
	errno = 0;
	d = strtod(string->string, &ep);
	
	if(string->string == ep || *ep != '\0' || errno == ERANGE)
		return 0.0;
	
	return d;
}



#pragma mark -

wi_data_t * wi_string_data(wi_string_t *string) {
	return wi_autorelease(wi_data_init_with_bytes(wi_data_alloc(), string->string, string->length));
}



#ifdef WI_DIGESTS

wi_string_t * wi_string_md5(wi_string_t *string) {
	return wi_md5_digest_string(wi_string_data(string));
}



wi_string_t * wi_string_sha1(wi_string_t *string) {
	return wi_sha1_digest_string(wi_string_data(string));
}



wi_string_t * wi_string_sha256(wi_string_t *string) {
	return wi_sha256_digest_string(wi_string_data(string));
}




#endif



wi_string_t * wi_string_base64(wi_string_t *string) {
	return wi_base64_string_from_data(wi_string_data(string));
}



#pragma mark -

#ifdef WI_ICONV

wi_string_t * wi_string_by_converting_encoding(wi_string_t *string, wi_string_encoding_t *from, wi_string_encoding_t *to) {
	wi_string_t		*newstring;
	
	newstring = wi_mutable_copy(string);
	
	wi_mutable_string_convert_encoding(newstring, from, to);
	
	wi_runtime_make_immutable(newstring);
	
	return wi_autorelease(newstring);
}

#endif



#pragma mark -

wi_boolean_t wi_string_write_to_file(wi_string_t *string, wi_string_t *path) {
	FILE	*fp;
	char	fullpath[WI_PATH_SIZE];
	
	snprintf(fullpath, sizeof(fullpath), "%s~", path->string);

	fp = fopen(fullpath, "w");

	if(!fp) {
		wi_error_set_errno(errno);

		return false;
	}
	
	fprintf(fp, "%s", string->string);
	fclose(fp);
	
	if(rename(fullpath, path->string) < 0) {
		wi_error_set_errno(errno);

		(void) unlink(fullpath);
		
		return false;
	}
	
	return true;
}



#pragma mark -

void wi_mutable_string_set_cstring(wi_mutable_string_t *string, const char *othercstring) {
	WI_RUNTIME_ASSERT_MUTABLE(string);
	
	if(string->string != othercstring) {
		string->string[0]	= '\0';
		string->length		= 0;

		wi_mutable_string_append_cstring(string, othercstring);
	}
}



void wi_mutable_string_set_string(wi_mutable_string_t *string, wi_string_t *otherstring) {
	WI_RUNTIME_ASSERT_MUTABLE(string);
	
	wi_mutable_string_set_cstring(string, otherstring->string);
}



void wi_mutable_string_set_format(wi_mutable_string_t *string, wi_string_t *fmt, ...) {
	va_list		ap;
	
	WI_RUNTIME_ASSERT_MUTABLE(string);
	
	va_start(ap, fmt);
	wi_mutable_string_set_format_and_arguments(string, fmt, ap);
	va_end(ap);
}



void wi_mutable_string_set_format_and_arguments(wi_mutable_string_t *string, wi_string_t *fmt, va_list ap) {
	wi_string_t		*newstring;
	
	newstring = wi_string_init_with_format_and_arguments(wi_string_alloc(), fmt, ap);
	wi_mutable_string_set_string(string, newstring);
	wi_release(newstring);
}



#pragma mark -

void wi_mutable_string_append_cstring(wi_mutable_string_t *string, const char *cstring) {
	WI_RUNTIME_ASSERT_MUTABLE(string);
	
	_wi_string_append_bytes(string, cstring, strlen(cstring));
}



void wi_mutable_string_append_bytes(wi_mutable_string_t *string, const void *buffer, wi_uinteger_t length) {
	WI_RUNTIME_ASSERT_MUTABLE(string);
	
	_wi_string_append_bytes(string, buffer, length);
}



void wi_mutable_string_append_string(wi_mutable_string_t *string, wi_string_t *otherstring) {
	WI_RUNTIME_ASSERT_MUTABLE(string);
	
	wi_mutable_string_append_cstring(string, otherstring->string);
}



void wi_mutable_string_append_format(wi_mutable_string_t *string, wi_string_t *fmt, ...) {
	va_list			ap;
	
	WI_RUNTIME_ASSERT_MUTABLE(string);
	
	va_start(ap, fmt);
	_wi_string_append_arguments(string, wi_string_cstring(fmt), ap);
	va_end(ap);
}



void wi_mutable_string_append_format_and_arguments(wi_mutable_string_t *string, wi_string_t *fmt, va_list ap) {
	WI_RUNTIME_ASSERT_MUTABLE(string);
	
	_wi_string_append_arguments(string, wi_string_cstring(fmt), ap);
}



#pragma mark -

void wi_mutable_string_insert_string_at_index(wi_mutable_string_t *string, wi_string_t *otherstring, wi_uinteger_t index) {
	WI_RUNTIME_ASSERT_MUTABLE(string);
	
	wi_mutable_string_insert_cstring_at_index(string, otherstring->string, index);
}



void wi_mutable_string_insert_cstring_at_index(wi_mutable_string_t *string, const char *otherstring, wi_uinteger_t index) {
	wi_uinteger_t		length;
	
	WI_RUNTIME_ASSERT_MUTABLE(string);
	_WI_STRING_INDEX_ASSERT(string, index);
	
	length = strlen(otherstring);
	
	_WI_STRING_GROW(string, length);
	
	memmove(string->string + index + length,
			string->string + index,
			string->length);
	
	memmove(string->string + index, otherstring, length);
	
	string->length += length;
	string->string[string->length] = '\0';
}



#pragma mark -

void wi_mutable_string_replace_characters_in_range_with_string(wi_mutable_string_t *string, wi_range_t range, wi_string_t *replacement) {
	WI_RUNTIME_ASSERT_MUTABLE(string);
	_WI_STRING_RANGE_ASSERT(string, range);
	
	wi_mutable_string_delete_characters_in_range(string, range);
	wi_mutable_string_insert_string_at_index(string, replacement, range.location);
}



void wi_mutable_string_replace_string_with_string(wi_mutable_string_t *string, wi_string_t *target, wi_string_t *replacement, wi_uinteger_t options) {
	wi_range_t		range;
	
	WI_RUNTIME_ASSERT_MUTABLE(string);
	
	while((range = wi_string_range_of_string(string, target, options)).location != WI_NOT_FOUND) {
		wi_mutable_string_delete_characters_in_range(string, range);
		wi_mutable_string_insert_string_at_index(string, replacement, range.location);
	}
}



#pragma mark -

void wi_mutable_string_delete_characters_in_range(wi_mutable_string_t *string, wi_range_t range) {
	WI_RUNTIME_ASSERT_MUTABLE(string);
	_WI_STRING_RANGE_ASSERT(string, range);

	if(range.location + range.length < string->length) {
		memmove(string->string + range.location,
				string->string + range.location + range.length,
				string->length - range.location - range.length);
	}
	
	string->length -= range.length;
	string->string[string->length] = '\0';
}



void wi_mutable_string_delete_characters_from_index(wi_mutable_string_t *string, wi_uinteger_t index) {
	WI_RUNTIME_ASSERT_MUTABLE(string);
	
	wi_mutable_string_delete_characters_in_range(string, wi_make_range(index, string->length - index));
}



void wi_mutable_string_delete_characters_to_index(wi_mutable_string_t *string, wi_uinteger_t index) {
	WI_RUNTIME_ASSERT_MUTABLE(string);
	
	wi_mutable_string_delete_characters_in_range(string, wi_make_range(0, index));
}



static wi_boolean_t _wi_mutable_string_char_is_whitespace(char ch) {
	return (ch == ' ' || ch == '\t' || ch == '\n');
}



void wi_mutable_string_delete_surrounding_whitespace(wi_mutable_string_t *string) {
	WI_RUNTIME_ASSERT_MUTABLE(string);
	
	while(string->length > 0 && _wi_mutable_string_char_is_whitespace(string->string[0]))
		wi_mutable_string_delete_characters_in_range(string, wi_make_range(0, 1));

	while(string->length > 0 && _wi_mutable_string_char_is_whitespace(string->string[string->length - 1]))
		wi_mutable_string_delete_characters_in_range(string, wi_make_range(string->length - 1, 1));
}



#pragma mark -

void wi_mutable_string_normalize_path(wi_mutable_string_t *path) {
	wi_mutable_array_t		*array;
	wi_string_t				*component, *string;
	wi_boolean_t			absolute;
	wi_uinteger_t			i, count;
	
	WI_RUNTIME_ASSERT_MUTABLE(path);
	
	if(wi_string_length(path) == 0 || wi_is_equal(path, WI_STR("/")))
	   return;

	wi_mutable_string_expand_tilde_in_path(path);

	absolute	= wi_string_has_prefix(path, WI_STR("/"));
	array		= _wi_string_path_components(path);
	count		= wi_array_count(array);
	
	for(i = 0; i < count; i++) {
		component = WI_ARRAY(array, i);

		if(wi_string_length(component) == 0 || wi_is_equal(component, WI_STR("/"))) {
			wi_mutable_array_remove_data_at_index(array, i);

			i--;
			count--;
		}
		else if(wi_is_equal(component, WI_STR("."))) {
			wi_mutable_array_remove_data_at_index(array, i);
			
			i--;
			count--;
		}
		else if(absolute && wi_is_equal(component, WI_STR("..")) && i > 0) {
			wi_mutable_array_remove_data_at_index(array, i - 1);
			wi_mutable_array_remove_data_at_index(array, i - 1);
			
			i -= 2;
			count -= 2;
		}
	}
	
	string = wi_array_components_joined_by_string(array, WI_STR("/"));
	
	if(wi_string_has_prefix(path, WI_STR("/")))
		wi_mutable_string_set_format(path, WI_STR("/%@"), string);
	else
		wi_mutable_string_set_string(path, string);
}



#ifdef HAVE_CARBON_CARBON_H

static void _wi_mutable_string_resolve_mac_alias_in_path(wi_mutable_string_t *path) {
	FSRef		fsRef;
	Boolean		isDir, isAlias;

	if(FSPathMakeRef((UInt8 *) path->string, &fsRef, NULL) != noErr)
		return;
	
	if(FSIsAliasFile(&fsRef, &isAlias, &isDir) != noErr)
		return;
	
	if(!isAlias)
		return;

	if(FSResolveAliasFileWithMountFlags(&fsRef, true, &isDir, &isAlias, kResolveAliasFileNoUI | kResolveAliasTryFileIDFirst) != noErr)
		return;

	if(FSRefMakePath(&fsRef, (UInt8 *) path->string, WI_PATH_SIZE) != noErr)
		return;
	
	path->length = strlen(path->string);
}

#endif



void wi_mutable_string_resolve_aliases_in_path(wi_mutable_string_t *path) {
	wi_mutable_string_t		*partialpath;
	wi_string_t				*component;
	wi_array_t				*components;
	wi_uinteger_t			i, count;
	
	WI_RUNTIME_ASSERT_MUTABLE(path);
	
	components		= wi_string_path_components(path);
	count			= wi_array_count(components);
	partialpath		= wi_string_init_with_capacity(wi_mutable_string_alloc(), WI_PATH_SIZE);
	
	for(i = 0; i < count; i++) {
		component = WI_ARRAY(components, i);
		
		wi_mutable_string_append_path_component(partialpath, component);
		
#ifdef HAVE_CARBON_CARBON_H
		_wi_mutable_string_resolve_mac_alias_in_path(partialpath);
#endif
	}
	
	wi_mutable_string_set_string(path, partialpath);

	wi_release(partialpath);
}



void wi_mutable_string_expand_tilde_in_path(wi_mutable_string_t *path) {
	wi_array_t		*array;
	wi_string_t		*component, *string;
	struct passwd	*user;
	wi_uinteger_t	length;
	
	WI_RUNTIME_ASSERT_MUTABLE(path);
	
	if(!wi_string_has_prefix(path, WI_STR("~")))
		return;

	array		= wi_string_path_components(path);
	component	= WI_ARRAY(array, 0);
	length		= wi_string_length(component);
	
	if(length == 1) {
		user = getpwuid(getuid());
	} else {
		wi_mutable_string_delete_characters_to_index(component, 1);
		
		user = getpwnam(wi_string_cstring(component));
	}
	
	if(user) {
		wi_mutable_string_delete_characters_to_index(path, length);
		
		string = wi_string_init_with_cstring(wi_string_alloc(), user->pw_dir);
		wi_mutable_string_insert_string_at_index(path, string, 0);
		wi_release(string);
	}
}



void wi_mutable_string_append_path_component(wi_mutable_string_t *path, wi_string_t *component) {
	WI_RUNTIME_ASSERT_MUTABLE(path);
	
	if(wi_string_length(path) == 0) {
		wi_mutable_string_append_string(path, component);
	}
	else if(wi_string_has_suffix(path, WI_STR("/"))) {
		if(wi_string_has_prefix(component, WI_STR("/")))
		   wi_mutable_string_delete_characters_from_index(path, path->length - 1);

		wi_mutable_string_append_string(path, component);
	}
	else if(!wi_is_equal(component, WI_STR("/"))) {
	   wi_mutable_string_append_format(path, WI_STR("/%@"), component);
	}
}



void wi_mutable_string_append_path_components(wi_mutable_string_t *path, wi_array_t *components) {
	wi_uinteger_t		i, count;
	
	WI_RUNTIME_ASSERT_MUTABLE(path);
	
	count = wi_array_count(components);
	
	for(i = 0; i < count; i++)
		wi_mutable_string_append_path_component(path, WI_ARRAY(components, i));
}



void wi_mutable_string_delete_last_path_component(wi_mutable_string_t *path) {
	wi_mutable_array_t		*array;
	wi_string_t				*string;
	wi_uinteger_t			count;
	
	WI_RUNTIME_ASSERT_MUTABLE(path);
	
	if(wi_is_equal(path, WI_STR("/")))
		return;
	
	array = _wi_string_path_components(path);
	count = wi_array_count(array);
	
	if(count > 0) {
		wi_mutable_array_remove_data_at_index(array, count - 1);
		
		string = wi_array_components_joined_by_string(array, WI_STR("/"));
		wi_mutable_string_set_string(path, string);
		wi_mutable_string_normalize_path(path);
	}
}



void wi_mutable_string_append_path_extension(wi_mutable_string_t *path, wi_string_t *extension) {
	WI_RUNTIME_ASSERT_MUTABLE(path);
	
	wi_mutable_string_append_format(path, WI_STR(".%@"), extension);
}



void wi_mutable_string_delete_path_extension(wi_mutable_string_t *path) {
	wi_uinteger_t	index;
	
	WI_RUNTIME_ASSERT_MUTABLE(path);
	
	index = wi_string_index_of_char(path, '.', WI_STRING_BACKWARDS);

	if(index != WI_NOT_FOUND)
		wi_mutable_string_delete_characters_from_index(path, index);
}



#pragma mark -

#ifdef WI_ICONV

void wi_mutable_string_convert_encoding(wi_mutable_string_t *string, wi_string_encoding_t *from, wi_string_encoding_t *to) {
	char		*in, *out, *buffer;
	size_t		bytes, inbytes, outbytes, inbytesleft, outbytesleft;
	iconv_t		conv;
	
	WI_RUNTIME_ASSERT_MUTABLE(string);
	
	conv = iconv_open(wi_string_cstring(to->encoding), wi_string_cstring(from->encoding));
	
	if(conv == (iconv_t) -1)
		return;
	
	inbytes = inbytesleft = string->length;
	outbytes = outbytesleft = string->length * 4;
	
	buffer = wi_malloc(outbytes);
	
	in = string->string;
	out = buffer;

	bytes = iconv(conv, (void *) &in, &inbytesleft, (void *) &out, &outbytesleft);

	if(bytes == (size_t) -1) {
		wi_error_set_errno(errno);
	} else {
		string->string[0]	= '\0';
		string->length		= 0;

		_wi_string_append_bytes(string, buffer, outbytes - outbytesleft);
	}
	
	wi_free(buffer);
	
	iconv_close(conv);
}

#endif

#pragma mark -

#ifdef WI_ICONV

wi_runtime_id_t wi_string_encoding_runtime_id(void) {
	return _wi_string_encoding_runtime_id;
}



#pragma mark -

wi_string_encoding_t * wi_string_encoding_with_charset(wi_string_t *charset, wi_string_encoding_options_t options) {
	return wi_autorelease(wi_string_encoding_init_with_charset(wi_string_encoding_alloc(), charset, options));
}



#pragma mark -

wi_string_encoding_t * wi_string_encoding_alloc(void) {
	return wi_runtime_create_instance_with_options(_wi_string_encoding_runtime_id, sizeof(wi_string_encoding_t), WI_RUNTIME_OPTION_IMMUTABLE);
}



wi_string_encoding_t * wi_string_encoding_init_with_charset(wi_string_encoding_t *encoding, wi_string_t *charset, wi_string_encoding_options_t options) {
	iconv_t			iconv;
	
	encoding->charset		= wi_copy(charset);
	encoding->encoding		= wi_mutable_copy(charset);
	encoding->options		= options;
	
	if(options & WI_STRING_ENCODING_IGNORE)
		wi_mutable_string_append_string(encoding->encoding, WI_STR("//IGNORE"));
		
	if(options & WI_STRING_ENCODING_TRANSLITERATE)
		wi_mutable_string_append_string(encoding->encoding, WI_STR("//TRANSLIT"));
	
	iconv = iconv_open(wi_string_cstring(encoding->encoding), wi_string_cstring(encoding->encoding));
	
	if(iconv == (iconv_t) -1) {
		wi_error_set_errno(errno);

		wi_release(encoding);
		
		return NULL;
	}
	
	iconv_close(iconv);
	
	return encoding;
}



static void _wi_string_encoding_dealloc(wi_runtime_instance_t *instance) {
	wi_string_encoding_t		*encoding = instance;
	
	wi_release(encoding->charset);
	wi_release(encoding->encoding);
}



static wi_string_t * _wi_string_encoding_description(wi_runtime_instance_t *instance) {
	wi_string_encoding_t		*encoding = instance;
	
	return wi_string_with_format(WI_STR("<%@ %p>{encoding = %@}"),
		wi_runtime_class_name(encoding),
		encoding,
		encoding->encoding);
}



#pragma mark -

wi_string_t * wi_string_encoding_charset(wi_string_encoding_t *encoding) {
	return encoding->charset;
}

#endif /* WI_ICONV */
