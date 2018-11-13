/* $Id$ */

/*
 *  Copyright (c) 2007-2009 Axel Andersson
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

#ifndef WI_P7_MESSAGE_H
#define WI_P7_MESSAGE_H 1

#include <wired/wi-base.h>
#include <wired/wi-data.h>
#include <wired/wi-date.h>
#include <wired/wi-dictionary.h>
#include <wired/wi-number.h>
#include <wired/wi-runtime.h>
#include <wired/wi-uuid.h>

typedef wi_boolean_t				wi_p7_boolean_t;
typedef uint32_t					wi_p7_enum_t;
typedef int32_t						wi_p7_int32_t;
typedef uint32_t					wi_p7_uint32_t;
typedef int64_t						wi_p7_int64_t;
typedef uint64_t					wi_p7_uint64_t;
typedef double						wi_p7_double_t;
typedef uint64_t					wi_p7_oobdata_t;


enum _wi_p7_type {
	WI_P7_BOOL						= 1,
	WI_P7_ENUM						= 2,
	WI_P7_INT32						= 3,
	WI_P7_UINT32					= 4,
	WI_P7_INT64						= 5,
	WI_P7_UINT64					= 6,
	WI_P7_DOUBLE					= 7,
	WI_P7_STRING					= 8,
	WI_P7_UUID						= 9,
	WI_P7_DATE						= 10,
	WI_P7_DATA						= 11,
	WI_P7_OOBDATA					= 12,
	WI_P7_LIST						= 13
};
typedef enum _wi_p7_type			wi_p7_type_t;

enum _wi_p7_serialization {
	WI_P7_UNKNOWN					= 0,
	WI_P7_XML,
	WI_P7_BINARY
};
typedef enum _wi_p7_serialization	wi_p7_serialization_t;


WI_EXPORT wi_runtime_id_t			wi_p7_message_runtime_id(void);

WI_EXPORT wi_p7_message_t *			wi_p7_message_with_name(wi_string_t *, wi_p7_spec_t *);
WI_EXPORT wi_p7_message_t *			wi_p7_message_with_data(wi_data_t *, wi_p7_serialization_t, wi_p7_spec_t *);
WI_EXPORT wi_p7_message_t *			wi_p7_message_with_bytes(const void *, wi_uinteger_t, wi_p7_serialization_t, wi_p7_spec_t *);

WI_EXPORT wi_p7_message_t *			wi_p7_message_alloc(void);
WI_EXPORT wi_p7_message_t *			wi_p7_message_init_with_name(wi_p7_message_t *, wi_string_t *, wi_p7_spec_t *);
WI_EXPORT wi_p7_message_t *			wi_p7_message_init_with_data(wi_p7_message_t *, wi_data_t *, wi_p7_serialization_t, wi_p7_spec_t *);
WI_EXPORT wi_p7_message_t *			wi_p7_message_init_with_bytes(wi_p7_message_t *, const void *, wi_uinteger_t, wi_p7_serialization_t, wi_p7_spec_t *);

WI_EXPORT wi_boolean_t				wi_p7_message_set_name(wi_p7_message_t *, wi_string_t *);
WI_EXPORT wi_string_t *				wi_p7_message_name(wi_p7_message_t *);

WI_EXPORT wi_dictionary_t *			wi_p7_message_fields(wi_p7_message_t *);
WI_EXPORT wi_data_t *				wi_p7_message_data_with_serialization(wi_p7_message_t *, wi_p7_serialization_t);

WI_EXPORT wi_boolean_t				wi_p7_message_set_bool_for_name(wi_p7_message_t *, wi_p7_boolean_t, wi_string_t *);
WI_EXPORT wi_boolean_t				wi_p7_message_get_bool_for_name(wi_p7_message_t *, wi_p7_boolean_t *, wi_string_t *);
WI_EXPORT wi_boolean_t				wi_p7_message_set_enum_for_name(wi_p7_message_t *, wi_p7_enum_t, wi_string_t *);
WI_EXPORT wi_boolean_t				wi_p7_message_get_enum_for_name(wi_p7_message_t *, wi_p7_enum_t *, wi_string_t *);
WI_EXPORT wi_boolean_t				wi_p7_message_set_int32_for_name(wi_p7_message_t *, wi_p7_int32_t, wi_string_t *);
WI_EXPORT wi_boolean_t				wi_p7_message_get_int32_for_name(wi_p7_message_t *, wi_p7_int32_t *, wi_string_t *);
WI_EXPORT wi_boolean_t				wi_p7_message_set_uint32_for_name(wi_p7_message_t *, wi_p7_uint32_t, wi_string_t *);
WI_EXPORT wi_boolean_t				wi_p7_message_get_uint32_for_name(wi_p7_message_t *, wi_p7_uint32_t *, wi_string_t *);
WI_EXPORT wi_boolean_t				wi_p7_message_set_int64_for_name(wi_p7_message_t *, wi_p7_int64_t, wi_string_t *);
WI_EXPORT wi_boolean_t				wi_p7_message_get_int64_for_name(wi_p7_message_t *, wi_p7_int64_t *, wi_string_t *);
WI_EXPORT wi_boolean_t				wi_p7_message_set_uint64_for_name(wi_p7_message_t *, wi_p7_uint64_t, wi_string_t *);
WI_EXPORT wi_boolean_t				wi_p7_message_get_uint64_for_name(wi_p7_message_t *, wi_p7_uint64_t *, wi_string_t *);
WI_EXPORT wi_boolean_t				wi_p7_message_set_double_for_name(wi_p7_message_t *, wi_p7_double_t, wi_string_t *);
WI_EXPORT wi_boolean_t				wi_p7_message_get_double_for_name(wi_p7_message_t *, wi_p7_double_t *, wi_string_t *);
WI_EXPORT wi_boolean_t				wi_p7_message_set_oobdata_for_name(wi_p7_message_t *, wi_p7_oobdata_t, wi_string_t *);
WI_EXPORT wi_boolean_t				wi_p7_message_get_oobdata_for_name(wi_p7_message_t *, wi_p7_oobdata_t *, wi_string_t *);

WI_EXPORT wi_boolean_t				wi_p7_message_set_string_for_name(wi_p7_message_t *, wi_string_t *, wi_string_t *);
WI_EXPORT wi_string_t *				wi_p7_message_string_for_name(wi_p7_message_t *, wi_string_t *);
WI_EXPORT wi_boolean_t				wi_p7_message_set_data_for_name(wi_p7_message_t *, wi_data_t *, wi_string_t *);
WI_EXPORT wi_data_t *				wi_p7_message_data_for_name(wi_p7_message_t *, wi_string_t *);
WI_EXPORT wi_boolean_t				wi_p7_message_set_number_for_name(wi_p7_message_t *, wi_number_t *, wi_string_t *);
WI_EXPORT wi_number_t *				wi_p7_message_number_for_name(wi_p7_message_t *, wi_string_t *);
WI_EXPORT wi_boolean_t				wi_p7_message_set_enum_name_for_name(wi_p7_message_t *, wi_string_t *, wi_string_t *);
WI_EXPORT wi_string_t *				wi_p7_message_enum_name_for_name(wi_p7_message_t *, wi_string_t *);
WI_EXPORT wi_boolean_t				wi_p7_message_set_uuid_for_name(wi_p7_message_t *, wi_uuid_t *, wi_string_t *);
WI_EXPORT wi_uuid_t *				wi_p7_message_uuid_for_name(wi_p7_message_t *, wi_string_t *);
WI_EXPORT wi_boolean_t				wi_p7_message_set_date_for_name(wi_p7_message_t *, wi_date_t *, wi_string_t *);
WI_EXPORT wi_date_t *				wi_p7_message_date_for_name(wi_p7_message_t *, wi_string_t *);
WI_EXPORT wi_boolean_t				wi_p7_message_set_list_for_name(wi_p7_message_t *, wi_array_t *, wi_string_t *);
WI_EXPORT wi_array_t *				wi_p7_message_list_for_name(wi_p7_message_t *, wi_string_t *);

WI_EXPORT wi_boolean_t				wi_p7_message_write_binary(wi_p7_message_t *, const void *, uint32_t, wi_uinteger_t);
WI_EXPORT wi_boolean_t				wi_p7_message_read_binary(wi_p7_message_t *, unsigned char **, uint32_t *, wi_uinteger_t);


extern wi_boolean_t					wi_p7_message_debug;

#endif /* WI_P7_MESSAGE_H */
