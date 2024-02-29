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

/**
 * @file wi-string.h 
 * @brief This file provide support for string objects.
 * @author Axel Andersson, Rafaël Warnault
 * @version 2.0
 *
 */

#ifndef WI_STRING_H
#define WI_STRING_H 1

#include <stdarg.h>
#include <wired/wi-data.h>
#include <wired/wi-base.h>
#include <wired/wi-pool.h>
#include <wired/wi-runtime.h>

#define WI_STR(cstring) \
	_wi_string_constant_string((cstring))


typedef struct _wi_string_encoding			wi_string_encoding_t;


enum _wi_string_options {
	WI_STRING_BACKWARDS						= (1 << 0),
	WI_STRING_CASE_INSENSITIVE				= (1 << 1),
	WI_STRING_SMART_CASE_INSENSITIVE		= (1 << 2)
};
typedef enum _wi_string_options				wi_string_options_t;


WI_EXPORT wi_runtime_id_t					wi_string_runtime_id(void);

WI_EXPORT wi_string_t *						wi_string(void);
WI_EXPORT wi_string_t *						wi_string_with_cstring(const char *);
WI_EXPORT wi_string_t *						wi_string_with_cstring_no_copy(char *, wi_boolean_t);
WI_EXPORT wi_string_t *						wi_string_with_format(wi_string_t *, ...);
WI_EXPORT wi_string_t *						wi_string_with_format_and_arguments(wi_string_t *, va_list);
WI_EXPORT wi_string_t *						wi_string_with_data(wi_data_t *);
WI_EXPORT wi_string_t *						wi_string_with_bytes(const void *, wi_uinteger_t);
WI_EXPORT wi_string_t *						wi_string_with_bytes_no_copy(void *, wi_uinteger_t, wi_boolean_t);
WI_EXPORT wi_string_t *						wi_string_with_base64(wi_string_t *);
WI_EXPORT wi_mutable_string_t *				wi_mutable_string(void);
WI_EXPORT wi_mutable_string_t *				wi_mutable_string_with_format(wi_string_t *, ...);

WI_EXPORT wi_string_t *						wi_string_alloc(void);
WI_EXPORT wi_mutable_string_t *				wi_mutable_string_alloc(void);
WI_EXPORT wi_string_t *						wi_string_init(wi_string_t *);
WI_EXPORT wi_string_t *						wi_string_init_with_capacity(wi_string_t *, wi_uinteger_t);
WI_EXPORT wi_string_t *						wi_string_init_with_cstring(wi_string_t *, const char *);
WI_EXPORT wi_string_t *						wi_string_init_with_cstring_no_copy(wi_string_t *, char *, wi_boolean_t);
WI_EXPORT wi_string_t *						wi_string_init_with_data(wi_string_t *, wi_data_t *);
WI_EXPORT wi_string_t *						wi_string_init_with_bytes(wi_string_t *, const void *, wi_uinteger_t);
WI_EXPORT wi_string_t *						wi_string_init_with_bytes_no_copy(wi_string_t *, void *, wi_uinteger_t, wi_boolean_t);
WI_EXPORT wi_string_t *						wi_string_init_with_random_bytes(wi_string_t *, wi_uinteger_t);
WI_EXPORT wi_string_t *						wi_string_init_with_format(wi_string_t *, wi_string_t *, ...);
WI_EXPORT wi_string_t *						wi_string_init_with_format_and_arguments(wi_string_t *, wi_string_t *, va_list);
WI_EXPORT wi_string_t *						wi_string_init_with_base64(wi_string_t *, wi_string_t *);
WI_EXPORT wi_string_t *						wi_string_init_with_contents_of_file(wi_string_t *, wi_string_t *);

WI_EXPORT wi_integer_t						wi_string_compare(wi_runtime_instance_t *, wi_runtime_instance_t *);
WI_EXPORT wi_integer_t						wi_string_case_insensitive_compare(wi_runtime_instance_t *, wi_runtime_instance_t *);

WI_EXPORT wi_uinteger_t						wi_string_length(wi_string_t *);
WI_EXPORT const char *						wi_string_cstring(wi_string_t *);
WI_EXPORT char								wi_string_character_at_index(wi_string_t *, wi_uinteger_t);

WI_EXPORT wi_string_t *						_wi_string_constant_string(const char *);

WI_EXPORT wi_string_t *						wi_string_by_appending_cstring(wi_string_t *, const char *);
WI_EXPORT wi_string_t *						wi_string_by_appending_bytes(wi_string_t *, const void *, wi_uinteger_t);
WI_EXPORT wi_string_t *						wi_string_by_appending_string(wi_string_t *, wi_string_t *);
WI_EXPORT wi_string_t *						wi_string_by_appending_format(wi_string_t *, wi_string_t *, ...);
WI_EXPORT wi_string_t *						wi_string_by_appending_format_and_arguments(wi_string_t *, wi_string_t *, va_list);

