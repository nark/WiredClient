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

#include "config.h"

#include <stdarg.h>
#include <stdio.h>
#include <unistd.h>
#include <signal.h>
#include <time.h>

#ifdef WI_PTHREADS
#include <pthread.h>
#endif

#include <wired/wi-dictionary.h>
#include <wired/wi-private.h>
#include <wired/wi-string.h>
#include <wired/wi-system.h>
#include <wired/wi-thread.h>

#define _WI_THREAD_KEY					"_wi_thread_t"


struct _wi_thread {
	wi_runtime_base_t					base;
	
#ifdef WI_PTHREADS
	pthread_t							thread;
#endif
	
	void								*poolstack;
};


static wi_thread_t *					_wi_thread_alloc(void);
static wi_thread_t *					_wi_thread_init(wi_thread_t *);

#ifdef WI_PTHREADS
static void *							_wi_thread_trampoline(void *);
#endif



#ifdef WI_PTHREADS
static pthread_key_t					_wi_thread_dictionary_key;
static pthread_key_t					_wi_thread_thread_key;
#else
static wi_dictionary_t					*_wi_thread_dictionary;
static wi_thread_t						*_wi_thread_thread;
#endif

static wi_runtime_id_t					_wi_thread_runtime_id = WI_RUNTIME_ID_NULL;
static wi_runtime_class_t				_wi_thread_runtime_class = {
	"wi_thread_t",
	NULL,
	NULL,
	NULL,
	NULL,
	NULL
};



void wi_thread_register(void) {
	_wi_thread_runtime_id = wi_runtime_register_class(&_wi_thread_runtime_class);
}



void wi_thread_initialize(void) {
#ifdef WI_PTHREADS
	pthread_key_create(&_wi_thread_dictionary_key, NULL);
	pthread_key_create(&_wi_thread_thread_key, NULL);
#endif

	wi_thread_enter_thread();
}



#pragma mark -

#ifdef WI_PTHREADS

wi_boolean_t wi_thread_create_thread(wi_thread_func_t *function, wi_runtime_instance_t *argument) {
	return wi_thread_create_thread_with_priority(function, argument, 0.5);
}



wi_boolean_t wi_thread_create_thread_with_priority(wi_thread_func_t *function, wi_runtime_instance_t *argument, double priority) {
#if defined(HAVE_PTHREAD_ATTR_SETSCHEDPOLICY) && defined(HAVE_SCHED_GET_PRIORITY_MIN) && defined(HAVE_SCHED_GET_PRIORITY_MAX)
	struct sched_param		param;
	int						min, max;
#endif
	pthread_t				thread;
	pthread_attr_t			attr;
	void					**vector;
	int						err;
	
	vector = wi_malloc(2 * sizeof(void *));
	vector[0] = function;
	vector[1] = wi_retain(argument);

	pthread_attr_init(&attr);
	pthread_attr_setdetachstate(&attr, PTHREAD_CREATE_DETACHED);
#if defined(HAVE_PTHREAD_ATTR_SETSCHEDPOLICY) && defined(HAVE_SCHED_GET_PRIORITY_MIN) && defined(HAVE_SCHED_GET_PRIORITY_MAX)
	min = sched_get_priority_min(SCHED_OTHER);
	max = sched_get_priority_max(SCHED_OTHER);
	
	if(min > 0 && max > 0)
		param.sched_priority = min + ((max - min) * priority);
	else
		param.sched_priority = 0;
	
	pthread_attr_setschedpolicy(&attr, SCHED_OTHER);
	pthread_attr_setschedparam(&attr, &param);
#endif
	
	err = pthread_create(&thread, &attr, _wi_thread_trampoline, vector);
	
	pthread_attr_destroy(&attr);
	
	if(err != 0) {
		wi_error_set_errno(err);
		
		wi_release(vector[1]);
		wi_free(vector);
		
		return false;
	}
	
	return true;
}

#endif



#pragma mark -

static wi_thread_t * _wi_thread_alloc(void) {
	return wi_runtime_create_instance(_wi_thread_runtime_id, sizeof(wi_thread_t));
}



static wi_thread_t * _wi_thread_init(wi_thread_t *thread) {
	return thread;
}



#pragma mark -

#ifdef WI_PTHREADS

static void * _wi_thread_trampoline(void *arg) {
	void					**vector = (void **) arg;
	wi_thread_func_t		*function;
	wi_runtime_instance_t	*argument;
	
	function = vector[0];
	argument = vector[1];
	
	wi_free(vector);
	
	wi_thread_enter_thread();
	
	(*function)(argument);
	
	wi_thread_exit_thread();
	
	wi_release(argument);
	
	return NULL;
}

#endif



void wi_thread_enter_thread(void) {
	wi_thread_t					*thread;
	wi_mutable_dictionary_t		*dictionary;
	
	thread = _wi_thread_init(_wi_thread_alloc());

#ifdef WI_PTHREADS
	thread->thread = pthread_self();
#endif

#ifdef WI_PTHREADS
	pthread_setspecific(_wi_thread_thread_key, thread);
#else
	_wi_thread_thread = thread;
#endif
	
	dictionary = wi_dictionary_init(wi_mutable_dictionary_alloc());

#ifdef WI_PTHREADS
	pthread_setspecific(_wi_thread_dictionary_key, dictionary);
#else
	_wi_thread_dictionary = dictionary;
#endif

	wi_error_enter_thread();
}



void wi_thread_exit_thread(void) {
	wi_socket_exit_thread();
	
	wi_release(wi_thread_dictionary());
	wi_release(wi_thread_current_thread());
}



#pragma mark -

wi_thread_t * wi_thread_current_thread(void) {
#ifdef WI_PTHREADS
	return pthread_getspecific(_wi_thread_thread_key);
#else
	return _wi_thread_thread;
#endif
}



wi_mutable_dictionary_t * wi_thread_dictionary(void) {
#ifdef WI_PTHREADS
	return pthread_getspecific(_wi_thread_dictionary_key);
#else
	return _wi_thread_dictionary;
#endif
}



#pragma mark -

void wi_thread_set_poolstack(wi_thread_t *thread, void *poolstack) {
	thread->poolstack = poolstack;
}



void * wi_thread_poolstack(wi_thread_t *thread) {
	return thread->poolstack;
}



#pragma mark -

void wi_thread_sleep(wi_time_interval_t interval) {
	usleep(interval * 1000000.0);
}



void wi_thread_block_signals(int signal, ...) {
	sigset_t	signals;
	va_list		ap;
	
	va_start(ap, signal);
	
	sigemptyset(&signals);
	sigaddset(&signals, signal);

	while((signal = va_arg(ap, int)))
		sigaddset(&signals, signal);
	
	va_end(ap);

#ifdef WI_PTHREADS
	pthread_sigmask(SIG_SETMASK, &signals, NULL);
#else
	sigprocmask(SIG_SETMASK, &signals, NULL);
#endif
}



#ifdef WI_PTHREADS

int wi_thread_wait_for_signals(int signal, ...) {
	sigset_t	signals;
	va_list		ap;
	
	va_start(ap, signal);
	
	sigemptyset(&signals);
	sigaddset(&signals, signal);

	while((signal = va_arg(ap, int)))
		sigaddset(&signals, signal);
	
	va_end(ap);

	sigwait(&signals, &signal);
	
	return signal;

}

#endif
