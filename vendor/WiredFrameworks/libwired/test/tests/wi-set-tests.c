/* $Id$ */

/*
 *  Copyright (c) 2008-2009 Axel Andersson
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

WI_TEST_EXPORT void						wi_test_set(void);


void wi_test_set(void) {
	wi_mutable_set_t		*set;
	
	set = wi_set_init(wi_mutable_set_alloc());
	
	WI_TEST_ASSERT_NOT_NULL(set, "");
	
	wi_mutable_set_add_data(set, WI_STR("foo"));
	
	WI_TEST_ASSERT_TRUE(wi_set_contains_data(set, WI_STR("foo")), "");
	WI_TEST_ASSERT_FALSE(wi_set_contains_data(set, WI_STR("bar")), "");
	WI_TEST_ASSERT_EQUALS(wi_set_count_for_data(set, WI_STR("foo")), 1U, "");
	
	wi_release(set);

	set = wi_set_init_with_capacity(wi_mutable_set_alloc(), 0, true);

	WI_TEST_ASSERT_NOT_NULL(set, "");
	
	wi_mutable_set_add_data(set, WI_STR("foo"));
	wi_mutable_set_add_data(set, WI_STR("foo"));

	WI_TEST_ASSERT_TRUE(wi_set_contains_data(set, WI_STR("foo")), "");
	WI_TEST_ASSERT_FALSE(wi_set_contains_data(set, WI_STR("bar")), "");
	WI_TEST_ASSERT_EQUALS(wi_set_count_for_data(set, WI_STR("foo")), 2U, "");

	wi_mutable_set_remove_data(set, WI_STR("foo"));

	WI_TEST_ASSERT_TRUE(wi_set_contains_data(set, WI_STR("foo")), "");
	WI_TEST_ASSERT_EQUALS(wi_set_count_for_data(set, WI_STR("foo")), 1U, "");
	
	wi_mutable_set_remove_data(set, WI_STR("foo"));
	
	WI_TEST_ASSERT_FALSE(wi_set_contains_data(set, WI_STR("foo")), "");
	WI_TEST_ASSERT_EQUALS(wi_set_count_for_data(set, WI_STR("foo")), 0U, "");
	
	wi_release(set);
}
