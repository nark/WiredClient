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

WI_TEST_EXPORT void						wi_test_number(void);


void wi_test_number(void) {
	WI_TEST_ASSERT_TRUE(wi_number_bool(wi_number_with_bool(true)), "");
	WI_TEST_ASSERT_FALSE(wi_number_bool(wi_number_with_bool(false)), "");
	WI_TEST_ASSERT_EQUALS(wi_number_int32(wi_number_with_int32(2147483647)), 2147483647, "");
	WI_TEST_ASSERT_EQUALS((uint32_t) wi_number_int32(wi_number_with_int32(4294967295U)), 4294967295U, "");
	WI_TEST_ASSERT_EQUALS(wi_number_int64(wi_number_with_int64(9223372036854775807LL)), 9223372036854775807LL, "");
	WI_TEST_ASSERT_EQUALS((uint64_t) wi_number_int64(wi_number_with_int64(18446744073709551615ULL)), 18446744073709551615ULL, "");

#ifdef WI_32
	WI_TEST_ASSERT_EQUALS(wi_number_integer(wi_number_with_integer(2147483647)), 2147483647, "");
	WI_TEST_ASSERT_EQUALS((wi_uinteger_t) wi_number_integer(wi_number_with_integer(4294967295U)), 4294967295U, "");
#else
	WI_TEST_ASSERT_EQUALS(wi_number_integer(wi_number_with_integer(9223372036854775807LL)), 9223372036854775807LL, "");
	WI_TEST_ASSERT_EQUALS((wi_uinteger_t) wi_number_integer(wi_number_with_integer(18446744073709551615ULL)), 18446744073709551615ULL, "");
#endif
	
	WI_TEST_ASSERT_EQUALS_WITH_ACCURACY(wi_number_float(wi_number_with_float(3.40282346e38)), 3.40282346e38F, 0.0001, "");
	WI_TEST_ASSERT_EQUALS_WITH_ACCURACY(wi_number_double(wi_number_with_double(1.7976931348623155e308)), 1.7976931348623155e308, 0.0001, "");
}
