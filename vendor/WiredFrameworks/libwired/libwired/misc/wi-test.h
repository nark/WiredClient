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

#ifndef WI_TEST_H
#define WI_TEST_H

#include <wired/wi-base.h>

#define WI_TEST_EXPORT				WI_EXPORT

#define WI_TEST_FAIL(fmt, ...)											\
	WI_ASSERT(0, fmt, ## __VA_ARGS__)									\

#define WI_TEST_ASSERT_EQUALS(a1, a2, fmt, ...)							\
	WI_STMT_START														\
		typeof(a1)			v1 = (a1);									\
		typeof(a2)			v2 = (a2);									\
																		\
		WI_ASSERT(v1 == v2,												\
				  "'%s' should be equal to '%s': " fmt,					\
				  #a1, #a2,												\
				  ## __VA_ARGS__);										\
	WI_STMT_END

#define WI_TEST_ASSERT_EQUALS_WITH_ACCURACY(a1, a2, epsilon, fmt, ...)	\
	WI_STMT_START														\
		typeof(a1)			v1 = (a1);									\
		typeof(a2)			v2 = (a2);									\
		typeof(epsilon)		e = (epsilon);								\
																		\
		WI_ASSERT(WI_MAX(v1, v2) - WI_MIN(v1, v2) < e,					\
				  "'%s' should be equal to '%s': " fmt,					\
				  #a1, #a2,												\
				  ## __VA_ARGS__);										\
	WI_STMT_END

#define WI_TEST_ASSERT_EQUAL_INSTANCES(a1, a2, fmt, ...)				\
	WI_STMT_START														\
		wi_runtime_instance_t	*i1 = (a1);								\
		wi_runtime_instance_t	*i2 = (a2);								\
																		\
		WI_ASSERT(wi_is_equal(i1, i2),									\
				  "'%@' should be equal to '%@': " fmt,					\
				  i1, i2, ## __VA_ARGS__);								\
	WI_STMT_END

#define WI_TEST_ASSERT_NULL(a1, fmt, ...)								\
	WI_ASSERT((a1) == NULL, "'%s' should be NULL: " fmt, #a1, ## __VA_ARGS__);

#define WI_TEST_ASSERT_NOT_NULL(a1, fmt, ...)							\
	WI_ASSERT((a1) != NULL, "'%s' should not be NULL: " fmt, #a1, ## __VA_ARGS__);

#define WI_TEST_ASSERT_TRUE(a1, fmt, ...)								\
	WI_ASSERT((a1), "'%s' should be true: " fmt, #a1, ## __VA_ARGS__);

#define WI_TEST_ASSERT_FALSE(a1, fmt, ...)								\
	WI_ASSERT(!(a1), "'%s' should be false: " fmt, #a1, ## __VA_ARGS__);


typedef void						wi_run_test_func_t(void);


WI_EXPORT void						wi_tests_start(void);
WI_EXPORT void						wi_tests_stop_and_report(void);
WI_EXPORT void						wi_tests_run_test(const char *, wi_run_test_func_t *);


WI_EXPORT wi_uinteger_t				wi_tests_passed;
WI_EXPORT wi_uinteger_t				wi_tests_failed;

#endif /* WI_TESTS_H */
