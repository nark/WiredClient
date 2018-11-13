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

#ifndef WI_THREAD_H
#define WI_THREAD_H 1

#include <wired/wi-base.h>
#include <wired/wi-dictionary.h>
#include <wired/wi-runtime.h>

typedef struct _wi_thread				wi_thread_t;

typedef void							wi_thread_func_t(wi_runtime_instance_t *);


WI_EXPORT wi_boolean_t					wi_thread_create_thread(wi_thread_func_t *, wi_runtime_instance_t *);
WI_EXPORT wi_boolean_t					wi_thread_create_thread_with_priority(wi_thread_func_t *, wi_runtime_instance_t *, double);

WI_EXPORT void							wi_thread_enter_thread(void);
WI_EXPORT void							wi_thread_exit_thread(void);

WI_EXPORT wi_thread_t *					wi_thread_current_thread(void);
WI_EXPORT wi_mutable_dictionary_t *		wi_thread_dictionary(void);

WI_EXPORT void							wi_thread_sleep(wi_time_interval_t);
WI_EXPORT void							wi_thread_block_signals(int, ...);
WI_EXPORT int							wi_thread_wait_for_signals(int, ...);

#endif /* WI_THREAD_H */
