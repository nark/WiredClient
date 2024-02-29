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

#ifndef WI_LOCK_H
#define WI_LOCK_H 1

#include <wired/wi-base.h>
#include <wired/wi-runtime.h>

typedef struct _wi_lock					wi_lock_t;

typedef struct _wi_recursive_lock		wi_recursive_lock_t;

typedef struct _wi_rwlock				wi_rwlock_t;

typedef struct _wi_condition_lock		wi_condition_lock_t;


WI_EXPORT wi_runtime_id_t				wi_lock_runtime_id(void);

WI_EXPORT wi_lock_t *					wi_lock_alloc(void);
WI_EXPORT wi_lock_t *					wi_lock_init(wi_lock_t *);

WI_EXPORT void							wi_lock_lock(wi_lock_t *);
WI_EXPORT wi_boolean_t					wi_lock_trylock(wi_lock_t *);
WI_EXPORT void							wi_lock_unlock(wi_lock_t *);


WI_EXPORT wi_runtime_id_t				wi_recursive_lock_runtime_id(void);

WI_EXPORT wi_recursive_lock_t *			wi_recursive_lock_alloc(void);
WI_EXPORT wi_recursive_lock_t *			wi_recursive_lock_init(wi_recursive_lock_t *);

WI_EXPORT void							wi_recursive_lock_lock(wi_recursive_lock_t *);
WI_EXPORT wi_boolean_t					wi_recursive_lock_trylock(wi_recursive_lock_t *);
WI_EXPORT void							wi_recursive_lock_unlock(wi_recursive_lock_t *);


WI_EXPORT wi_runtime_id_t				wi_rwlock_runtime_id(void);

WI_EXPORT wi_rwlock_t *					wi_rwlock_alloc(void);
WI_EXPORT wi_rwlock_t *					wi_rwlock_init(wi_rwlock_t *);

WI_EXPORT void							wi_rwlock_wrlock(wi_rwlock_t *);
WI_EXPORT wi_boolean_t					wi_rwlock_trywrlock(wi_rwlock_t *);
WI_EXPORT void							wi_rwlock_rdlock(wi_rwlock_t *);
WI_EXPORT wi_boolean_t					wi_rwlock_tryrdlock(wi_rwlock_t *);
WI_EXPORT void							wi_rwlock_unlock(wi_rwlock_t *);


WI_EXPORT wi_runtime_id_t				wi_condition_lock_runtime_id(void);

WI_EXPORT wi_condition_lock_t *			wi_condition_lock_alloc(void);
WI_EXPORT wi_condition_lock_t *			wi_condition_lock_init(wi_condition_lock_t *);
WI_EXPORT wi_condition_lock_t *			wi_condition_lock_init_with_condition(wi_condition_lock_t *, int);

WI_EXPORT void							wi_condition_lock_lock(wi_condition_lock_t *);
WI_EXPORT wi_boolean_t					wi_condition_lock_lock_when_condition(wi_condition_lock_t *, int, wi_time_interval_t);
WI_EXPORT wi_boolean_t					wi_condition_lock_trylock(wi_condition_lock_t *);
WI_EXPORT wi_boolean_t					wi_condition_lock_trylock_when_condition(wi_condition_lock_t *, int);
WI_EXPORT void							wi_condition_lock_unlock(wi_condition_lock_t *);
WI_EXPORT void							wi_condition_lock_unlock_with_condition(wi_condition_lock_t *, int);
WI_EXPORT int							wi_condition_lock_condition(wi_condition_lock_t *);

#endif /* WI_LOCK_H */
