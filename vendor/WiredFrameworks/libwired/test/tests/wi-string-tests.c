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

WI_TEST_EXPORT void						wi_test_string_case(void);
WI_TEST_EXPORT void						wi_test_string_constant(void);
WI_TEST_EXPORT void						wi_test_string_compare(void);
WI_TEST_EXPORT void						wi_test_string_digest(void);
WI_TEST_EXPORT void						wi_test_string_length(void);
WI_TEST_EXPORT void						wi_test_string_format(void);
WI_TEST_EXPORT void						wi_test_string_numeric_conversions(void);
WI_TEST_EXPORT void						wi_test_string_paths(void);



void wi_test_string_case(void) {
	WI_TEST_ASSERT_EQUAL_INSTANCES(wi_string_lowercase_string(WI_STR("ABC")), WI_STR("abc"), "");
	WI_TEST_ASSERT_EQUAL_INSTANCES(wi_string_uppercase_string(WI_STR("abc")), WI_STR("ABC"), "");
}



void wi_test_string_constant(void) {
	WI_TEST_ASSERT_EQUALS(WI_STR("hello world"), WI_STR("hello world"), "");
	WI_TEST_ASSERT_TRUE(WI_STR("hello world") != WI_STR("hello another world"), "");
}



void wi_test_string_compare(void) {
	WI_TEST_ASSERT_TRUE(wi_is_equal(wi_string_with_cstring("hello world"), wi_string_with_cstring("hello world")), "");
	WI_TEST_ASSERT_FALSE(wi_is_equal(wi_string_with_cstring("hello world"), wi_string_with_cstring("hello another world")), "");
	WI_TEST_ASSERT_TRUE(wi_string_compare(wi_string_with_cstring("hello world"), wi_string_with_cstring("hello world")) == 0, "");
	WI_TEST_ASSERT_FALSE(wi_string_compare(wi_string_with_cstring("hello world"), wi_string_with_cstring("Hello world")) == 0, "");
	WI_TEST_ASSERT_FALSE(wi_string_compare(wi_string_with_cstring("hello world"), wi_string_with_cstring("hello another world")) == 0, "");
	WI_TEST_ASSERT_TRUE(wi_string_case_insensitive_compare(wi_string_with_cstring("hello world"), wi_string_with_cstring("Hello world")) == 0, "");
	WI_TEST_ASSERT_FALSE(wi_string_case_insensitive_compare(wi_string_with_cstring("hello world"), wi_string_with_cstring("Hello another world")) == 0, "");
}



void wi_test_string_digest(void) {
#ifdef WI_DIGESTS
	WI_TEST_ASSERT_EQUAL_INSTANCES(wi_string_md5(WI_STR("hello world")), WI_STR("5eb63bbbe01eeed093cb22bb8f5acdc3"), "");
	WI_TEST_ASSERT_EQUAL_INSTANCES(wi_string_sha1(WI_STR("hello world")), WI_STR("2aae6c35c94fcfb415dbe95f408b9ce91ee846ed"), "");
#endif
	
	WI_TEST_ASSERT_EQUAL_INSTANCES(wi_string_base64(WI_STR("hello world")), WI_STR("aGVsbG8gd29ybGQ="), "");
	WI_TEST_ASSERT_EQUAL_INSTANCES(wi_string_with_base64(WI_STR("aGVsbG8gd29ybGQ=")), WI_STR("hello world"), "");
}



void wi_test_string_format(void) {
	WI_TEST_ASSERT_EQUAL_INSTANCES(
		wi_string_with_format(WI_STR("'%d' '%u' '%p' '%.5f' '%@' '%@' '%#@' '%s' '%s' '%#s'"),
			-5, 5, 0xAC1DFEED, 3.1415926, WI_STR("hello world"), NULL, NULL, "hello world", NULL, NULL),
		WI_STR("'-5' '5' '0xac1dfeed' '3.14159' 'hello world' '(null)' '' 'hello world' '(null)' ''"),
		"");
}



void wi_test_string_length(void) {
	WI_TEST_ASSERT_EQUALS(wi_string_length(WI_STR("")), 0U, "");
	WI_TEST_ASSERT_EQUALS(wi_string_length(WI_STR("hello world")), 11U, "");
}



