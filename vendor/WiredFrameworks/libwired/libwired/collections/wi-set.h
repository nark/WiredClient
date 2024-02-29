/* $Id$ */

/*
 *  Copyright (c) 2006-2009 Axel Andersson
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

#ifndef WI_SET_H
#define WI_SET_H 1

#include <wired/wi-base.h>
#include <wired/wi-enumerator.h>
#include <wired/wi-runtime.h>

typedef struct _wi_set						wi_set_t;
typedef struct _wi_set						wi_mutable_set_t;

struct _wi_set_callbacks {
	wi_retain_func_t						*retain;
	wi_release_func_t						*release;
	wi_is_equal_func_t						*is_equal;
	wi_description_func_t					*description;
	wi_hash_func_t							*hash;
};
typedef struct _wi_set_callbacks			wi_set_callbacks_t;


WI_EXPORT wi_runtime_id_t					wi_set_runtime_id(void);

WI_EXPORT wi_set_t *						wi_set(void);
WI_EXPORT wi_set_t *						wi_set_with_data(void *, ...);
WI_EXPORT wi_mutable_set_t *				wi_mutable_set(void);

WI_EXPORT wi_set_t *						wi_set_alloc(void);
WI_EXPORT wi_mutable_set_t *				wi_mutable_set_alloc(void);
WI_EXPORT wi_set_t *						wi_set_init(wi_set_t *);
WI_EXPORT wi_set_t *						wi_set_init_with_capacity(wi_set_t *, wi_uinteger_t, wi_boolean_t);
WI_EXPORT wi_set_t *						wi_set_init_with_capacity_and_callbacks(wi_set_t *, wi_uinteger_t, wi_boolean_t, wi_set_callbacks_t);
WI_EXPORT wi_set_t *						wi_set_init_with_data(wi_set_t *, ...) WI_SENTINEL;
WI_EXPORT wi_set_t *						wi_set_init_with_array(wi_set_t *, wi_array_t *);

WI_EXPORT void								wi_set_wrlock(wi_mutable_set_t *);
WI_EXPORT wi_boolean_t						wi_set_trywrlock(wi_mutable_set_t *);
WI_EXPORT void								wi_set_rdlock(wi_set_t *);
WI_EXPORT wi_boolean_t						wi_set_tryrdlock(wi_set_t *);
WI_EXPORT void								wi_set_unlock(wi_set_t *);

WI_EXPORT wi_uinteger_t						wi_set_count(wi_set_t *);
WI_EXPORT wi_array_t *						wi_set_all_data(wi_set_t *);

WI_EXPORT wi_enumerator_t *					wi_set_data_enumerator(wi_set_t *);

WI_EXPORT wi_boolean_t						wi_set_contains_data(wi_set_t *, void *);
WI_EXPORT wi_uinteger_t						wi_set_count_for_data(wi_set_t *, void *);

WI_EXPORT void								wi_mutable_set_add_data(wi_mutable_set_t *, void *);
WI_EXPORT void								wi_mutable_set_add_data_from_array(wi_mutable_set_t *, wi_array_t *);
WI_EXPORT void								wi_mutable_set_set_set(wi_mutable_set_t *, wi_set_t *);

WI_EXPORT void								wi_mutable_set_remove_data(wi_mutable_set_t *, void *);
WI_EXPORT void								wi_mutable_set_remove_all_data(wi_mutable_set_t *);


WI_EXPORT const wi_set_callbacks_t			wi_set_default_callbacks;
WI_EXPORT const wi_set_callbacks_t			wi_set_null_callbacks;

#endif /* WI_SET_H */
