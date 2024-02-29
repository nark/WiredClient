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

#ifndef WI_P7_SPEC_H
#define WI_P7_SPEC_H 1

#include <wired/wi-base.h>
#include <wired/wi-runtime.h>

enum _wi_p7_originator {
	WI_P7_BOTH,
	WI_P7_SERVER,
	WI_P7_CLIENT
};
typedef enum _wi_p7_originator			wi_p7_originator_t;

typedef struct _wi_p7_spec_type			wi_p7_spec_type_t;
typedef struct _wi_p7_spec_field		wi_p7_spec_field_t;
typedef struct _wi_p7_spec_message		wi_p7_spec_message_t;
typedef struct _wi_p7_spec_parameter	wi_p7_spec_parameter_t;


WI_EXPORT wi_runtime_id_t				wi_p7_spec_runtime_id(void);

WI_EXPORT wi_p7_spec_t *				wi_p7_spec_builtin_spec(void);
WI_EXPORT wi_p7_originator_t			wi_p7_spec_opposite_originator(wi_p7_originator_t);

WI_EXPORT wi_p7_spec_t *				wi_p7_spec_alloc(void);
WI_EXPORT wi_p7_spec_t *				wi_p7_spec_init_with_file(wi_p7_spec_t *, wi_string_t *, wi_p7_originator_t);
WI_EXPORT wi_p7_spec_t *				wi_p7_spec_init_with_string(wi_p7_spec_t *, wi_string_t *, wi_p7_originator_t);

WI_EXPORT wi_boolean_t					wi_p7_spec_is_compatible_with_spec(wi_p7_spec_t *, wi_p7_spec_t *);
WI_EXPORT void							wi_p7_spec_merge_with_spec(wi_p7_spec_t *, wi_p7_spec_t *);

WI_EXPORT wi_string_t *					wi_p7_spec_name(wi_p7_spec_t *);
WI_EXPORT wi_string_t *					wi_p7_spec_version(wi_p7_spec_t *);
WI_EXPORT wi_p7_originator_t			wi_p7_spec_originator(wi_p7_spec_t *);
WI_EXPORT wi_string_t *					wi_p7_spec_xml(wi_p7_spec_t *);
WI_EXPORT wi_p7_spec_type_t *			wi_p7_spec_type_with_name(wi_p7_spec_t *, wi_string_t *);
WI_EXPORT wi_p7_spec_type_t *			wi_p7_spec_type_with_id(wi_p7_spec_t *, wi_uinteger_t);
WI_EXPORT wi_array_t *					wi_p7_spec_fields(wi_p7_spec_t *);
WI_EXPORT wi_p7_spec_field_t *			wi_p7_spec_field_with_name(wi_p7_spec_t *, wi_string_t *);
WI_EXPORT wi_p7_spec_field_t *			wi_p7_spec_field_with_id(wi_p7_spec_t *, wi_uinteger_t);
WI_EXPORT wi_array_t *					wi_p7_spec_messages(wi_p7_spec_t *);
WI_EXPORT wi_p7_spec_message_t *		wi_p7_spec_message_with_name(wi_p7_spec_t *, wi_string_t *);
WI_EXPORT wi_p7_spec_message_t *		wi_p7_spec_message_with_id(wi_p7_spec_t *, wi_uinteger_t);

WI_EXPORT wi_boolean_t					wi_p7_spec_verify_message(wi_p7_spec_t *, wi_p7_message_t *);


WI_EXPORT wi_runtime_id_t				wi_p7_spec_type_runtime_id(void);

WI_EXPORT wi_string_t *					wi_p7_spec_type_name(wi_p7_spec_type_t *);
WI_EXPORT wi_uinteger_t					wi_p7_spec_type_id(wi_p7_spec_type_t *);
WI_EXPORT wi_uinteger_t					wi_p7_spec_type_size(wi_p7_spec_type_t *);


WI_EXPORT wi_runtime_id_t				wi_p7_spec_field_runtime_id(void);

WI_EXPORT wi_string_t *					wi_p7_spec_field_name(wi_p7_spec_field_t *);
WI_EXPORT wi_uinteger_t					wi_p7_spec_field_id(wi_p7_spec_field_t *);
WI_EXPORT wi_uinteger_t					wi_p7_spec_field_size(wi_p7_spec_field_t *);
WI_EXPORT wi_p7_spec_type_t *			wi_p7_spec_field_type(wi_p7_spec_field_t *);
WI_EXPORT wi_p7_spec_type_t *			wi_p7_spec_field_listtype(wi_p7_spec_field_t *);
WI_EXPORT wi_dictionary_t *				wi_p7_spec_field_enums_by_name(wi_p7_spec_field_t *);
WI_EXPORT wi_dictionary_t *				wi_p7_spec_field_enums_by_value(wi_p7_spec_field_t *);


WI_EXPORT wi_runtime_id_t				wi_p7_spec_message_runtime_id(void);

WI_EXPORT wi_string_t *					wi_p7_spec_message_name(wi_p7_spec_message_t *);
WI_EXPORT wi_uinteger_t					wi_p7_spec_message_id(wi_p7_spec_message_t *);
WI_EXPORT wi_array_t *					wi_p7_spec_message_parameters(wi_p7_spec_message_t *);


WI_EXPORT wi_runtime_id_t				wi_p7_spec_parameter_runtime_id(void);

WI_EXPORT wi_p7_spec_field_t *			wi_p7_spec_parameter_field(wi_p7_spec_parameter_t *);
WI_EXPORT wi_boolean_t					wi_p7_spec_parameter_required(wi_p7_spec_parameter_t *);

#endif /* WI_P7_SPEC_H */
