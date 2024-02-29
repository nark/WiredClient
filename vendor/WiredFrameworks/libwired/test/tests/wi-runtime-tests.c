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

#include <wired/wired.h>

WI_TEST_EXPORT void						wi_test_runtime_initialize(void);

WI_TEST_EXPORT void						wi_test_runtime_info(void);
WI_TEST_EXPORT void						wi_test_runtime_functions(void);
WI_TEST_EXPORT void						wi_test_runtime_pool(void);
WI_TEST_EXPORT void						wi_test_runtime_retain(void);



struct _wi_runtimetest {
	wi_runtime_base_t					base;
	
	wi_uinteger_t						value;
};
typedef struct _wi_runtimetest			_wi_runtimetest_t;
typedef struct _wi_runtimetest			_wi_mutable_runtimetest_t;


static _wi_runtimetest_t *				_wi_runtimetest_alloc(void);
static _wi_runtimetest_t *				_wi_runtimetest_init_with_value(_wi_runtimetest_t *, wi_uinteger_t);
static void								_wi_runtimetest_dealloc(wi_runtime_instance_t *);
static wi_runtime_instance_t *			_wi_runtimetest_copy(wi_runtime_instance_t *);
static wi_boolean_t						_wi_runtimetest_is_equal(wi_runtime_instance_t *, wi_runtime_instance_t *);
static wi_hash_code_t					_wi_runtimetest_hash(wi_runtime_instance_t *);
static wi_string_t *					_wi_runtimetest_description(wi_runtime_instance_t *);

static wi_uinteger_t					_wi_runtimetest_deallocs;

static wi_runtime_id_t					_wi_runtimetest_runtime_id = WI_RUNTIME_ID_NULL;
static wi_runtime_class_t				_wi_runtimetest_runtime_class = {
	"_wi_runtimetest_t",
	_wi_runtimetest_dealloc,
	_wi_runtimetest_copy,
	_wi_runtimetest_is_equal,
	_wi_runtimetest_description,
	_wi_runtimetest_hash
};



void wi_test_runtime_initialize(void) {
	_wi_runtimetest_runtime_id = wi_runtime_register_class(&_wi_runtimetest_runtime_class);
}



#pragma mark -

static _wi_runtimetest_t * _wi_runtimetest_alloc(void) {
	return wi_runtime_create_instance_with_options(_wi_runtimetest_runtime_id, sizeof(_wi_runtimetest_t), WI_RUNTIME_OPTION_IMMUTABLE);
}



static _wi_runtimetest_t * _wi_runtimetest_init_with_value(_wi_runtimetest_t *runtimetest, wi_uinteger_t value) {
	runtimetest->value = value;
	
	return runtimetest;
}



static void _wi_runtimetest_dealloc(wi_runtime_instance_t *instance) {
	_wi_runtimetest_deallocs++;
}



static wi_runtime_instance_t * _wi_runtimetest_copy(wi_runtime_instance_t *instance) {
	_wi_runtimetest_t	*runtimetest = instance;
	
	return _wi_runtimetest_init_with_value(_wi_runtimetest_alloc(), runtimetest->value);
}



static wi_boolean_t _wi_runtimetest_is_equal(wi_runtime_instance_t *instance1, wi_runtime_instance_t *instance2) {
	_wi_runtimetest_t	*runtimetest1 = instance1;
	_wi_runtimetest_t	*runtimetest2 = instance2;
	
	return (runtimetest1->value == runtimetest2->value);
}



static wi_hash_code_t _wi_runtimetest_hash(wi_runtime_instance_t *instance) {
	_wi_runtimetest_t	*runtimetest = instance;
	
	return runtimetest->value;
}



static wi_string_t * _wi_runtimetest_description(wi_runtime_instance_t *instance) {
	_wi_runtimetest_t	*runtimetest = instance;
	
	return wi_string_with_format(WI_STR("value=%lu"), runtimetest->value);
}



#pragma mark -

void wi_test_runtime_info(void) {
	_wi_runtimetest_t		*runtimetest;
	
	WI_TEST_ASSERT_EQUALS(wi_runtime_class_with_name(WI_STR("_wi_runtimetest_t")), &_wi_runtimetest_runtime_class, "");
	WI_TEST_ASSERT_EQUALS(wi_runtime_class_with_id(_wi_runtimetest_runtime_id), &_wi_runtimetest_runtime_class, "");
	
	runtimetest = _wi_runtimetest_init_with_value(_wi_runtimetest_alloc(), 42);
	
	WI_TEST_ASSERT_EQUALS(wi_runtime_id(runtimetest), _wi_runtimetest_runtime_id, "");
	WI_TEST_ASSERT_EQUALS(wi_runtime_class(runtimetest), &_wi_runtimetest_runtime_class, "");
	WI_TEST_ASSERT_EQUAL_INSTANCES(wi_runtime_class_name(runtimetest), wi_string_with_cstring(_wi_runtimetest_runtime_class.name), "");
	
	wi_release(runtimetest);
}



