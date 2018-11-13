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

#ifndef WI_DICTIONARY_H
#define WI_DICTIONARY_H 1

#include <wired/wi-base.h>
#include <wired/wi-enumerator.h>
#include <wired/wi-runtime.h>

typedef struct _wi_dictionary						wi_dictionary_t;
typedef struct _wi_dictionary						wi_mutable_dictionary_t;

struct _wi_dictionary_key_callbacks {
	wi_retain_func_t								*retain;
	wi_release_func_t								*release;
	wi_is_equal_func_t								*is_equal;
	wi_description_func_t							*description;
	wi_hash_func_t									*hash;
};
typedef struct _wi_dictionary_key_callbacks			wi_dictionary_key_callbacks_t;

struct _wi_dictionary_value_callbacks {
	wi_retain_func_t								*retain;
	wi_release_func_t								*release;
	wi_is_equal_func_t								*is_equal;
	wi_description_func_t							*description;
};
typedef struct _wi_dictionary_value_callbacks		wi_dictionary_value_callbacks_t;


WI_EXPORT wi_runtime_id_t							wi_dictionary_runtime_id(void);

WI_EXPORT wi_dictionary_t *							wi_dictionary(void);
WI_EXPORT wi_dictionary_t *							wi_dictionary_with_data_and_keys(void *, void *, ...) WI_SENTINEL;
WI_EXPORT wi_dictionary_t *							wi_dictionary_with_plist_file(wi_string_t *);
WI_EXPORT wi_mutable_dictionary_t *					wi_mutable_dictionary(void);
WI_EXPORT wi_mutable_dictionary_t *					wi_mutable_dictionary_with_data_and_keys(void *, void *, ...) WI_SENTINEL;

WI_EXPORT wi_dictionary_t *							wi_dictionary_alloc(void);
WI_EXPORT wi_mutable_dictionary_t *					wi_mutable_dictionary_alloc(void);
WI_EXPORT wi_dictionary_t *							wi_dictionary_init(wi_dictionary_t *);
WI_EXPORT wi_dictionary_t *							wi_dictionary_init_with_capacity(wi_dictionary_t *, wi_uinteger_t);
WI_EXPORT wi_dictionary_t *							wi_dictionary_init_with_capacity_and_callbacks(wi_dictionary_t *, wi_uinteger_t, wi_dictionary_key_callbacks_t, wi_dictionary_value_callbacks_t);
WI_EXPORT wi_dictionary_t *							wi_dictionary_init_with_data_and_keys(wi_dictionary_t *, ...) WI_SENTINEL;
WI_EXPORT wi_dictionary_t *							wi_dictionary_init_with_plist_file(wi_dictionary_t *, wi_string_t *);

WI_EXPORT void										wi_dictionary_wrlock(wi_mutable_dictionary_t *);
WI_EXPORT wi_boolean_t								wi_dictionary_trywrlock(wi_mutable_dictionary_t *);
WI_EXPORT void										wi_dictionary_rdlock(wi_dictionary_t *);
WI_EXPORT wi_boolean_t								wi_dictionary_tryrdlock(wi_dictionary_t *);
WI_EXPORT void										wi_dictionary_unlock(wi_dictionary_t *);

WI_EXPORT wi_uinteger_t								wi_dictionary_count(wi_dictionary_t *);
WI_EXPORT void *									wi_dictionary_data_for_key(wi_dictionary_t *, void *);

WI_EXPORT wi_boolean_t								wi_dictionary_contains_key(wi_dictionary_t *, void *);
WI_EXPORT wi_array_t *								wi_dictionary_all_keys(wi_dictionary_t *);
WI_EXPORT wi_array_t *								wi_dictionary_all_values(wi_dictionary_t *);
WI_EXPORT wi_array_t *								wi_dictionary_keys_sorted_by_value(wi_dictionary_t *, wi_compare_func_t *);

WI_EXPORT wi_enumerator_t *							wi_dictionary_key_enumerator(wi_dictionary_t *);
WI_EXPORT wi_enumerator_t *							wi_dictionary_data_enumerator(wi_dictionary_t *);

WI_EXPORT wi_boolean_t								wi_dictionary_write_to_file(wi_dictionary_t *, wi_string_t *);

WI_EXPORT void										wi_mutable_dictionary_set_data_for_key(wi_mutable_dictionary_t *, void *, void *);
WI_EXPORT void										wi_mutable_dictionary_add_entries_from_dictionary(wi_mutable_dictionary_t *, wi_dictionary_t *);
WI_EXPORT void										wi_mutable_dictionary_set_dictionary(wi_mutable_dictionary_t *, wi_dictionary_t *);

WI_EXPORT void										wi_mutable_dictionary_remove_data_for_key(wi_mutable_dictionary_t *, void *);
WI_EXPORT void										wi_mutable_dictionary_remove_all_data(wi_mutable_dictionary_t *);


WI_EXPORT const wi_dictionary_key_callbacks_t		wi_dictionary_default_key_callbacks;
WI_EXPORT const wi_dictionary_key_callbacks_t		wi_dictionary_null_key_callbacks;
WI_EXPORT const wi_dictionary_value_callbacks_t		wi_dictionary_default_value_callbacks;
WI_EXPORT const wi_dictionary_value_callbacks_t		wi_dictionary_null_value_callbacks;

#endif /* WI_DICTIONARY_H */
