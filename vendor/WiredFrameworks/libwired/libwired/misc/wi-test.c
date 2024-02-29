/* $Id$ */

/*
 *  Copyright (c) 2007-2009 Axel Andersson
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

#include <setjmp.h>

#include <wired/wi-assert.h>
#include <wired/wi-date.h>
#include <wired/wi-log.h>
#include <wired/wi-private.h>
#include <wired/wi-string.h>
#include <wired/wi-test.h>

struct _wi_test {
	wi_runtime_base_t					base;
	
	wi_string_t							*name;
	wi_run_test_func_t					*function;
	wi_boolean_t						passed;
	wi_time_interval_t					interval;
};
typedef struct _wi_test					wi_test_t;


static void								_wi_tests_assert_handler(const char *, unsigned int, wi_string_t *, ...);

static wi_test_t *						_wi_test_alloc(void);
static wi_test_t *						_wi_test_init_with_function(wi_test_t *, wi_string_t *, wi_run_test_func_t *);
static void								_wi_test_dealloc(wi_runtime_instance_t *);


static wi_runtime_id_t					_wi_test_runtime_id = WI_RUNTIME_ID_NULL;
static wi_runtime_class_t				_wi_test_runtime_class = {
	"wi_test_t",
	_wi_test_dealloc,
	NULL,
	NULL,
	NULL,
	NULL
};

static wi_test_t						*_wi_tests_current_test;
static wi_date_t						*_wi_tests_start_date;
static jmp_buf							_wi_tests_jmp_buf;


wi_uinteger_t							wi_tests_passed;
wi_uinteger_t							wi_tests_failed;



void wi_test_register(void) {
	_wi_test_runtime_id = wi_runtime_register_class(&_wi_test_runtime_class);
}



void wi_test_initialize(void) {
}



#pragma mark -

void wi_tests_start(void) {
	_wi_tests_start_date = wi_date_init(wi_date_alloc());
	
	wi_tests_passed = wi_tests_failed = 0;
	
	wi_log_info(WI_STR("Tests started at %@"), wi_date_string_with_format(_wi_tests_start_date, WI_STR("%Y-%m-%d %H:%M:%S")));
}



void wi_tests_stop_and_report(void) {
	wi_uinteger_t	tests;
	
	tests = wi_tests_passed + wi_tests_failed;
	
	wi_log_info(WI_STR("Tests stopped at %@"), wi_date_string_with_format(_wi_tests_start_date, WI_STR("%Y-%m-%d %H:%M:%S")));
	wi_log_info(WI_STR("%lu %@ passed (%.1f%%), %lu failed (%.1f%%) in %.3f seconds"),
		wi_tests_passed,
		wi_tests_passed == 1
			? WI_STR("test")
			: WI_STR("tests"),
		tests > 0 ? ((double) wi_tests_passed / (double) tests) * 100.0 : 0.0,
		wi_tests_failed,
		tests > 0 ? ((double) wi_tests_failed / (double) tests) * 100.0 : 0.0,
		wi_date_time_interval_since_now(_wi_tests_start_date));

	wi_release(_wi_tests_start_date);
}



void wi_tests_run_test(const char *name, wi_run_test_func_t *function) {
	wi_pool_t					*pool;
	wi_assert_handler_func_t	*handler;
	wi_time_interval_t			interval;
	
	if(wi_string_has_suffix(wi_string_with_cstring(name), WI_STR("initialize"))) {
		(*function)();
	} else {
		_wi_tests_current_test = _wi_test_init_with_function(_wi_test_alloc(), wi_string_with_cstring(name), function);
		
		handler = wi_assert_handler;
		wi_assert_handler = _wi_tests_assert_handler;
		
		interval = wi_time_interval();
		
		pool = wi_pool_init(wi_pool_alloc());

		if(setjmp(_wi_tests_jmp_buf) == 0)
			(*_wi_tests_current_test->function)();

		wi_release(pool);
		
		_wi_tests_current_test->interval = wi_time_interval() - interval;
		
		wi_assert_handler = handler;

		if(_wi_tests_current_test->passed) {
			wi_log_info(WI_STR("Test \"%@\" passed (%.3f seconds)"),
				_wi_tests_current_test->name, _wi_tests_current_test->interval);
			
			wi_tests_passed++;
		} else {
			wi_log_info(WI_STR("Test \"%@\" failed (%.3f seconds)"),
				_wi_tests_current_test->name, _wi_tests_current_test->interval);
			
			wi_tests_failed++;
		}
		
		wi_release(_wi_tests_current_test);
	}
}



#pragma mark -

static void _wi_tests_assert_handler(const char *file, unsigned int line, wi_string_t *fmt, ...) {
	wi_string_t		*string;
	va_list			ap;
	
	va_start(ap, fmt);
	string = wi_string_init_with_format_and_arguments(wi_string_alloc(), fmt, ap);
	va_end(ap);
	
	wi_log_warn(WI_STR("%@:%u: %@"), wi_string_last_path_component(wi_string_with_cstring(file)), line, string);
	
	wi_release(string);
	
	_wi_tests_current_test->passed = false;
	
	longjmp(_wi_tests_jmp_buf, 1);
}



#pragma mark -

static wi_test_t * _wi_test_alloc(void) {
	return wi_runtime_create_instance(_wi_test_runtime_id, sizeof(wi_test_t));
}



static wi_test_t * _wi_test_init_with_function(wi_test_t *test, wi_string_t *name, wi_run_test_func_t *function) {
	test->passed	= true;
	test->name		= wi_retain(name);
	test->function	= function;
	
	return test;
}



static void _wi_test_dealloc(wi_runtime_instance_t *instance) {
	wi_test_t		*test = instance;
	
	wi_release(test->name);
}