WI_EXPORT wi_string_t *						wi_string_by_inserting_string_at_index(wi_string_t *, wi_string_t *, wi_uinteger_t);

WI_EXPORT wi_string_t *						wi_string_by_replacing_characters_in_range_with_string(wi_string_t *, wi_range_t, wi_string_t *);
WI_EXPORT wi_string_t *						wi_string_by_replacing_string_with_string(wi_string_t *, wi_string_t *, wi_string_t *, wi_uinteger_t);

WI_EXPORT wi_string_t *						wi_string_by_deleting_characters_in_range(wi_string_t *, wi_range_t);
WI_EXPORT wi_string_t *						wi_string_by_deleting_characters_from_index(wi_string_t *, wi_uinteger_t);
WI_EXPORT wi_string_t *						wi_string_by_deleting_characters_to_index(wi_string_t *, wi_uinteger_t);
WI_EXPORT wi_string_t *						wi_string_by_deleting_surrounding_whitespace(wi_string_t *);

WI_EXPORT wi_string_t *						wi_string_substring_with_range(wi_string_t *, wi_range_t);
WI_EXPORT wi_string_t *						wi_string_substring_from_index(wi_string_t *, wi_uinteger_t);
WI_EXPORT wi_string_t *						wi_string_substring_to_index(wi_string_t *, wi_uinteger_t);
WI_EXPORT wi_array_t *						wi_string_components_separated_by_string(wi_string_t *, wi_string_t *);

WI_EXPORT wi_range_t						wi_string_range_of_string(wi_string_t *, wi_string_t *, wi_uinteger_t);
WI_EXPORT wi_range_t						wi_string_range_of_string_in_range(wi_string_t *, wi_string_t *, wi_uinteger_t, wi_range_t);
WI_EXPORT wi_uinteger_t						wi_string_index_of_string(wi_string_t *, wi_string_t *, wi_uinteger_t);
WI_EXPORT wi_uinteger_t						wi_string_index_of_string_in_range(wi_string_t *, wi_string_t *, wi_uinteger_t, wi_range_t);
WI_EXPORT wi_uinteger_t						wi_string_index_of_char(wi_string_t *, int, wi_uinteger_t);
WI_EXPORT wi_boolean_t						wi_string_contains_string(wi_string_t *, wi_string_t *, wi_uinteger_t);
WI_EXPORT wi_boolean_t						wi_string_has_prefix(wi_string_t *, wi_string_t *);
WI_EXPORT wi_boolean_t						wi_string_has_suffix(wi_string_t *, wi_string_t *);

WI_EXPORT wi_string_t *						wi_string_lowercase_string(wi_string_t *);
WI_EXPORT wi_string_t *						wi_string_uppercase_string(wi_string_t *);

WI_EXPORT wi_array_t *						wi_string_path_components(wi_string_t *);
WI_EXPORT wi_string_t *						wi_string_by_normalizing_path(wi_string_t *);
WI_EXPORT wi_string_t *						wi_string_by_resolving_aliases_in_path(wi_string_t *);
WI_EXPORT wi_string_t *						wi_string_by_expanding_tilde_in_path(wi_string_t *);
WI_EXPORT wi_string_t *						wi_string_by_appending_path_component(wi_string_t *, wi_string_t *);
WI_EXPORT wi_string_t *						wi_string_by_appending_path_components(wi_string_t *, wi_array_t *);
WI_EXPORT wi_string_t *						wi_string_last_path_component(wi_string_t *);
WI_EXPORT wi_string_t *						wi_string_by_deleting_last_path_component(wi_string_t *);
WI_EXPORT wi_string_t *						wi_string_by_appending_path_extension(wi_string_t *, wi_string_t *);
WI_EXPORT wi_string_t *						wi_string_path_extension(wi_string_t *);
WI_EXPORT wi_string_t *						wi_string_by_deleting_path_extension(wi_string_t *);

WI_EXPORT wi_boolean_t						wi_string_bool(wi_string_t *);
WI_EXPORT int32_t							wi_string_int32(wi_string_t *);
WI_EXPORT uint32_t							wi_string_uint32(wi_string_t *);
WI_EXPORT int64_t							wi_string_int64(wi_string_t *);
WI_EXPORT uint64_t							wi_string_uint64(wi_string_t *);
WI_EXPORT wi_integer_t						wi_string_integer(wi_string_t *);
WI_EXPORT wi_uinteger_t						wi_string_uinteger(wi_string_t *);
WI_EXPORT float								wi_string_float(wi_string_t *);
WI_EXPORT double							wi_string_double(wi_string_t *);

