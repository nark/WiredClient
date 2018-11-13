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

#include "config.h"

#ifndef WI_PTHREADS

int wi_timer_dummy = 0;

#else

#include <pthread.h>

#include <wired/wi-date.h>
#include <wired/wi-lock.h>
#include <wired/wi-log.h>
#include <wired/wi-macros.h>
#include <wired/wi-private.h>
#include <wired/wi-runtime.h>
#include <wired/wi-string.h>
#include <wired/wi-thread.h>
#include <wired/wi-timer.h>

#define _WI_TIMER_MINIMUM_INTERVAL		0.001


struct _wi_timer {
	wi_runtime_base_t					base;
	
	wi_timer_func_t						*func;
	wi_time_interval_t					interval;
	wi_boolean_t						repeats;

	wi_boolean_t						scheduled;
	wi_boolean_t						incallback;
	wi_time_interval_t					fire;
	
	void								*data;
};


static void								_wi_timer_dealloc(wi_runtime_instance_t *);
static wi_string_t *					_wi_timer_description(wi_runtime_instance_t *);
static wi_integer_t						_wi_timer_compare(wi_runtime_instance_t *, wi_runtime_instance_t *);

static void								_wi_timer_create_thread(void);
static void								_wi_timer_thread(wi_runtime_instance_t *);
static wi_timer_t *						_wi_timer_first_timer(void);

static void								_wi_timer_schedule(wi_timer_t *);
static void								_wi_timer_invalidate(wi_timer_t *);


static wi_mutable_array_t				*_wi_timers;

static wi_condition_lock_t				*_wi_timer_lock;

static pthread_once_t					_wi_timer_once_control = PTHREAD_ONCE_INIT;

static wi_runtime_id_t					_wi_timer_runtime_id = WI_RUNTIME_ID_NULL;
static wi_runtime_class_t				_wi_timer_runtime_class = {
	"wi_timer_t",
	_wi_timer_dealloc,
	NULL,
	NULL,
	_wi_timer_description,
	NULL
};



void wi_timer_register(void) {
	_wi_timer_runtime_id = wi_runtime_register_class(&_wi_timer_runtime_class);
}



void wi_timer_initialize(void) {
	_wi_timers			= wi_array_init(wi_mutable_array_alloc());
	_wi_timer_lock		= wi_condition_lock_init_with_condition(wi_condition_lock_alloc(), 0);
}



#pragma mark -

wi_runtime_id_t wi_timer_runtime_id(void) {
	return _wi_timer_runtime_id;
}



#pragma mark -

static void _wi_timer_create_thread(void) {
	if(!wi_thread_create_thread(_wi_timer_thread, NULL))
		wi_log_fatal(WI_STR("Could not create a timer thread: %m"));
}



static void _wi_timer_thread(wi_runtime_instance_t *argument) {
	wi_pool_t			*pool;
	wi_timer_t			*timer, *fire_timer;
	wi_time_interval_t	interval, diff;
	wi_boolean_t		locked;
	
	pool = wi_pool_init(wi_pool_alloc());
	
	while(true) {
		fire_timer	= NULL;
		locked		= true;
		interval	= wi_time_interval();
		timer		= _wi_timer_first_timer();

		if(!timer) {
			locked = wi_condition_lock_lock_when_condition(_wi_timer_lock, 1, 0.0);

			timer = _wi_timer_first_timer();
			interval = wi_time_interval();

			if(timer && timer->fire - interval <= _WI_TIMER_MINIMUM_INTERVAL)
				fire_timer = timer;
		} else {
			diff = timer->fire - interval;

			if(diff <= _WI_TIMER_MINIMUM_INTERVAL) {
				fire_timer = timer;

				locked = false;
			} else {
				locked = wi_condition_lock_lock_when_condition(_wi_timer_lock, 1, diff);
				
				if(!locked)
					fire_timer = _wi_timer_first_timer();
			} 
		}

		if(locked)
			wi_condition_lock_unlock_with_condition(_wi_timer_lock, 0);
		
		if(fire_timer) {
			_wi_timer_invalidate(fire_timer);
				
			wi_timer_fire(fire_timer);

			if(timer->repeats)
				_wi_timer_schedule(fire_timer);
		}
		
		wi_pool_drain(pool);
	}

	//wi_release(pool);
}