void wi_test_string_numeric_conversions(void) {
	WI_TEST_ASSERT_EQUALS(wi_string_bool(WI_STR("yes")), true, "");
	WI_TEST_ASSERT_EQUALS(wi_string_bool(WI_STR("no")), false, "");
	WI_TEST_ASSERT_EQUALS(wi_string_int32(WI_STR("2147483647")), 2147483647, "");
 	WI_TEST_ASSERT_EQUALS(wi_string_int32(WI_STR("2147483648")), 0, "");
	WI_TEST_ASSERT_EQUALS(wi_string_uint32(WI_STR("4294967295")), 4294967295U, "");
	WI_TEST_ASSERT_EQUALS(wi_string_uint32(WI_STR("4294967296")), 0U, "");
	WI_TEST_ASSERT_EQUALS(wi_string_int64(WI_STR("9223372036854775807")), 9223372036854775807LL, "");
	WI_TEST_ASSERT_EQUALS(wi_string_int64(WI_STR("9223372036854775808")), 0LL, "");
	WI_TEST_ASSERT_EQUALS(wi_string_uint64(WI_STR("18446744073709551615")), 18446744073709551615ULL, "");
	WI_TEST_ASSERT_EQUALS(wi_string_uint64(WI_STR("18446744073709551616")), 0ULL, "");

#ifdef WI_32
	WI_TEST_ASSERT_EQUALS(wi_string_integer(WI_STR("2147483647")), 2147483647, "");
	WI_TEST_ASSERT_EQUALS(wi_string_integer(WI_STR("2147483648")), 0, "");
	WI_TEST_ASSERT_EQUALS(wi_string_uinteger(WI_STR("4294967295")), 4294967295U, "");
	WI_TEST_ASSERT_EQUALS(wi_string_uinteger(WI_STR("4294967296")), 0U, "");
#else
	WI_TEST_ASSERT_EQUALS(wi_string_integer(WI_STR("9223372036854775807")), 9223372036854775807LL, "");
	WI_TEST_ASSERT_EQUALS(wi_string_integer(WI_STR("9223372036854775808")), 0LL, "");
	WI_TEST_ASSERT_EQUALS(wi_string_uinteger(WI_STR("18446744073709551615")), 18446744073709551615ULL, "");
	WI_TEST_ASSERT_EQUALS(wi_string_uinteger(WI_STR("18446744073709551616")), 0ULL, "");
#endif

	WI_TEST_ASSERT_EQUALS_WITH_ACCURACY(wi_string_float(WI_STR("3.40282346e38")), 3.40282346e38F, 0.0001, "");
	WI_TEST_ASSERT_EQUALS_WITH_ACCURACY(wi_string_float(WI_STR("3.40282347e38")), 0.0F, 0.0001, "");
	WI_TEST_ASSERT_EQUALS_WITH_ACCURACY(wi_string_double(WI_STR("1.7976931348623155e308")), 1.7976931348623155e308, 0.0001, "");
	WI_TEST_ASSERT_EQUALS_WITH_ACCURACY(wi_string_double(WI_STR("1.7976931348623160e308")), 0.0, 0.0001, "");
}



void wi_test_string_paths(void) {
	WI_TEST_ASSERT_EQUAL_INSTANCES(
		wi_string_path_components(WI_STR("/usr/local/wired")),
		wi_autorelease(wi_array_init_with_data(wi_array_alloc(),
			WI_STR("/"), WI_STR("usr"), WI_STR("local"), WI_STR("wired"), NULL)),
		"");
	
	WI_TEST_ASSERT_EQUAL_INSTANCES(
		wi_string_by_normalizing_path(WI_STR("////usr/././local/../local/../local/wired///")),
		WI_STR("/usr/local/wired"),
		"");
	
	WI_TEST_ASSERT_EQUAL_INSTANCES(
		wi_string_by_appending_path_component(WI_STR("/usr/local/"), WI_STR("/wired")),
		WI_STR("/usr/local/wired"),
		"");
	
	WI_TEST_ASSERT_EQUAL_INSTANCES(wi_string_last_path_component(WI_STR("/usr/local/wired/")), WI_STR("wired"), "");
	WI_TEST_ASSERT_EQUAL_INSTANCES(wi_string_last_path_component(WI_STR("/")), WI_STR("/"), "");
	WI_TEST_ASSERT_EQUAL_INSTANCES(wi_string_last_path_component(WI_STR("/wired/")), WI_STR("wired"), "");
	WI_TEST_ASSERT_EQUAL_INSTANCES(wi_string_by_deleting_last_path_component(WI_STR("/usr/local/wired")), WI_STR("/usr/local"), "");
	WI_TEST_ASSERT_EQUAL_INSTANCES(wi_string_by_deleting_last_path_component(WI_STR("/usr/local/wired/")), WI_STR("/usr/local"), "");
	WI_TEST_ASSERT_EQUAL_INSTANCES(wi_string_by_appending_path_extension(WI_STR("wired"), WI_STR("c")), WI_STR("wired.c"), "");
	WI_TEST_ASSERT_EQUAL_INSTANCES(wi_string_path_extension(WI_STR("wired.c")), WI_STR("c"), "");
	WI_TEST_ASSERT_EQUAL_INSTANCES(wi_string_path_extension(WI_STR("wired")), WI_STR(""), "");
	WI_TEST_ASSERT_EQUAL_INSTANCES(wi_string_by_deleting_path_extension(WI_STR("wired")), WI_STR("wired"), "");
}
