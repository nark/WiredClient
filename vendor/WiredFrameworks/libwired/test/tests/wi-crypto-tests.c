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

WI_TEST_EXPORT void						wi_test_crypto_cipher(void);
WI_TEST_EXPORT void						wi_test_crypto_rsa(void);

#ifdef WI_CIPHERS
static void								_wi_test_crypto_cipher(wi_cipher_type_t, wi_string_t *, wi_uinteger_t, wi_data_t *, wi_data_t *);
#endif



void wi_test_crypto_cipher(void) {
#ifdef WI_CIPHERS
	_wi_test_crypto_cipher(WI_CIPHER_AES128, WI_STR("AES"), 128,
						   wi_data_with_base64(WI_STR("ThMdgpVRxOZ+tgJQSmp84w==")),
						   wi_data_with_base64(WI_STR("bHHG4L6aGKGsGIzA82DVvQ==")));

	_wi_test_crypto_cipher(WI_CIPHER_AES192, WI_STR("AES"), 192,
						   wi_data_with_base64(WI_STR("DOBad099mTPH6lagfKPRsJAb46fVaiol")),
						   wi_data_with_base64(WI_STR("QoJeh/+7zxVAQAX8h88QgA==")));

	_wi_test_crypto_cipher(WI_CIPHER_AES256, WI_STR("AES"), 256,
						   wi_data_with_base64(WI_STR("BZofvj2yZm+pF0Lu+ebDP65XPv1Qbj3eLEIOx9dOLT4=")),
						   wi_data_with_base64(WI_STR("1qq13sv6H+sA8vn72Vs1hQ==")));

	_wi_test_crypto_cipher(WI_CIPHER_BF128, WI_STR("Blowfish"), 128,
						   wi_data_with_base64(WI_STR("k96E++BNrz/nvEqRKfK2DA==")),
						   wi_data_with_base64(WI_STR("k4NWyhAd0F0=")));

	_wi_test_crypto_cipher(WI_CIPHER_3DES192, WI_STR("Triple DES"), 192,
						   wi_data_with_base64(WI_STR("bqXg+ZSQxitsx5ynTe04m7tNq6PDNQoF")),
						   wi_data_with_base64(WI_STR("mY2Zs19VJeE=")));
#endif
}



#ifdef WI_CIPHERS

static void _wi_test_crypto_cipher(wi_cipher_type_t type, wi_string_t *name, wi_uinteger_t bits, wi_data_t *key, wi_data_t *iv) {
	wi_cipher_t		*cipher;
	
	cipher = wi_autorelease(wi_cipher_init_with_key(wi_cipher_alloc(), type, key, iv));
	
	if(!cipher && wi_error_domain() == WI_ERROR_DOMAIN_LIBWIRED && wi_error_code() == WI_ERROR_CIPHER_CIPHERNOTSUPP)
		return;
	
	WI_TEST_ASSERT_NOT_NULL(cipher, "");
	WI_TEST_ASSERT_EQUAL_INSTANCES(wi_cipher_key(cipher), key, "");
	WI_TEST_ASSERT_EQUAL_INSTANCES(wi_cipher_iv(cipher), iv, "");
	WI_TEST_ASSERT_EQUALS(wi_cipher_type(cipher), type, "");
	WI_TEST_ASSERT_EQUALS(wi_cipher_bits(cipher), bits, "");
	WI_TEST_ASSERT_EQUAL_INSTANCES(wi_cipher_name(cipher), name, "");
	
	WI_TEST_ASSERT_EQUAL_INSTANCES(
		wi_cipher_decrypt(cipher, wi_cipher_encrypt(cipher, wi_string_data(WI_STR("hello world")))),
		wi_string_data(WI_STR("hello world")),
		"%m");
	
	cipher = wi_autorelease(wi_cipher_init_with_random_key(wi_cipher_alloc(), type));

	WI_TEST_ASSERT_NOT_NULL(cipher, "");
}

#endif



void wi_test_crypto_rsa(void) {
#ifdef WI_RSA
	wi_rsa_t		*rsa;
	
	rsa = wi_autorelease(wi_rsa_init_with_private_key(wi_rsa_alloc(), wi_data_with_base64(WI_STR("MIIBOwIBAAJBANlpi/JRzsGFCHyHARWkjg6qLnNjvgo84Shha4aOKQlQVON6LjVUTKuTGodkp7yZK0W4gfoNF/5CNbXb1Qo4xcUCAwEAAQJAafHFAJBc8HCjcgtXu/Q0RXEosZIpSVPhZIwUmb0swhw9LULNarL244HT2WJ/pSSUu3uIx+sT6mpNL+OtunQJAQIhAPSgtPWiWbHE7Bf3F4GS87PuVD2uYj9nbHuGAqfkrTaLAiEA44Tzb52/2dKz56sOW/ga/4ydsQeIQAxVBmr3uHK9zu8CIQDzQviQp5CQUeYBcurCJHMKA79r0wTKTju3niz37lQ9PwIhANdjtv5UzhpNgalxY++nSw/gtCyy38capaekvo2seoqbAiBYCzlmjq02JpohH29ijG52ecfb88uS9eUufUVoOfTC/A=="))));

	WI_TEST_ASSERT_NOT_NULL(rsa, "");
	WI_TEST_ASSERT_EQUALS(wi_rsa_bits(rsa), 512U, "");

	WI_TEST_ASSERT_EQUAL_INSTANCES(
		wi_rsa_public_key(rsa),
		wi_data_with_base64(WI_STR("MEgCQQDZaYvyUc7BhQh8hwEVpI4Oqi5zY74KPOEoYWuGjikJUFTjei41VEyrkxqHZKe8mStFuIH6DRf+QjW129UKOMXFAgMBAAE=")),
		"");
	
	WI_TEST_ASSERT_EQUAL_INSTANCES(
		wi_rsa_decrypt(rsa, wi_rsa_encrypt(rsa, wi_string_data(WI_STR("hello world")))),
		wi_string_data(WI_STR("hello world")),
		"%m");
	
	WI_TEST_ASSERT_EQUAL_INSTANCES(
		wi_rsa_decrypt(rsa, wi_rsa_encrypt(rsa, wi_string_data(WI_STR("hello world")))),
		wi_string_data(WI_STR("hello world")),
		"%m");

	rsa = wi_autorelease(wi_rsa_init_with_bits(wi_rsa_alloc(), 512));

	WI_TEST_ASSERT_NOT_NULL(rsa, "");
	WI_TEST_ASSERT_EQUALS(wi_rsa_bits(rsa), 512U, "");
#endif
}
