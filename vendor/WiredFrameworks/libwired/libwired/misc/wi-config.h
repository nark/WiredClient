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

#ifndef WI_CONFIG_H
#define WI_CONFIG_H 1

#include <wired/wi-base.h>
#include <wired/wi-dictionary.h>
#include <wired/wi-regexp.h>
#include <wired/wi-runtime.h>
#include <wired/wi-set.h>

enum _wi_config_type {
	WI_CONFIG_INTEGER,
	WI_CONFIG_BOOL,
	WI_CONFIG_STRING,
	WI_CONFIG_STRINGLIST,
	WI_CONFIG_PATH,
	WI_CONFIG_USER,
	WI_CONFIG_GROUP,
	WI_CONFIG_PORT,
	WI_CONFIG_REGEXP,
	WI_CONFIG_TIME_INTERVAL
};
typedef enum _wi_config_type		wi_config_type_t;

typedef struct _wi_config			wi_config_t;


WI_EXPORT wi_runtime_id_t			wi_config_runtime_id(void);

WI_EXPORT wi_config_t *				wi_config_alloc(void);
WI_EXPORT wi_config_t *				wi_config_init_with_path(wi_config_t *, wi_string_t *, wi_dictionary_t *, wi_dictionary_t *);

WI_EXPORT wi_boolean_t				wi_config_read_file(wi_config_t *);
WI_EXPORT wi_boolean_t				wi_config_write_file(wi_config_t *);

WI_EXPORT void						wi_config_note_change(wi_config_t *, wi_string_t *);
WI_EXPORT void						wi_config_clear_changes(wi_config_t *);
WI_EXPORT wi_set_t *				wi_config_changes(wi_config_t *);

WI_EXPORT void						wi_config_set_instance_for_name(wi_config_t *, wi_runtime_instance_t *, wi_string_t *);

WI_EXPORT wi_integer_t				wi_config_integer_for_name(wi_config_t *, wi_string_t *);
WI_EXPORT wi_boolean_t				wi_config_bool_for_name(wi_config_t *, wi_string_t *);
WI_EXPORT wi_string_t *				wi_config_string_for_name(wi_config_t *, wi_string_t *);
WI_EXPORT wi_array_t *				wi_config_stringlist_for_name(wi_config_t *, wi_string_t *);
WI_EXPORT wi_string_t *				wi_config_path_for_name(wi_config_t *, wi_string_t *);
WI_EXPORT uint32_t					wi_config_uid_for_name(wi_config_t *, wi_string_t *);
WI_EXPORT uint32_t					wi_config_gid_for_name(wi_config_t *, wi_string_t *);
WI_EXPORT wi_uinteger_t				wi_config_port_for_name(wi_config_t *, wi_string_t *);
WI_EXPORT wi_regexp_t *				wi_config_regexp_for_name(wi_config_t *, wi_string_t *);
WI_EXPORT wi_time_interval_t		wi_config_time_interval_for_name(wi_config_t *, wi_string_t *);

#endif /* WI_CONFIG_H */
