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

#ifndef WI_TIMER_H
#define WI_TIMER_H 1

#include <wired/wi-base.h>
#include <wired/wi-runtime.h>

typedef struct _wi_timer		wi_timer_t;

typedef void					wi_timer_func_t(wi_timer_t *);


WI_EXPORT wi_runtime_id_t		wi_timer_runtime_id(void);

WI_EXPORT wi_timer_t *			wi_timer_alloc(void);
WI_EXPORT wi_timer_t *			wi_timer_init_with_function(wi_timer_t *, wi_timer_func_t *, wi_time_interval_t, wi_boolean_t);

WI_EXPORT void					wi_timer_schedule(wi_timer_t *);
WI_EXPORT void					wi_timer_reschedule(wi_timer_t *, wi_time_interval_t);
WI_EXPORT void					wi_timer_fire(wi_timer_t *);
WI_EXPORT void					wi_timer_invalidate(wi_timer_t *);

WI_EXPORT void					wi_timer_set_data(wi_timer_t *, void *);
WI_EXPORT void *				wi_timer_data(wi_timer_t *);

#endif /* WI_TIMER_H */