WI_EXPORT wi_data_t *						wi_string_data(wi_string_t *);
WI_EXPORT wi_string_t *						wi_string_md5(wi_string_t *);
WI_EXPORT wi_string_t *						wi_string_sha1(wi_string_t *);
WI_EXPORT wi_string_t *                     wi_string_sha256(wi_string_t *string);
WI_EXPORT wi_string_t *                     wi_string_sha512(wi_string_t *string);
WI_EXPORT wi_string_t *						wi_string_base64(wi_string_t *);

WI_EXPORT wi_string_t *						wi_string_by_converting_encoding(wi_string_t *, wi_string_encoding_t *, wi_string_encoding_t *);

WI_EXPORT wi_boolean_t						wi_string_write_to_file(wi_string_t *, wi_string_t *);

WI_EXPORT void								wi_mutable_string_set_cstring(wi_string_t *, const char *);
WI_EXPORT void								wi_mutable_string_set_string(wi_string_t *, wi_string_t *);
WI_EXPORT void								wi_mutable_string_set_format(wi_string_t *, wi_string_t *, ...);
WI_EXPORT void								wi_mutable_string_set_format_and_arguments(wi_string_t *, wi_string_t *, va_list);

WI_EXPORT void								wi_mutable_string_append_cstring(wi_mutable_string_t *, const char *);
WI_EXPORT void								wi_mutable_string_append_bytes(wi_mutable_string_t *, const void *, wi_uinteger_t);
WI_EXPORT void								wi_mutable_string_append_string(wi_mutable_string_t *, wi_string_t *);
WI_EXPORT void								wi_mutable_string_append_format(wi_mutable_string_t *, wi_string_t *, ...);
WI_EXPORT void								wi_mutable_string_append_format_and_arguments(wi_mutable_string_t *, wi_string_t *, va_list);

WI_EXPORT void								wi_mutable_string_insert_string_at_index(wi_mutable_string_t *, wi_string_t *, wi_uinteger_t);
WI_EXPORT void								wi_mutable_string_insert_cstring_at_index(wi_mutable_string_t *, const char *, wi_uinteger_t);

WI_EXPORT void								wi_mutable_string_replace_characters_in_range_with_string(wi_mutable_string_t *, wi_range_t, wi_string_t *);
WI_EXPORT void								wi_mutable_string_replace_string_with_string(wi_mutable_string_t *, wi_string_t *, wi_string_t *, wi_uinteger_t);

WI_EXPORT void								wi_mutable_string_delete_characters_in_range(wi_mutable_string_t *, wi_range_t);
WI_EXPORT void								wi_mutable_string_delete_characters_from_index(wi_mutable_string_t *, wi_uinteger_t);
WI_EXPORT void								wi_mutable_string_delete_characters_to_index(wi_mutable_string_t *, wi_uinteger_t);
WI_EXPORT void								wi_mutable_string_delete_surrounding_whitespace(wi_mutable_string_t *);

WI_EXPORT void								wi_mutable_string_normalize_path(wi_mutable_string_t *);
WI_EXPORT void								wi_mutable_string_resolve_aliases_in_path(wi_mutable_string_t *);
WI_EXPORT void								wi_mutable_string_expand_tilde_in_path(wi_mutable_string_t *);
WI_EXPORT void								wi_mutable_string_append_path_component(wi_mutable_string_t *, wi_string_t *);
WI_EXPORT void								wi_mutable_string_append_path_components(wi_mutable_string_t *, wi_array_t *);
WI_EXPORT void								wi_mutable_string_delete_last_path_component(wi_mutable_string_t *);
WI_EXPORT void								wi_mutable_string_append_path_extension(wi_mutable_string_t *, wi_string_t *);
WI_EXPORT void								wi_mutable_string_delete_path_extension(wi_mutable_string_t *);

WI_EXPORT void								wi_mutable_string_convert_encoding(wi_mutable_string_t *, wi_string_encoding_t *, wi_string_encoding_t *);


enum _wi_string_encoding_options {
	WI_STRING_ENCODING_IGNORE				= (1 << 0),
	WI_STRING_ENCODING_TRANSLITERATE		= (1 << 1),
	WI_STRING_ENCODING_ALL					= (WI_STRING_ENCODING_IGNORE | WI_STRING_ENCODING_TRANSLITERATE)
};
typedef enum _wi_string_encoding_options	wi_string_encoding_options_t;


WI_EXPORT wi_runtime_id_t					wi_string_encoding_runtime_id(void);

WI_EXPORT wi_string_encoding_t *			wi_string_encoding_with_charset(wi_string_t *, wi_string_encoding_options_t);

WI_EXPORT wi_string_encoding_t *			wi_string_encoding_alloc(void);
WI_EXPORT wi_string_encoding_t *			wi_string_encoding_init_with_charset(wi_string_encoding_t *, wi_string_t *, wi_string_encoding_options_t);

WI_EXPORT wi_string_t *						wi_string_encoding_charset(wi_string_encoding_t *);

#endif /* WI_STRING_H */