void wi_test_runtime_functions(void) {
	_wi_runtimetest_t			*runtimetest1, *runtimetest2;
	_wi_mutable_runtimetest_t	*runtimetest3;
	
	_wi_runtimetest_deallocs = 0;
	
	runtimetest1 = _wi_runtimetest_init_with_value(_wi_runtimetest_alloc(), 42);
	runtimetest2 = wi_copy(runtimetest1);
	
	WI_TEST_ASSERT_TRUE(runtimetest1 == runtimetest2, "");
	
	wi_release(runtimetest2);

	runtimetest3 = wi_mutable_copy(runtimetest1);
	
	WI_TEST_ASSERT_TRUE(runtimetest1 != runtimetest3, "");
	WI_TEST_ASSERT_EQUALS(runtimetest1->value, runtimetest3->value, "");
	WI_TEST_ASSERT_TRUE(wi_is_equal(runtimetest1, runtimetest3), "");
	
	runtimetest3->value++;
	
	WI_TEST_ASSERT_FALSE(wi_is_equal(runtimetest1, runtimetest3), "");
	
	wi_release(runtimetest3);
	
	WI_TEST_ASSERT_EQUALS(_wi_runtimetest_deallocs, 1U, "");
	WI_TEST_ASSERT_EQUAL_INSTANCES(wi_description(runtimetest1), WI_STR("value=42"), "");
	WI_TEST_ASSERT_EQUALS(wi_hash(runtimetest1), 42U, "");
	
	wi_release(runtimetest1);
}



void wi_test_runtime_pool(void) {
	wi_pool_t			*pool, *pool2;
	_wi_runtimetest_t	*runtimetest, *runtimetest2;
	
	_wi_runtimetest_deallocs = 0;
	
	pool = wi_pool_init(wi_pool_alloc());
	runtimetest = wi_retain(wi_autorelease(_wi_runtimetest_init_with_value(_wi_runtimetest_alloc(), 42)));
	wi_release(pool);
	WI_TEST_ASSERT_EQUALS(wi_retain_count(runtimetest), 1U, "");
	wi_release(runtimetest);

	pool = wi_pool_init(wi_pool_alloc());
	runtimetest = wi_retain(wi_autorelease(_wi_runtimetest_init_with_value(_wi_runtimetest_alloc(), 42)));
	wi_pool_drain(pool);
	WI_TEST_ASSERT_EQUALS(wi_retain_count(runtimetest), 1U, "");
	wi_release(pool);
	wi_release(runtimetest);
	
	pool = wi_pool_init(wi_pool_alloc());
	runtimetest = wi_retain(wi_autorelease(_wi_runtimetest_init_with_value(_wi_runtimetest_alloc(), 42)));
	pool2 = wi_pool_init(wi_pool_alloc());
	runtimetest2 = wi_retain(wi_autorelease(_wi_runtimetest_init_with_value(_wi_runtimetest_alloc(), 42)));
	wi_release(pool2);
	WI_TEST_ASSERT_EQUALS(wi_retain_count(runtimetest2), 1U, "");
	wi_release(pool);
	WI_TEST_ASSERT_EQUALS(wi_retain_count(runtimetest), 1U, "");
	wi_release(runtimetest);
	wi_release(runtimetest2);
}



void wi_test_runtime_retain(void) {
	_wi_runtimetest_t		*runtimetest, *runtimetest2;
	
	_wi_runtimetest_deallocs = 0;

	runtimetest = _wi_runtimetest_init_with_value(_wi_runtimetest_alloc(), 42);
	
	WI_TEST_ASSERT_EQUALS(wi_retain_count(runtimetest), 1U, "");
	
	runtimetest2 = wi_retain(runtimetest);
	
	WI_TEST_ASSERT_EQUALS(wi_retain_count(runtimetest), 2U, "");
	WI_TEST_ASSERT_EQUALS(runtimetest, runtimetest2, "");
	
	wi_release(runtimetest);
	
	WI_TEST_ASSERT_EQUALS(wi_retain_count(runtimetest), 1U, "");
	
	wi_release(runtimetest);
	
	WI_TEST_ASSERT_EQUALS(_wi_runtimetest_deallocs, 1U, "");
}
