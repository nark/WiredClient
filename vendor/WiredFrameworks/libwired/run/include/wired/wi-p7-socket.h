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

#ifndef WI_P7_SOCKET_H
#define WI_P7_SOCKET_H 1

#include <wired/wi-base.h>
#include <wired/wi-cipher.h>
#include <wired/wi-rsa.h>
#include <wired/wi-runtime.h>
#include <wired/wi-socket.h>

#define WI_P7_COMPRESSION_ENABLED(options)					\
	(((options) & WI_P7_COMPRESSION_DEFLATE))

#define WI_P7_ENCRYPTION_ENABLED(options)					\
	(((options) & WI_P7_ENCRYPTION_RSA_AES128_SHA1) ||		\
	 ((options) & WI_P7_ENCRYPTION_RSA_AES192_SHA1) ||		\
	 ((options) & WI_P7_ENCRYPTION_RSA_AES256_SHA1) ||		\
	 ((options) & WI_P7_ENCRYPTION_RSA_BF128_SHA1)  ||		\
	 ((options) & WI_P7_ENCRYPTION_RSA_3DES192_SHA1) ||		\
	 ((options) & WI_P7_ENCRYPTION_RSA_AES256_SHA256))			

#define WI_P7_CHECKSUM_ENABLED(options)						\
	(((options) & WI_P7_CHECKSUM_SHA1)  || 					\
	 ((options) & WI_P7_CHECKSUM_SHA256))


enum _wi_p7_options {
	WI_P7_COMPRESSION_DEFLATE						= (1 << 0),
	WI_P7_ENCRYPTION_RSA_AES128_SHA1				= (1 << 1),
	WI_P7_ENCRYPTION_RSA_AES192_SHA1				= (1 << 2),
	WI_P7_ENCRYPTION_RSA_AES256_SHA1				= (1 << 3),
	WI_P7_ENCRYPTION_RSA_BF128_SHA1					= (1 << 4),
	WI_P7_ENCRYPTION_RSA_3DES192_SHA1				= (1 << 5),
	WI_P7_ENCRYPTION_RSA_AES256_SHA256				= (1 << 6),
	WI_P7_CHECKSUM_SHA1								= (1 << 7),
	WI_P7_CHECKSUM_SHA256							= (1 << 8),
	WI_P7_ALL										= (WI_P7_COMPRESSION_DEFLATE |
													   WI_P7_ENCRYPTION_RSA_AES128_SHA1 |
													   WI_P7_ENCRYPTION_RSA_AES192_SHA1 |
													   WI_P7_ENCRYPTION_RSA_AES256_SHA1 |
													   WI_P7_ENCRYPTION_RSA_BF128_SHA1 |
													   WI_P7_ENCRYPTION_RSA_3DES192_SHA1 |
													   WI_P7_ENCRYPTION_RSA_AES256_SHA256 |
													   WI_P7_CHECKSUM_SHA1 | 
													   WI_P7_CHECKSUM_SHA256)
};
typedef enum _wi_p7_options							wi_p7_options_t;

typedef void										wi_p7_socket_message_callback_func_t(wi_p7_socket_t *, wi_p7_message_t *, void *);


typedef wi_string_t *								wi_p7_socket_password_provider_func_t(wi_string_t *);


WI_EXPORT wi_runtime_id_t							wi_p7_socket_runtime_id(void);

WI_EXPORT wi_p7_socket_t *							wi_p7_socket_alloc(void);
WI_EXPORT wi_p7_socket_t *							wi_p7_socket_init_with_descriptor(wi_p7_socket_t *, int, wi_p7_spec_t *);
WI_EXPORT wi_p7_socket_t *							wi_p7_socket_init_with_socket(wi_p7_socket_t *, wi_socket_t *, wi_p7_spec_t *);

WI_EXPORT void										wi_p7_socket_set_private_key(wi_p7_socket_t *, wi_rsa_t *);
WI_EXPORT wi_rsa_t *								wi_p7_socket_private_key(wi_p7_socket_t *);
WI_EXPORT wi_rsa_t *								wi_p7_socket_public_key(wi_p7_socket_t *);
WI_EXPORT void										wi_p7_socket_set_tls(wi_p7_socket_t *, wi_socket_tls_t *);
WI_EXPORT wi_socket_tls_t *							wi_p7_socket_tls(wi_p7_socket_t *);
WI_EXPORT void										wi_p7_socket_set_read_message_callback(wi_p7_socket_t *, wi_p7_socket_message_callback_func_t *, void *);
WI_EXPORT void										wi_p7_socket_set_wrote_message_callback(wi_p7_socket_t *, wi_p7_socket_message_callback_func_t *, void *);

WI_EXPORT wi_socket_t *								wi_p7_socket_socket(wi_p7_socket_t *);
WI_EXPORT wi_p7_spec_t *							wi_p7_socket_spec(wi_p7_socket_t *);
WI_EXPORT wi_cipher_t *								wi_p7_socket_cipher(wi_p7_socket_t *);
WI_EXPORT wi_uinteger_t								wi_p7_socket_options(wi_p7_socket_t *);
WI_EXPORT wi_p7_serialization_t						wi_p7_socket_serialization(wi_p7_socket_t *);
WI_EXPORT wi_string_t *								wi_p7_socket_remote_protocol_name(wi_p7_socket_t *);
WI_EXPORT wi_string_t *								wi_p7_socket_remote_protocol_version(wi_p7_socket_t *);
WI_EXPORT wi_string_t *								wi_p7_socket_user_name(wi_p7_socket_t *);
WI_EXPORT double									wi_p7_socket_compression_ratio(wi_p7_socket_t *);

WI_EXPORT wi_boolean_t								wi_p7_socket_verify_message(wi_p7_socket_t *, wi_p7_message_t *);

WI_EXPORT wi_boolean_t								wi_p7_socket_connect(wi_p7_socket_t *, wi_time_interval_t, wi_uinteger_t, wi_p7_serialization_t, wi_string_t *, wi_string_t *);
WI_EXPORT wi_boolean_t								wi_p7_socket_accept(wi_p7_socket_t *, wi_time_interval_t, wi_uinteger_t);
WI_EXPORT void										wi_p7_socket_close(wi_p7_socket_t *);

WI_EXPORT wi_boolean_t								wi_p7_socket_write_message(wi_p7_socket_t *, wi_time_interval_t, wi_p7_message_t *);
WI_EXPORT wi_p7_message_t *							wi_p7_socket_read_message(wi_p7_socket_t *, wi_time_interval_t);
WI_EXPORT wi_boolean_t								wi_p7_socket_write_oobdata(wi_p7_socket_t *, wi_time_interval_t, const void *, uint32_t);
WI_EXPORT wi_integer_t								wi_p7_socket_read_oobdata(wi_p7_socket_t *, wi_time_interval_t, void **);


WI_EXPORT wi_boolean_t								wi_p7_socket_debug;
WI_EXPORT wi_p7_socket_password_provider_func_t		*wi_p7_socket_password_provider;

#endif /* WI_P7_SOCKET_H */
