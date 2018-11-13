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

/**
 * @file wi-array.h 
 * @brief Provide support for array structure
 * @author Axel Andersson, Rafaël Warnault
 * @version 2.0
 *
 * NOTE: Very similar to NSArray classe in Objective-C language.
 *
 */

#ifndef WI_ARRAY_H
#define WI_ARRAY_H 1

#include <stdarg.h>
#include <wired/wi-base.h>
#include <wired/wi-enumerator.h>
#include <wired/wi-runtime.h>

#define WI_ARRAY(array, i)				wi_array_data_at_index((array), (i))


struct _wi_array_callbacks {
	wi_retain_func_t					*retain;
	wi_release_func_t					*release;
	wi_is_equal_func_t					*is_equal;
	wi_description_func_t				*description;
};
typedef struct _wi_array_callbacks		wi_array_callbacks_t;


WI_EXPORT wi_runtime_id_t				wi_array_runtime_id(void);

WI_EXPORT wi_array_t *					wi_array(void);
WI_EXPORT wi_array_t *					wi_array_with_data(void *, ...) WI_SENTINEL;
WI_EXPORT wi_array_t *					wi_array_with_arguments(va_list);
WI_EXPORT wi_array_t *					wi_array_with_plist_file(wi_string_t *);
WI_EXPORT wi_mutable_array_t *			wi_mutable_array(void);

WI_EXPORT wi_array_t *					wi_array_alloc(void);
WI_EXPORT wi_mutable_array_t *			wi_mutable_array_alloc(void);
WI_EXPORT wi_array_t *					wi_array_init(wi_array_t *);
WI_EXPORT wi_array_t *					wi_array_init_with_capacity(wi_array_t *, wi_uinteger_t);
WI_EXPORT wi_array_t *					wi_array_init_with_capacity_and_callbacks(wi_array_t *, wi_uinteger_t, wi_array_callbacks_t);
WI_EXPORT wi_array_t *					wi_array_init_with_data(wi_array_t *, ...) WI_SENTINEL;
WI_EXPORT wi_array_t *					wi_array_init_with_data_and_count(wi_array_t *, void **, wi_uinteger_t);
WI_EXPORT wi_array_t *					wi_array_init_with_argv(wi_array_t *, int, const char **);
WI_EXPORT wi_array_t *					wi_array_init_with_argument_string(wi_array_t *, wi_string_t *, wi_integer_t);
WI_EXPORT wi_array_t *					wi_array_init_with_arguments(wi_array_t *, va_list);
WI_EXPORT wi_array_t *					wi_array_init_with_plist_file(wi_array_t *, wi_string_t *);

WI_EXPORT void							wi_array_wrlock(wi_mutable_array_t *);
WI_EXPORT wi_boolean_t					wi_array_trywrlock(wi_mutable_array_t *);
WI_EXPORT void							wi_array_rdlock(wi_array_t *);
WI_EXPORT wi_boolean_t					wi_array_tryrdlock(wi_array_t *);
WI_EXPORT void							wi_array_unlock(wi_array_t *);

WI_EXPORT wi_uinteger_t					wi_array_count(wi_array_t *);
WI_EXPORT void *						wi_array_data_at_index(wi_array_t *, wi_uinteger_t);

WI_EXPORT void *						wi_array_first_data(wi_array_t *);
WI_EXPORT void *						wi_array_last_data(wi_array_t *);
WI_EXPORT wi_boolean_t					wi_array_contains_data(wi_array_t *, void *);
WI_EXPORT wi_uinteger_t					wi_array_index_of_data(wi_array_t *, void *);
WI_EXPORT void							wi_array_get_data(wi_array_t *, void **);
WI_EXPORT void							wi_array_get_data_in_range(wi_array_t *, void **, wi_range_t);
WI_EXPORT wi_string_t *					wi_array_components_joined_by_string(wi_array_t *, wi_string_t *);
WI_EXPORT const char **					wi_array_create_argv(wi_array_t *);
WI_EXPORT void							wi_array_destroy_argv(wi_uinteger_t, const char **);

WI_EXPORT wi_enumerator_t *				wi_array_data_enumerator(wi_array_t *);
WI_EXPORT wi_enumerator_t *				wi_array_reverse_data_enumerator(wi_array_t *);

WI_EXPORT wi_array_t *					wi_array_subarray_with_range(wi_array_t *, wi_range_t);
WI_EXPORT wi_array_t *					wi_array_by_adding_data(wi_array_t *, void *);
WI_EXPORT wi_array_t *					wi_array_by_adding_data_from_array(wi_array_t *, wi_array_t *);

WI_EXPORT wi_array_t *					wi_array_by_sorting(wi_array_t *, wi_compare_func_t *);

WI_EXPORT wi_boolean_t					wi_array_write_to_file(wi_array_t *, wi_string_t *);

WI_EXPORT void							wi_mutable_array_add_data(wi_mutable_array_t *, void *);
WI_EXPORT void							wi_mutable_array_add_data_sorted(wi_mutable_array_t *, void *, wi_compare_func_t *);
WI_EXPORT void							wi_mutable_array_add_data_from_array(wi_mutable_array_t *, wi_array_t *);
WI_EXPORT void							wi_mutable_array_insert_data_at_index(wi_mutable_array_t *, void *, wi_uinteger_t);
WI_EXPORT void							wi_mutable_array_replace_data_at_index(wi_mutable_array_t *, void *, wi_uinteger_t);
WI_EXPORT void							wi_mutable_array_set_array(wi_mutable_array_t *, wi_array_t *);

WI_EXPORT void							wi_mutable_array_remove_data(wi_mutable_array_t *, void *);
WI_EXPORT void							wi_mutable_array_remove_data_at_index(wi_mutable_array_t *, wi_uinteger_t);
WI_EXPORT void							wi_mutable_array_remove_data_in_range(wi_mutable_array_t *, wi_range_t);
WI_EXPORT void							wi_mutable_array_remove_data_in_array(wi_mutable_array_t *, wi_array_t *);
WI_EXPORT void							wi_mutable_array_remove_all_data(wi_mutable_array_t *);

WI_EXPORT void							wi_mutable_array_sort(wi_mutable_array_t *, wi_compare_func_t *);
WI_EXPORT void							wi_mutable_array_reverse(wi_mutable_array_t *);


WI_EXPORT const wi_array_callbacks_t	wi_array_default_callbacks;
WI_EXPORT const wi_array_callbacks_t	wi_array_null_callbacks;

#endif /* WI_ARRAY_H */
