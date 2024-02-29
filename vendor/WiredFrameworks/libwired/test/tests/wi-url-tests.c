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

WI_TEST_EXPORT void						wi_test_url(void);


void wi_test_url(void) {
	wi_url_t			*url1;
	wi_mutable_url_t	*url2;
	
	url1 = wi_url_init_with_string(wi_url_alloc(), WI_STR("wired://user:pass@localhost:2000/file.txt"));
	
	WI_TEST_ASSERT_TRUE(wi_url_is_valid(url1), "");
	WI_TEST_ASSERT_EQUAL_INSTANCES(wi_url_string(url1), WI_STR("wired://user:pass@localhost:2000/file.txt"), "");
	
	WI_TEST_ASSERT_EQUAL_INSTANCES(wi_url_scheme(url1), WI_STR("wired"), "");
	WI_TEST_ASSERT_EQUAL_INSTANCES(wi_url_host(url1), WI_STR("localhost"), "");
	WI_TEST_ASSERT_EQUALS(wi_url_port(url1), 2000U, "");
	WI_TEST_ASSERT_EQUAL_INSTANCES(wi_url_path(url1), WI_STR("/file.txt"), "");
	WI_TEST_ASSERT_EQUAL_INSTANCES(wi_url_user(url1), WI_STR("user"), "");
	WI_TEST_ASSERT_EQUAL_INSTANCES(wi_url_password(url1), WI_STR("pass"), "");
	
	url2 = wi_mutable_copy(url1);
	
	wi_mutable_url_set_scheme(url2, WI_STR("wired2"));
	wi_mutable_url_set_host(url2, WI_STR("localhost2"));
	wi_mutable_url_set_port(url2, 2001);
	wi_mutable_url_set_path(url2, WI_STR("/anotherfile.txt"));
	wi_mutable_url_set_user(url2, WI_STR("user2"));
	wi_mutable_url_set_password(url2, WI_STR("pass2"));

	WI_TEST_ASSERT_EQUAL_INSTANCES(wi_url_string(url2), WI_STR("wired2://user2:pass2@localhost2:2001/anotherfile.txt"), "");
	
	wi_release(url1);
	wi_release(url2);
}