static wi_timer_t * _wi_timer_first_timer(void) {
	wi_timer_t		*timer;
	
	wi_array_rdlock(_wi_timers);
	timer = wi_autorelease(wi_retain(wi_array_first_data(_wi_timers)));
	wi_array_unlock(_wi_timers);
	
	return timer;
}



#pragma mark -

wi_timer_t * wi_timer_alloc(void) {
	return wi_runtime_create_instance(_wi_timer_runtime_id, sizeof(wi_timer_t));
}



wi_timer_t * wi_timer_init_with_function(wi_timer_t *timer, wi_timer_func_t *func, wi_time_interval_t interval, wi_boolean_t repeats) {
	timer->func = func;
	timer->interval = WI_MAX(interval, _WI_TIMER_MINIMUM_INTERVAL);
	timer->repeats = repeats;
	
	return timer;
}



static void _wi_timer_dealloc(wi_runtime_instance_t *instance) {
	wi_timer_t		*timer = instance;
	
	wi_timer_invalidate(timer);
}



static wi_string_t * _wi_timer_description(wi_runtime_instance_t *instance) {
	wi_timer_t		*timer = instance;

	return wi_string_with_format(WI_STR("<%@ %p>{interval = %.2fs}"),
		wi_runtime_class_name(instance),
		instance,
		timer->interval);
}



static wi_integer_t _wi_timer_compare(wi_runtime_instance_t *instance1, wi_runtime_instance_t *instance2) {
	wi_timer_t		*timer1 = instance1;
	wi_timer_t		*timer2 = instance2;

	if(timer1->fire < timer2->fire)
		return -1;
	else if(timer1->fire < timer2->fire)
		return 1;
	
	return 0;
}



#pragma mark -

static void _wi_timer_schedule(wi_timer_t *timer) {
	timer->fire = wi_time_interval() + timer->interval;
	
	wi_array_wrlock(_wi_timers);
	wi_mutable_array_add_data_sorted(_wi_timers, timer, _wi_timer_compare);
	wi_array_unlock(_wi_timers);
	
	timer->scheduled = true;
}



static void _wi_timer_invalidate(wi_timer_t *timer) {
	wi_array_wrlock(_wi_timers);
	wi_mutable_array_remove_data(_wi_timers, timer);
	wi_array_unlock(_wi_timers);

	timer->scheduled = false;
}



#pragma mark -

void wi_timer_schedule(wi_timer_t *timer) {
	if(!timer->scheduled) {
		pthread_once(&_wi_timer_once_control, _wi_timer_create_thread);

		if(!timer->incallback)
			wi_condition_lock_lock(_wi_timer_lock);
		
		_wi_timer_schedule(timer);
		
		if(!timer->incallback)
			wi_condition_lock_unlock_with_condition(_wi_timer_lock, 1);
	}
}



void wi_timer_reschedule(wi_timer_t *timer, wi_time_interval_t interval) {
	timer->interval = WI_MAX(interval, _WI_TIMER_MINIMUM_INTERVAL);

	if(timer->scheduled)
		_wi_timer_invalidate(timer);

	if(!timer->incallback)
		wi_condition_lock_lock(_wi_timer_lock);

	_wi_timer_schedule(timer);

	if(!timer->incallback)
		wi_condition_lock_unlock_with_condition(_wi_timer_lock, 1);
}



void wi_timer_fire(wi_timer_t *timer) {
	timer->incallback = true;
	(*timer->func)(timer);
	timer->incallback = false;
}



void wi_timer_invalidate(wi_timer_t *timer) {
	if(timer->scheduled) {
		if(!timer->incallback)
			wi_condition_lock_lock(_wi_timer_lock);
		
		_wi_timer_invalidate(timer);
		
		if(!timer->incallback)
			wi_condition_lock_unlock_with_condition(_wi_timer_lock, 1);
	}
}



#pragma mark -

void wi_timer_set_data(wi_timer_t *timer, void *data) {
	timer->data = data;
}



void * wi_timer_data(wi_timer_t *timer) {
	return timer->data;
}

#endif
