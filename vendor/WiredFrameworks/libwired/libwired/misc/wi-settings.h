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

#ifndef WI_SETTINGS_H
#define WI_SETTINGS_H 1

#include <wired/wi-base.h>
#include <wired/wi-runtime.h>

enum _wi_settings_type {
	WI_SETTINGS_NUMBER,
	WI_SETTINGS_BOOL,
	WI_SETTINGS_STRING,
	WI_SETTINGS_STRING_ARRAY,
	WI_SETTINGS_PATH,
	WI_SETTINGS_USER,
	WI_SETTINGS_GROUP,
	WI_SETTINGS_PORT,
	WI_SETTINGS_REGEXP,
	WI_SETTINGS_TIME_INTERVAL
};
typedef enum _wi_settings_type		wi_settings_type_t;


struct _wi_settings_spec {
	const char						*name;
	wi_settings_type_t				type;
	void							*setting;
};
typedef struct _wi_settings_spec	wi_settings_spec_t;

typedef struct _wi_settings			wi_settings_t;


WI_EXPORT wi_runtime_id_t			wi_settings_runtime_id(void);

WI_EXPORT wi_settings_t *			wi_settings_alloc(void);
WI_EXPORT wi_settings_t *			wi_settings_init_with_spec(wi_settings_t *, wi_settings_spec_t *, wi_uinteger_t);

WI_EXPORT wi_boolean_t				wi_settings_read_file(wi_settings_t *);


WI_EXPORT wi_string_t				*wi_settings_config_path;

#endif /* WI_SETTINGS_H */
