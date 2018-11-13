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

#ifndef WI_P7

int wi_p7_socket_dummy = 0;

#else

#include <wired/wi-byteorder.h>
#include <wired/wi-cipher.h>
#include <wired/wi-dictionary.h>
#include <wired/wi-digest.h>
#include <wired/wi-error.h>
#include <wired/wi-log.h>
#include <wired/wi-p7-message.h>
#include <wired/wi-p7-socket.h>
#include <wired/wi-p7-spec.h>
#include <wired/wi-p7-private.h>
#include <wired/wi-private.h>
#include <wired/wi-rsa.h>
#include <wired/wi-string.h>
#include <wired/wi-system.h>

#include <sys/types.h>
#include <sys/uio.h>
#include <unistd.h>
#include <string.h>
#include <errno.h>

#include <zlib.h>

#define _WI_P7_SOCKET_XML_MAGIC								0x3C3F786D
#define _WI_P7_SOCKET_LENGTH_SIZE							4
#define _WI_P7_SOCKET_MAX_BINARY_SIZE						(10 * 1024 * 1024)

#define _WI_P7_COMPRESSION_DEFLATE							0

#define _WI_P7_ENCRYPTION_RSA_AES128_SHA1					0	
#define _WI_P7_ENCRYPTION_RSA_AES192_SHA1					1
#define _WI_P7_ENCRYPTION_RSA_AES256_SHA1					2
#define _WI_P7_ENCRYPTION_RSA_BF128_SHA1					3
#define _WI_P7_ENCRYPTION_RSA_3DES192_SHA1					4
#define _WI_P7_ENCRYPTION_RSA_AES256_SHA256					5

#define _WI_P7_CHECKSUM_SHA1								0
#define _WI_P7_CHECKSUM_SHA256								1

#define _WI_P7_COMPRESSION_ENUM_TO_OPTIONS(flag)			\
	((flag) == _WI_P7_COMPRESSION_DEFLATE ?					\
		WI_P7_COMPRESSION_DEFLATE : -1)

#define _WI_P7_ENCRYPTION_ENUM_TO_OPTIONS(flag)				\
	((flag) == _WI_P7_ENCRYPTION_RSA_AES128_SHA1 ?			\
		WI_P7_ENCRYPTION_RSA_AES128_SHA1 :					\
	 (flag) == _WI_P7_ENCRYPTION_RSA_AES192_SHA1 ?			\
		WI_P7_ENCRYPTION_RSA_AES192_SHA1 :					\
	 (flag) == _WI_P7_ENCRYPTION_RSA_AES256_SHA1 ?			\
		WI_P7_ENCRYPTION_RSA_AES256_SHA1 :					\
	 (flag) == _WI_P7_ENCRYPTION_RSA_BF128_SHA1 ?			\
		WI_P7_ENCRYPTION_RSA_BF128_SHA1 :					\
	 (flag) == _WI_P7_ENCRYPTION_RSA_3DES192_SHA1 ?			\
		WI_P7_ENCRYPTION_RSA_3DES192_SHA1 :					\
	 (flag) == _WI_P7_ENCRYPTION_RSA_AES256_SHA256 ?		\
		WI_P7_ENCRYPTION_RSA_AES256_SHA256 : -1)

#define _WI_P7_CHECKSUM_ENUM_TO_OPTIONS(flag)				\
	((flag) == _WI_P7_CHECKSUM_SHA1 ?						\
		WI_P7_CHECKSUM_SHA1 : 								\
	 (flag) == _WI_P7_CHECKSUM_SHA256 ?						\
	 	WI_P7_CHECKSUM_SHA256 : -1)

#define _WI_P7_COMPRESSION_OPTIONS_TO_ENUM(options)			\
	((options) & WI_P7_COMPRESSION_DEFLATE ?				\
		_WI_P7_COMPRESSION_DEFLATE : -1)

#define _WI_P7_ENCRYPTION_OPTIONS_TO_ENUM(options)			\
	((options) & WI_P7_ENCRYPTION_RSA_AES128_SHA1 ?			\
		_WI_P7_ENCRYPTION_RSA_AES128_SHA1 :					\
	 (options) & WI_P7_ENCRYPTION_RSA_AES192_SHA1 ?			\
		_WI_P7_ENCRYPTION_RSA_AES192_SHA1 :					\
	 (options) & WI_P7_ENCRYPTION_RSA_AES256_SHA1 ?			\
		_WI_P7_ENCRYPTION_RSA_AES256_SHA1 :					\
	 (options) & WI_P7_ENCRYPTION_RSA_BF128_SHA1 ?			\
		_WI_P7_ENCRYPTION_RSA_BF128_SHA1 :					\
	 (options) & WI_P7_ENCRYPTION_RSA_3DES192_SHA1 ?		\
		_WI_P7_ENCRYPTION_RSA_3DES192_SHA1 :				\
	 (options) & WI_P7_ENCRYPTION_RSA_AES256_SHA256 ?		\
		_WI_P7_ENCRYPTION_RSA_AES256_SHA256 : -1)

#define _WI_P7_CHECKSUM_OPTIONS_TO_ENUM(options)			\
	((options) & WI_P7_CHECKSUM_SHA1 ?						\
		_WI_P7_CHECKSUM_SHA1 : 								\
	 (options) & WI_P7_CHECKSUM_SHA256 ?					\
		_WI_P7_CHECKSUM_SHA256 : -1)

#define _WI_P7_CHECKSUM_OPTIONS_TO_LENGTH(options)			\
	((options) & WI_P7_CHECKSUM_SHA1 ?						\
		WI_SHA1_DIGEST_LENGTH : 							\
	 (options) & WI_P7_CHECKSUM_SHA256 ?					\
		WI_SHA256_DIGEST_LENGTH : WI_SHA1_DIGEST_LENGTH)

#define _WI_P7_ENCRYPTION_OPTIONS_TO_CIPHER(options)		\
	((options) & WI_P7_ENCRYPTION_RSA_AES128_SHA1 ?			\
		WI_CIPHER_AES128 :									\
	 (options) & WI_P7_ENCRYPTION_RSA_AES192_SHA1 ?			\
		WI_CIPHER_AES192 :									\
	 (options) & WI_P7_ENCRYPTION_RSA_AES256_SHA1 ?			\
		WI_CIPHER_AES256 :									\
	 (options) & WI_P7_ENCRYPTION_RSA_BF128_SHA1 ?			\
		WI_CIPHER_BF128 :									\
	 (options) & WI_P7_ENCRYPTION_RSA_3DES192_SHA1 ?		\
		WI_CIPHER_3DES192 :									\
	 (options) & WI_P7_ENCRYPTION_RSA_AES256_SHA256 ?		\
		WI_CIPHER_AES256 : -1)


struct _wi_p7_socket {
	wi_runtime_base_t						base;
	
	wi_socket_t								*socket;
	wi_p7_spec_t							*spec;
	wi_p7_spec_t							*merged_spec;
	
	wi_string_t								*remote_name;
	wi_string_t								*remote_version;
	
	wi_string_t								*user_name;
	
	wi_p7_serialization_t					serialization;
	wi_uinteger_t							options;
	
	uint32_t								message_binary_size;
	
#ifdef WI_RSA
	wi_boolean_t							encryption_enabled;
	wi_rsa_t								*private_key;
	wi_rsa_t								*public_key;
	wi_cipher_t								*cipher;
#endif
	
	wi_boolean_t							compression_enabled;
	z_stream								deflate_stream;
	z_stream								inflate_stream;
	
	wi_boolean_t							checksum_enabled;
	wi_uinteger_t							checksum_length;
	
	wi_p7_boolean_t							local_compatibility_check;
	wi_p7_boolean_t							remote_compatibility_check;
	
	void									*compression_buffer;
	wi_uinteger_t							compression_buffer_length;
	void									*encryption_buffer;
	wi_uinteger_t							encryption_buffer_length;
	void									*decryption_buffer;
	wi_uinteger_t							decryption_buffer_length;
	void									*oobdata_read_buffer;
	wi_uinteger_t							oobdata_read_buffer_length;
	
	wi_p7_socket_message_callback_func_t	*read_message_callback;
	void									*read_message_context;
	
	wi_p7_socket_message_callback_func_t	*wrote_message_callback;
	void									*wrote_message_context;
	
	uint64_t								read_raw_bytes, read_processed_bytes;
	uint64_t								sent_raw_bytes, sent_processed_bytes;
};


enum _wi_p7_socket_compression {
	_WI_P7_SOCKET_COMPRESS,
	_WI_P7_SOCKET_DECOMPRESS,
};
typedef enum _wi_p7_socket_compression		_wi_p7_socket_compression_t;


static void									_wi_p7_socket_dealloc(wi_runtime_instance_t *);
static wi_string_t *						_wi_p7_socket_description(wi_runtime_instance_t *);

static wi_boolean_t							_wi_p7_socket_connect_handshake(wi_p7_socket_t *, wi_time_interval_t, wi_uinteger_t);
static wi_boolean_t							_wi_p7_socket_accept_handshake(wi_p7_socket_t *, wi_time_interval_t, wi_uinteger_t);

#ifdef WI_RSA
static wi_boolean_t							_wi_p7_socket_connect_key_exchange(wi_p7_socket_t *, wi_time_interval_t, wi_string_t *, wi_string_t *);
static wi_boolean_t							_wi_p7_socket_accept_key_exchange(wi_p7_socket_t *, wi_time_interval_t);
static wi_boolean_t							_wi_p7_password_is_equal(wi_string_t *, wi_string_t *);
#endif

static wi_boolean_t							_wi_p7_socket_send_compatibility_check(wi_p7_socket_t *, wi_time_interval_t);
static wi_boolean_t							_wi_p7_socket_receive_compatibility_check(wi_p7_socket_t *, wi_time_interval_t);

static wi_boolean_t							_wi_p7_socket_write_binary_message(wi_p7_socket_t *, wi_time_interval_t, wi_p7_message_t *);
static wi_boolean_t							_wi_p7_socket_write_xml_message(wi_p7_socket_t *, wi_time_interval_t, wi_p7_message_t *);
static wi_p7_message_t *					_wi_p7_socket_read_binary_message(wi_p7_socket_t *, wi_time_interval_t, uint32_t);
static wi_p7_message_t *					_wi_p7_socket_read_xml_message(wi_p7_socket_t *, wi_time_interval_t, wi_string_t *);

static wi_boolean_t							_wi_p7_socket_configure_compression(wi_p7_socket_t *);
static wi_integer_t							_wi_p7_socket_deflate(wi_p7_socket_t *, const void *, uint32_t);
static wi_integer_t							_wi_p7_socket_inflate(wi_p7_socket_t *, const void *, uint32_t);

static void									_wi_p7_socket_configure_checksum(wi_p7_socket_t *);
static void									_wi_p7_socket_checksum_binary_message(wi_p7_socket_t *, wi_p7_message_t *, void *);
static void									_wi_p7_socket_checksum_buffer(wi_p7_socket_t *, const void *, uint32_t, void *);

static wi_string_t *						_wi_p7_socket_string_checksum(wi_p7_socket_t *, wi_string_t *);
static wi_string_t *						_wi_p7_socket_data_checksum(wi_p7_socket_t *, wi_data_t *);

wi_boolean_t								wi_p7_socket_debug = false;
wi_p7_socket_password_provider_func_t		*wi_p7_socket_password_provider = NULL;

static wi_runtime_id_t						_wi_p7_socket_runtime_id = WI_RUNTIME_ID_NULL;
static wi_runtime_class_t					_wi_p7_socket_runtime_class = {
    "wi_p7_socket_t",
    _wi_p7_socket_dealloc,
    NULL,
    NULL,
    _wi_p7_socket_description,
    NULL
};



void wi_p7_socket_register(void) {
    _wi_p7_socket_runtime_id = wi_runtime_register_class(&_wi_p7_socket_runtime_class);
}



void wi_p7_socket_initialize(void) {
	char	*env;
	
	env = getenv("wi_p7_socket_debug");
	
	if(env) {
		wi_p7_socket_debug = (strcmp(env, "0") != 0);
		
		printf("*** wi_p7_socket_initialize(): wi_p7_socket_debug = %u\n", wi_p7_socket_debug);
	}
}



#pragma mark -

wi_runtime_id_t wi_p7_socket_runtime_id(void) {
    return _wi_p7_socket_runtime_id;
}



#pragma mark -

wi_p7_socket_t * wi_p7_socket_alloc(void) {
    return wi_runtime_create_instance(_wi_p7_socket_runtime_id, sizeof(wi_p7_socket_t));
}



wi_p7_socket_t * wi_p7_socket_init_with_descriptor(wi_p7_socket_t *p7_socket, int sd, wi_p7_spec_t *p7_spec) {
	p7_socket->socket	= wi_socket_init_with_descriptor(wi_socket_alloc(), sd);
	p7_socket->spec		= wi_retain(p7_spec);

	return p7_socket;
}



wi_p7_socket_t * wi_p7_socket_init_with_socket(wi_p7_socket_t *p7_socket, wi_socket_t *socket, wi_p7_spec_t *p7_spec) {
	p7_socket->socket	= wi_retain(socket);
	p7_socket->spec		= wi_retain(p7_spec);
	
	return p7_socket;
}



static void _wi_p7_socket_dealloc(wi_runtime_instance_t *instance) {
	wi_p7_socket_t		*p7_socket = instance;

	if(p7_socket->compression_enabled) {
		deflateEnd(&p7_socket->deflate_stream);
		inflateEnd(&p7_socket->inflate_stream);
	}
	
	wi_free(p7_socket->compression_buffer);
	wi_free(p7_socket->encryption_buffer);
	wi_free(p7_socket->decryption_buffer);
	wi_free(p7_socket->oobdata_read_buffer);
	
	wi_release(p7_socket->socket);
	wi_release(p7_socket->spec);
	wi_release(p7_socket->merged_spec);
	wi_release(p7_socket->remote_name);
	wi_release(p7_socket->remote_version);
	wi_release(p7_socket->user_name);
	
#ifdef WI_RSA
	wi_release(p7_socket->private_key);
	wi_release(p7_socket->public_key);
	wi_release(p7_socket->cipher);
#endif
}



static wi_string_t * _wi_p7_socket_description(wi_runtime_instance_t *instance) {
	wi_p7_socket_t		*p7_socket = instance;

	return wi_string_with_format(WI_STR("<%@ %p>{options = 0x%X, socket = %@}"),
		wi_runtime_class_name(p7_socket),
		p7_socket,
		p7_socket->options,
		p7_socket->socket);
}



#pragma mark -

#ifdef WI_RSA

void wi_p7_socket_set_private_key(wi_p7_socket_t *p7_socket, wi_rsa_t *rsa) {
	wi_release(p7_socket->private_key);
	
	p7_socket->private_key = wi_copy(rsa);
}



wi_rsa_t * wi_p7_socket_private_key(wi_p7_socket_t *p7_socket) {
	return p7_socket->private_key;
}



wi_rsa_t * wi_p7_socket_public_key(wi_p7_socket_t *p7_socket) {
	return p7_socket->public_key;
}

#endif



void wi_p7_socket_set_read_message_callback(wi_p7_socket_t *p7_socket, wi_p7_socket_message_callback_func_t *callback, void *context) {
	p7_socket->read_message_callback = callback;
	p7_socket->read_message_context = context;
}



void wi_p7_socket_set_wrote_message_callback(wi_p7_socket_t *p7_socket, wi_p7_socket_message_callback_func_t *callback, void *context) {
	p7_socket->wrote_message_callback = callback;
	p7_socket->wrote_message_context = context;
}



#pragma mark -

wi_socket_t * wi_p7_socket_socket(wi_p7_socket_t *p7_socket) {
	return p7_socket->socket;
}



wi_p7_spec_t * wi_p7_socket_spec(wi_p7_socket_t *p7_socket) {
	return p7_socket->spec;
}



#ifdef WI_RSA

wi_cipher_t * wi_p7_socket_cipher(wi_p7_socket_t *p7_socket) {
	return p7_socket->cipher;
}

#endif



wi_uinteger_t wi_p7_socket_options(wi_p7_socket_t *p7_socket) {
	return p7_socket->options;
}



wi_p7_serialization_t wi_p7_socket_serialization(wi_p7_socket_t *p7_socket) {
	return p7_socket->serialization;
}



wi_string_t * wi_p7_socket_remote_protocol_name(wi_p7_socket_t *p7_socket) {
	return p7_socket->remote_name;
}



wi_string_t * wi_p7_socket_remote_protocol_version(wi_p7_socket_t *p7_socket) {
	return p7_socket->remote_version;
}



wi_string_t * wi_p7_socket_user_name(wi_p7_socket_t *p7_socket) {
	return p7_socket->user_name;
}



double wi_p7_socket_compression_ratio(wi_p7_socket_t *p7_socket) {
	return ((double) (p7_socket->sent_raw_bytes + p7_socket->read_processed_bytes) /
			(double) (p7_socket->sent_processed_bytes + p7_socket->read_raw_bytes));
}



#pragma mark -

static wi_boolean_t _wi_p7_socket_connect_handshake(wi_p7_socket_t *p7_socket, wi_time_interval_t timeout, wi_uinteger_t options) {
	wi_string_t			*version;
	wi_p7_message_t		*p7_message;
	wi_p7_enum_t		flag;
	
	p7_message = wi_p7_message_with_name(WI_STR("p7.handshake.client_handshake"), wi_p7_socket_spec(p7_socket));
	
	if(!p7_message)
		return false;

	if(!wi_p7_message_set_string_for_name(p7_message, wi_p7_spec_version(wi_p7_spec_builtin_spec()), WI_STR("p7.handshake.version")))
		return false;
	
	if(!wi_p7_message_set_string_for_name(p7_message, wi_p7_spec_name(p7_socket->spec), WI_STR("p7.handshake.protocol.name")))
		return false;
	
	if(!wi_p7_message_set_string_for_name(p7_message, wi_p7_spec_version(p7_socket->spec), WI_STR("p7.handshake.protocol.version")))
		return false;
	
	if(p7_socket->serialization == WI_P7_BINARY) {
		if(WI_P7_COMPRESSION_ENABLED(options)) {
			if(!wi_p7_message_set_enum_for_name(p7_message,
												_WI_P7_COMPRESSION_OPTIONS_TO_ENUM(options),
												WI_STR("p7.handshake.compression"))) {
				return false;
			}
		}
		
		if(WI_P7_ENCRYPTION_ENABLED(options)) {
#ifdef WI_RSA
			if(!wi_p7_message_set_enum_for_name(p7_message,
												_WI_P7_ENCRYPTION_OPTIONS_TO_ENUM(options),
												WI_STR("p7.handshake.encryption"))) {
				return false;
			}
#else
			wi_error_set_libwired_error(WI_ERROR_P7_RSANOTSUPP);
			
			return false;
#endif
		}
		
		if(WI_P7_CHECKSUM_ENABLED(options)) {
			if(!wi_p7_message_set_enum_for_name(p7_message,
												_WI_P7_CHECKSUM_OPTIONS_TO_ENUM(options),
												WI_STR("p7.handshake.checksum"))) {
				return false;
			}
		}
	}
	
	if(!wi_p7_socket_write_message(p7_socket, timeout, p7_message))
		return false;
	
	p7_message = wi_p7_socket_read_message(p7_socket, timeout);
	
	if(!p7_message)
		return false;

	if(!wi_is_equal(p7_message->name, WI_STR("p7.handshake.server_handshake"))) {
		wi_error_set_libwired_error_with_format(WI_ERROR_P7_HANDSHAKEFAILED,
			WI_STR("Message should be \"p7.handshake.server_handshake\", not \"%@\""),
			p7_message->name);
		
		return false;
	}
	
	version = wi_p7_message_string_for_name(p7_message, WI_STR("p7.handshake.version"));
	
	if(!version) {
		wi_error_set_libwired_error_with_format(WI_ERROR_P7_HANDSHAKEFAILED,
			WI_STR("Message has no \"p7.handshake.version\" field"));
		
		return false;
	}

	if(!wi_is_equal(version, wi_p7_spec_version(wi_p7_spec_builtin_spec()))) {
		wi_error_set_libwired_error_with_format(WI_ERROR_P7_HANDSHAKEFAILED,
			WI_STR("Remote P7 protocol %.1f is not compatible"),
			version);
		
		return false;
	}
	
	p7_socket->remote_name = wi_retain(wi_p7_message_string_for_name(p7_message, WI_STR("p7.handshake.protocol.name")));
	
	if(!p7_socket->remote_name) {
		wi_error_set_libwired_error_with_format(WI_ERROR_P7_HANDSHAKEFAILED,
			WI_STR("Message has no \"p7.handshake.protocol.name\" field"));
		
		return false;
	}
	
	p7_socket->remote_version = wi_retain(wi_p7_message_string_for_name(p7_message, WI_STR("p7.handshake.protocol.version")));

	if(!p7_socket->remote_version) {
		wi_error_set_libwired_error_with_format(WI_ERROR_P7_HANDSHAKEFAILED,
			WI_STR("Message has no \"p7.handshake.protocol.version\" field"));
		
		return false;
	}
	
	p7_socket->local_compatibility_check = !wi_p7_spec_is_compatible_with_protocol(p7_socket->spec, p7_socket->remote_name, p7_socket->remote_version);

	if(p7_socket->serialization == WI_P7_BINARY) {
		if(wi_p7_message_get_enum_for_name(p7_message, &flag, WI_STR("p7.handshake.compression")))
			p7_socket->options |= _WI_P7_COMPRESSION_ENUM_TO_OPTIONS(flag);
	
		if(wi_p7_message_get_enum_for_name(p7_message, &flag, WI_STR("p7.handshake.encryption")))
			p7_socket->options |= _WI_P7_ENCRYPTION_ENUM_TO_OPTIONS(flag);
	
		if(wi_p7_message_get_enum_for_name(p7_message, &flag, WI_STR("p7.handshake.checksum")))
			p7_socket->options |= _WI_P7_CHECKSUM_ENUM_TO_OPTIONS(flag);
	}
	
	if(!wi_p7_message_get_bool_for_name(p7_message, &p7_socket->remote_compatibility_check, WI_STR("p7.handshake.compatibility_check")))
		p7_socket->remote_compatibility_check = false;
	
	p7_message = wi_p7_message_with_name(WI_STR("p7.handshake.acknowledge"), wi_p7_socket_spec(p7_socket));
	
	if(!p7_message)
		return false;
	
	if(p7_socket->local_compatibility_check) {
		if(!wi_p7_message_set_bool_for_name(p7_message, true, WI_STR("p7.handshake.compatibility_check")))
			return false;
	}

	if(!wi_p7_socket_write_message(p7_socket, timeout, p7_message))
		return false;
	
	return true;
}



static wi_boolean_t _wi_p7_socket_accept_handshake(wi_p7_socket_t *p7_socket, wi_time_interval_t timeout, wi_uinteger_t options) {
	wi_string_t			*version;
	wi_p7_message_t		*p7_message;
	wi_p7_enum_t		flag;
	wi_uinteger_t		client_options;
	
	p7_message = wi_p7_socket_read_message(p7_socket, timeout);
	
	if(!p7_message)
		return false;

	if(!wi_is_equal(p7_message->name, WI_STR("p7.handshake.client_handshake"))) {
		wi_error_set_libwired_error_with_format(WI_ERROR_P7_HANDSHAKEFAILED,
			WI_STR("Message should be \"p7.handshake.client_handshake\", not \"%@\""),
			p7_message->name);
		
		return false;
	}
	
	version = wi_p7_message_string_for_name(p7_message, WI_STR("p7.handshake.version"));
	
	if(!version) {
		wi_error_set_libwired_error_with_format(WI_ERROR_P7_HANDSHAKEFAILED,
			WI_STR("Message has no \"p7.handshake.version\" field"));
		
		return false;
	}
	
	if(!wi_is_equal(version, wi_p7_spec_version(wi_p7_spec_builtin_spec()))) {
		wi_error_set_libwired_error_with_format(WI_ERROR_P7_HANDSHAKEFAILED,
			WI_STR("Remote P7 protocol %.1f is not compatible"),
			version);

		return false;
	}
	
	p7_socket->remote_name = wi_retain(wi_p7_message_string_for_name(p7_message, WI_STR("p7.handshake.protocol.name")));
	
	if(!p7_socket->remote_name) {
		wi_error_set_libwired_error_with_format(WI_ERROR_P7_HANDSHAKEFAILED,
			WI_STR("Message has no \"p7.handshake.protocol.name\" field"));
		
		return false;
	}
	
	p7_socket->remote_version = wi_retain(wi_p7_message_string_for_name(p7_message, WI_STR("p7.handshake.protocol.version")));

	if(!p7_socket->remote_version) {
		wi_error_set_libwired_error_with_format(WI_ERROR_P7_HANDSHAKEFAILED,
			WI_STR("Message has no \"p7.handshake.protocol.version\" field"));
		
		return false;
	}

	p7_socket->local_compatibility_check = !wi_p7_spec_is_compatible_with_protocol(p7_socket->spec, p7_socket->remote_name, p7_socket->remote_version);

	if(p7_socket->serialization == WI_P7_BINARY) {
		if(wi_p7_message_get_enum_for_name(p7_message, &flag, WI_STR("p7.handshake.compression"))) {
			client_options = _WI_P7_COMPRESSION_ENUM_TO_OPTIONS(flag);
			
			if(options & client_options)
				p7_socket->options |= client_options;
		}
		
		if(wi_p7_message_get_enum_for_name(p7_message, &flag, WI_STR("p7.handshake.encryption"))) {
			client_options = _WI_P7_ENCRYPTION_ENUM_TO_OPTIONS(flag);

#ifdef WI_RSA
			if(options & client_options)
				p7_socket->options |= client_options;
#endif
		}
		
		if(wi_p7_message_get_enum_for_name(p7_message, &flag, WI_STR("p7.handshake.checksum"))) {
			client_options = _WI_P7_CHECKSUM_ENUM_TO_OPTIONS(flag);

			if(options & client_options)
				p7_socket->options |= client_options;
		}
	}
	
	p7_message = wi_p7_message_with_name(WI_STR("p7.handshake.server_handshake"), wi_p7_socket_spec(p7_socket));

	if(!p7_message)
		return false;
	
	if(!wi_p7_message_set_string_for_name(p7_message, wi_p7_spec_version(wi_p7_spec_builtin_spec()), WI_STR("p7.handshake.version")))
		return false;
	
	if(!wi_p7_message_set_string_for_name(p7_message, wi_p7_spec_name(p7_socket->spec), WI_STR("p7.handshake.protocol.name")))
		return false;
	
	if(!wi_p7_message_set_string_for_name(p7_message, wi_p7_spec_version(p7_socket->spec), WI_STR("p7.handshake.protocol.version")))
		return false;
	
	if(p7_socket->serialization == WI_P7_BINARY) {
		if(WI_P7_COMPRESSION_ENABLED(p7_socket->options)) {
			if(!wi_p7_message_set_enum_for_name(p7_message,
												_WI_P7_COMPRESSION_OPTIONS_TO_ENUM(p7_socket->options),
												WI_STR("p7.handshake.compression"))) {
				return false;
			}
		}

		if(WI_P7_ENCRYPTION_ENABLED(p7_socket->options)) {
			if(!wi_p7_message_set_enum_for_name(p7_message,
												_WI_P7_ENCRYPTION_OPTIONS_TO_ENUM(p7_socket->options),
												WI_STR("p7.handshake.encryption"))) {
				return false;
			}
		}

		if(WI_P7_CHECKSUM_ENABLED(p7_socket->options)) {
			if(!wi_p7_message_set_enum_for_name(p7_message,
												_WI_P7_CHECKSUM_OPTIONS_TO_ENUM(p7_socket->options),
												WI_STR("p7.handshake.checksum"))) {
				return false;
			}
		}
	}
	
	if(p7_socket->local_compatibility_check) {
		if(!wi_p7_message_set_bool_for_name(p7_message, true, WI_STR("p7.handshake.compatibility_check")))
			return false;
	}

	if(!wi_p7_socket_write_message(p7_socket, timeout, p7_message))
		return false;

	p7_message = wi_p7_socket_read_message(p7_socket, timeout);
	
	if(!p7_message)
		return false;

	if(!wi_is_equal(p7_message->name, WI_STR("p7.handshake.acknowledge"))) {
		wi_error_set_libwired_error_with_format(WI_ERROR_P7_HANDSHAKEFAILED,
			WI_STR("Message should be \"p7.handshake.acknowledge\", not \"%@\""),
			p7_message->name);
		
		return false;
	}
	
	if(!wi_p7_message_get_bool_for_name(p7_message, &p7_socket->remote_compatibility_check, WI_STR("p7.handshake.compatibility_check")))
		p7_socket->remote_compatibility_check = false;
	
	return true;
}



#ifdef WI_RSA

static wi_boolean_t _wi_p7_socket_connect_key_exchange(wi_p7_socket_t *p7_socket, wi_time_interval_t timeout, wi_string_t *username, wi_string_t *password) {
	wi_p7_message_t		*p7_message;
	wi_data_t			*data, *rsa;
	wi_string_t			*client_password1, *client_password2, *server_password;

	p7_message = wi_p7_socket_read_message(p7_socket, timeout);
	
	if(!p7_message)
		return false;
	
	if(!wi_is_equal(p7_message->name, WI_STR("p7.encryption.server_key"))) {
		wi_error_set_libwired_error_with_format(WI_ERROR_P7_HANDSHAKEFAILED,
			WI_STR("Message should be \"p7.encryption\", not \"%@\""),
			p7_message->name);
		
		return false;
	}
	
	rsa = wi_p7_message_data_for_name(p7_message, WI_STR("p7.encryption.public_key"));
	
	if(!rsa) {
		wi_error_set_libwired_error_with_format(WI_ERROR_P7_HANDSHAKEFAILED,
			WI_STR("Message has no \"p7.encryption.public_key\" field"));
		
		return false;
	}
	
	p7_socket->public_key = wi_rsa_init_with_public_key(wi_rsa_alloc(), rsa);
	
	if(!p7_socket->public_key)
		return false;
    
	p7_socket->cipher = wi_cipher_init_with_random_key(wi_cipher_alloc(), _WI_P7_ENCRYPTION_OPTIONS_TO_CIPHER(p7_socket->options));
	
	if(!p7_socket->cipher) {
		return false;
	}
        
	p7_message = wi_p7_message_with_name(WI_STR("p7.encryption.client_key"), wi_p7_socket_spec(p7_socket));

	if(!p7_message)
		return false;
	
	data = wi_rsa_encrypt(p7_socket->public_key, wi_cipher_key(p7_socket->cipher));
	
	if(!data)
		return false;
	
	if(!wi_p7_message_set_data_for_name(p7_message, data, WI_STR("p7.encryption.cipher.key")))
		return false;

	data = wi_cipher_iv(p7_socket->cipher);
	
	if(data) {
		data = wi_rsa_encrypt(p7_socket->public_key, data);
		
		if(!data)
			return false;
		
		if(!wi_p7_message_set_data_for_name(p7_message, data, WI_STR("p7.encryption.cipher.iv")))
			return false;
	}
	
	p7_socket->user_name = username ? wi_retain(username) : wi_retain(WI_STR(""));
	
	data = wi_rsa_encrypt(p7_socket->public_key, wi_string_data(p7_socket->user_name));
	
	if(!data)
		return false;
	
	if(!wi_p7_message_set_data_for_name(p7_message, data, WI_STR("p7.encryption.username")))
		return false;
	
	if(!password)
		password = _wi_p7_socket_string_checksum(p7_socket, WI_STR(""));
	
	client_password1 = _wi_p7_socket_data_checksum(p7_socket, wi_data_by_appending_data(wi_string_data(password), rsa));
	client_password2 = _wi_p7_socket_data_checksum(p7_socket, wi_data_by_appending_data(rsa, wi_string_data(password)));
	
	data = wi_rsa_encrypt(p7_socket->public_key, wi_string_data(client_password1));
	
	if(!data)
		return false;

	if(!wi_p7_message_set_data_for_name(p7_message, data, WI_STR("p7.encryption.client_password")))
		return false;
	
	if(!wi_p7_socket_write_message(p7_socket, timeout, p7_message))
		return false;

	p7_message = wi_p7_socket_read_message(p7_socket, timeout);
	
	if(!p7_message)
		return false;
	
	if(wi_is_equal(p7_message->name, WI_STR("p7.encryption.authentication_error"))) {
		wi_error_set_libwired_error(WI_ERROR_P7_AUTHENTICATIONFAILED);
		
		return false;
	}
	
	if(!wi_is_equal(p7_message->name, WI_STR("p7.encryption.acknowledge"))) {
		wi_error_set_libwired_error_with_format(WI_ERROR_P7_HANDSHAKEFAILED,
			WI_STR("Message should be \"p7.encryption.acknowledge\", not \"%@\""),
			p7_message->name);
		
		return false;
	}
	
	data = wi_p7_message_data_for_name(p7_message, WI_STR("p7.encryption.server_password"));
	
	if(!data) {
		wi_error_set_libwired_error_with_format(WI_ERROR_P7_HANDSHAKEFAILED,
			WI_STR("Message has no \"p7.encryption.server_password\" field"));
		
		return false;
	}
	
	data = wi_cipher_decrypt(p7_socket->cipher, data);	
	if(!data)
		return false;
	
	server_password = wi_string_with_data(data);
	
	if(!_wi_p7_password_is_equal(server_password, client_password2)) {
		wi_error_set_libwired_error_with_format(WI_ERROR_P7_HANDSHAKEFAILED,
			WI_STR("Password mismatch during key exchange"));
		
		return false;
	}

	p7_socket->encryption_enabled = true;
	
	return true;
}



static wi_boolean_t _wi_p7_socket_accept_key_exchange(wi_p7_socket_t *p7_socket, wi_time_interval_t timeout) {
	wi_p7_message_t		*p7_message;
	wi_data_t			*data, *rsa, *key, *iv;
	wi_string_t			*string, *client_password, *server_password1, *server_password2;
	
	p7_message = wi_p7_message_with_name(WI_STR("p7.encryption.server_key"), wi_p7_socket_spec(p7_socket));

	if(!p7_message)
		return false;
	
	if(!p7_socket->private_key) {
		wi_error_set_libwired_error(WI_ERROR_P7_NORSAKEY);
		
		return false;
	}
	
	rsa = wi_rsa_public_key(p7_socket->private_key);
	
	if(!wi_p7_message_set_data_for_name(p7_message, rsa, WI_STR("p7.encryption.public_key")))
		return false;
	
	if(!wi_p7_socket_write_message(p7_socket, timeout, p7_message))
		return false;
	
	p7_message = wi_p7_socket_read_message(p7_socket, timeout);
	
	if(!p7_message)
		return false;
	
	if(!wi_is_equal(p7_message->name, WI_STR("p7.encryption.client_key"))) {
		wi_error_set_libwired_error_with_format(WI_ERROR_P7_HANDSHAKEFAILED,
			WI_STR("Message should be \"p7.encryption.reply\", not \"%@\""),
			p7_message->name);
		
		return false;
	}

	key		= wi_p7_message_data_for_name(p7_message, WI_STR("p7.encryption.cipher.key"));
	iv		= wi_p7_message_data_for_name(p7_message, WI_STR("p7.encryption.cipher.iv"));

	if(!key) {
		wi_error_set_libwired_error_with_format(WI_ERROR_P7_HANDSHAKEFAILED,
			WI_STR("Message has no \"p7.encryption.cipher.key\" field"));
		
		return false;
	}
	
	key = wi_rsa_decrypt(p7_socket->private_key, key);
	
	if(!key)
		return false;
	
	if(iv) {
		iv = wi_rsa_decrypt(p7_socket->private_key, iv);
		
		if(!iv)
			return false;
	}

	p7_socket->cipher = wi_cipher_init_with_key(wi_cipher_alloc(), _WI_P7_ENCRYPTION_OPTIONS_TO_CIPHER(p7_socket->options), key, iv);

	if(!p7_socket->cipher)
		return false;
	
	data = wi_p7_message_data_for_name(p7_message, WI_STR("p7.encryption.username"));

	if(!data) {
		wi_error_set_libwired_error_with_format(WI_ERROR_P7_HANDSHAKEFAILED,
			WI_STR("Message has no \"p7.encryption.username\" field"));
		
		return false;
	}
	
	data = wi_rsa_decrypt(p7_socket->private_key, data);
	
	if(!data)
		return false;
	
	p7_socket->user_name = wi_string_init_with_data(wi_string_alloc(), data);
	
	data = wi_p7_message_data_for_name(p7_message, WI_STR("p7.encryption.client_password"));

	if(!data) {
		wi_error_set_libwired_error_with_format(WI_ERROR_P7_HANDSHAKEFAILED,
			WI_STR("Message has no \"p7.encryption.client_password\" field"));
		
		return false;
	}
	
	data = wi_rsa_decrypt(p7_socket->private_key, data);
	
	if(!data)
		return false;

	client_password = wi_string_with_data(data);
	
	if(wi_p7_socket_password_provider) {
		string = (*wi_p7_socket_password_provider)(p7_socket->user_name);
		
		if(!string) {
			wi_error_set_libwired_error_with_format(WI_ERROR_P7_AUTHENTICATIONFAILED,
				WI_STR("Unknown user \"%@\" during key exchange"),
				p7_socket->user_name);
			
			p7_message = wi_p7_message_with_name(WI_STR("p7.encryption.authentication_error"), wi_p7_socket_spec(p7_socket));
			wi_p7_socket_write_message(p7_socket, timeout, p7_message);

			return false;
		}
	} else {
		string = _wi_p7_socket_string_checksum(p7_socket, WI_STR(""));
	}
	
	server_password1 = _wi_p7_socket_data_checksum(p7_socket, wi_data_by_appending_data(wi_string_data(string), rsa));
	server_password2 = _wi_p7_socket_data_checksum(p7_socket, wi_data_by_appending_data(rsa, wi_string_data(string)));

	if(!_wi_p7_password_is_equal(client_password, server_password1)) {
		wi_error_set_libwired_error_with_format(WI_ERROR_P7_AUTHENTICATIONFAILED,
			WI_STR("Password mismatch for \"%@\" during key exchange"),
			p7_socket->user_name);
		
		p7_message = wi_p7_message_with_name(WI_STR("p7.encryption.authentication_error"), wi_p7_socket_spec(p7_socket));
		wi_p7_socket_write_message(p7_socket, timeout, p7_message);
		
		return false;
	}
	
	p7_message = wi_p7_message_with_name(WI_STR("p7.encryption.acknowledge"), wi_p7_socket_spec(p7_socket));
	
	if(!p7_message)
		return false;
	
	data = wi_cipher_encrypt(p7_socket->cipher, wi_string_data(server_password2));
	
	if(!data)
		return false;

	if(!wi_p7_message_set_data_for_name(p7_message, data, WI_STR("p7.encryption.server_password")))
		return false;

	if(!wi_p7_socket_write_message(p7_socket, timeout, p7_message))
		return false;

	p7_socket->encryption_enabled = true;
	
	return true;
}



static wi_boolean_t _wi_p7_password_is_equal(wi_string_t *password1, wi_string_t *password2) {
	const char			*cstring1, *cstring2;
	wi_uinteger_t		length1, length2, i;
	wi_boolean_t		result;
	
	length1		= wi_string_length(password1);
	length2		= wi_string_length(password2);
	
	if(length1 != length2)
		return false;
	
	cstring1	= wi_string_cstring(password1);
	cstring2	= wi_string_cstring(password2);
	result		= true;
	
	for(i = 0; i < length1; i++) {
		if(cstring1[i] != cstring2[i])
			result = false;
	}
	
	return result;
}

#endif



static wi_boolean_t _wi_p7_socket_send_compatibility_check(wi_p7_socket_t *p7_socket, wi_time_interval_t timeout) {
	wi_p7_message_t		*p7_message;
	wi_p7_boolean_t		status;

	p7_message = wi_p7_message_with_name(WI_STR("p7.compatibility_check.specification"), wi_p7_socket_spec(p7_socket));
	
	if(!p7_message)
		return false;
	
	if(!wi_p7_message_set_string_for_name(p7_message, wi_p7_spec_xml(p7_socket->spec), WI_STR("p7.compatibility_check.specification")))
		return false;

	if(!wi_p7_socket_write_message(p7_socket, timeout, p7_message))
		return false;

	p7_message = wi_p7_socket_read_message(p7_socket, timeout);
	
	if(!p7_message)
		return false;
	
	if(!wi_is_equal(p7_message->name, WI_STR("p7.compatibility_check.status"))) {
		wi_error_set_libwired_error_with_format(WI_ERROR_P7_HANDSHAKEFAILED,
			WI_STR("Message should be \"p7.compatibility_check.status\", not \"%@\""),
			p7_message->name);
		
		return false;
	}
	
	if(!wi_p7_message_get_bool_for_name(p7_message, &status, WI_STR("p7.compatibility_check.status"))) {
		wi_error_set_libwired_error_with_format(WI_ERROR_P7_HANDSHAKEFAILED,
			WI_STR("Message has no \"p7.compatibility_check.status\" field"));
		
		return false;
	}

	if(!status) {
		wi_error_set_libwired_error_with_format(WI_ERROR_P7_INCOMPATIBLESPEC,
			WI_STR("Remote protocol %@ %@ is not compatible with local protocol %@ %@"),
			p7_socket->remote_name,
			p7_socket->remote_version,
			wi_p7_spec_name(p7_socket->spec),
			wi_p7_spec_version(p7_socket->spec));
	}

	return status;
}



static wi_boolean_t _wi_p7_socket_receive_compatibility_check(wi_p7_socket_t *p7_socket, wi_time_interval_t timeout) {
	wi_string_t			*string;
	wi_p7_message_t		*p7_message;
	wi_p7_spec_t		*p7_spec;
	wi_boolean_t		compatible;
	
	p7_message = wi_p7_socket_read_message(p7_socket, timeout);
	
	if(!p7_message)
		return false;

	if(!wi_is_equal(p7_message->name, WI_STR("p7.compatibility_check.specification"))) {
		wi_error_set_libwired_error_with_format(WI_ERROR_P7_HANDSHAKEFAILED,
			WI_STR("Message should be \"p7.compatibility_check.specification\", not \"%@\""),
			p7_message->name);
		
		return false;
	}

	string = wi_p7_message_string_for_name(p7_message, WI_STR("p7.compatibility_check.specification"));
	
	if(!string) {
		wi_error_set_libwired_error_with_format(WI_ERROR_P7_HANDSHAKEFAILED,
			WI_STR("Message has no \"p7.compatibility_check.specification\" field"));
		
		return false;
	}
	
	p7_spec = wi_autorelease(wi_p7_spec_init_with_string(wi_p7_spec_alloc(), string,
		wi_p7_spec_opposite_originator(wi_p7_spec_originator(p7_socket->spec))));
	
	if(!p7_spec)
		return false;
	
	compatible = wi_p7_spec_is_compatible_with_spec(p7_socket->spec, p7_spec);
	
	if(compatible) {
		p7_socket->merged_spec = wi_copy(p7_socket->spec);

		wi_p7_spec_merge_with_spec(p7_socket->merged_spec, p7_spec);
	} else {
		wi_error_set_libwired_error_with_format(WI_ERROR_P7_INCOMPATIBLESPEC,
			WI_STR("Remote protocol %@ %@ is not compatible with local protocol %@ %@: %m"),
			p7_socket->remote_name,
			p7_socket->remote_version,
			wi_p7_spec_name(p7_socket->spec),
			wi_p7_spec_version(p7_socket->spec));
	}
	
	p7_message = wi_p7_message_with_name(WI_STR("p7.compatibility_check.status"), wi_p7_socket_spec(p7_socket));
	
	if(!p7_message)
		return false;
	
	if(!wi_p7_message_set_bool_for_name(p7_message, compatible, WI_STR("p7.compatibility_check.status")))
		return false;

	if(!wi_p7_socket_write_message(p7_socket, timeout, p7_message))
		return false;

	return compatible;
}



#pragma mark -

static wi_boolean_t _wi_p7_socket_write_binary_message(wi_p7_socket_t *p7_socket, wi_time_interval_t timeout, wi_p7_message_t *p7_message) {
	const void			*send_buffer;
	char				length_buffer[_WI_P7_SOCKET_LENGTH_SIZE];
	unsigned char		checksum_buffer[_WI_P7_CHECKSUM_OPTIONS_TO_LENGTH(p7_socket->options)];
	wi_integer_t		compressed_size;
#ifdef WI_RSA
	wi_integer_t		encrypted_size;
#endif	
	uint32_t			send_size;
	
	send_size	= p7_message->binary_size;
	send_buffer	= p7_message->binary_buffer;
	
	p7_socket->sent_raw_bytes += send_size;

	if(p7_socket->compression_enabled) {
		compressed_size = _wi_p7_socket_deflate(p7_socket, send_buffer, send_size);
		
		if(compressed_size < 0)
			return false;
		
		send_size	= compressed_size;
		send_buffer	= p7_socket->compression_buffer;
	}
	
#ifdef WI_RSA
	if(p7_socket->encryption_enabled) {
		encrypted_size = send_size + wi_cipher_block_size(p7_socket->cipher);
		
		if(!p7_socket->encryption_buffer) {
			p7_socket->encryption_buffer_length = encrypted_size;
			p7_socket->encryption_buffer = wi_malloc(p7_socket->encryption_buffer_length);
		}
		else if((wi_uinteger_t) encrypted_size > p7_socket->encryption_buffer_length) {
			p7_socket->encryption_buffer_length = encrypted_size * 2;
			p7_socket->encryption_buffer = wi_realloc(p7_socket->encryption_buffer, p7_socket->encryption_buffer_length);
		}
		
		encrypted_size = wi_cipher_encrypt_bytes(p7_socket->cipher,
												 send_buffer,
												 send_size,
												 p7_socket->encryption_buffer);
		
		if(encrypted_size < 0)
			return false;
		
		send_size	= encrypted_size;
		send_buffer	= p7_socket->encryption_buffer;
	}
#endif

	p7_socket->sent_processed_bytes += send_size;

	wi_write_swap_host_to_big_int32(length_buffer, 0, send_size);
	
	if(wi_socket_write_buffer(p7_socket->socket, timeout, length_buffer, sizeof(length_buffer)) < 0)
		return false;

	if(wi_socket_write_buffer(p7_socket->socket, timeout, send_buffer, send_size) < 0)
		return false;
	
	if(p7_socket->checksum_enabled) {
		_wi_p7_socket_checksum_binary_message(p7_socket, p7_message, checksum_buffer);
		
		if(wi_socket_write_buffer(p7_socket->socket, timeout, checksum_buffer, p7_socket->checksum_length) < 0)
			return false;
	}
	
	return true;
}



static wi_boolean_t _wi_p7_socket_write_xml_message(wi_p7_socket_t *p7_socket, wi_time_interval_t timeout, wi_p7_message_t *p7_message) {
	if(wi_socket_write_format(p7_socket->socket, timeout, WI_STR("%s\r\n"), p7_message->xml_buffer) < 0)
		return false;
	
	p7_socket->sent_raw_bytes += p7_message->xml_length;
	p7_socket->sent_processed_bytes += p7_message->xml_length;
	
	return true;
}



static wi_p7_message_t * _wi_p7_socket_read_binary_message(wi_p7_socket_t *p7_socket, wi_time_interval_t timeout, uint32_t message_size) {
	wi_p7_message_t		*p7_message;
	unsigned char		local_checksum_buffer[_WI_P7_CHECKSUM_OPTIONS_TO_LENGTH(p7_socket->options)];
	unsigned char		remote_checksum_buffer[_WI_P7_CHECKSUM_OPTIONS_TO_LENGTH(p7_socket->options)];
	wi_integer_t		decompressed_size;
#ifdef WI_RSA
	wi_integer_t		decrypted_size;
#endif
	int32_t				length;
	
	if(message_size > _WI_P7_SOCKET_MAX_BINARY_SIZE) {
		wi_error_set_libwired_error_with_format(WI_ERROR_P7_MESSAGETOOLARGE,
			WI_STR("%u bytes"), message_size);
		
		return NULL;
	}

	p7_message = wi_autorelease(wi_p7_message_init(wi_p7_message_alloc(), p7_socket->merged_spec ? p7_socket->merged_spec : p7_socket->spec));
	p7_message->binary_capacity = message_size;
	p7_message->binary_buffer = wi_malloc(p7_message->binary_capacity);
	
	length = wi_socket_read_buffer(p7_socket->socket, timeout, p7_message->binary_buffer, message_size);

	if(length <= 0)
		return NULL;
	
	p7_message->binary_size			= length;
	p7_socket->message_binary_size	= 0;
	p7_socket->read_raw_bytes		+= p7_message->binary_size;

#ifdef WI_RSA
	if(p7_socket->encryption_enabled) {
		//printf("wi_cipher_block_size: %d\n", (int)wi_cipher_block_size(p7_socket->cipher));

		decrypted_size = p7_message->binary_size + wi_cipher_block_size(p7_socket->cipher);
		
		if(!p7_socket->decryption_buffer) {
			p7_socket->decryption_buffer_length = decrypted_size;
			p7_socket->decryption_buffer = wi_malloc(p7_socket->decryption_buffer_length);
		}
		else if((wi_uinteger_t) decrypted_size > p7_socket->decryption_buffer_length) {
			p7_socket->decryption_buffer_length = decrypted_size * 2;
			p7_socket->decryption_buffer = wi_realloc(p7_socket->decryption_buffer, p7_socket->decryption_buffer_length);
		}
		
		decrypted_size = wi_cipher_decrypt_bytes(p7_socket->cipher,
												 p7_message->binary_buffer,
												 p7_message->binary_size,
												 p7_socket->decryption_buffer);
		
		if(decrypted_size < 0)
			return NULL;
		
		if((wi_uinteger_t) decrypted_size > p7_message->binary_capacity) {
			p7_message->binary_capacity = decrypted_size;
			p7_message->binary_buffer = wi_realloc(p7_message->binary_buffer, p7_message->binary_capacity);
		}
		
		memcpy(p7_message->binary_buffer, p7_socket->decryption_buffer, decrypted_size);
		
		p7_message->binary_size = decrypted_size;
	}
#endif
	
	if(p7_socket->compression_enabled) {
		decompressed_size = _wi_p7_socket_inflate(p7_socket, p7_message->binary_buffer, p7_message->binary_size);
		
		if(decompressed_size < 0)
			return NULL;
		
		if((wi_uinteger_t) decompressed_size > p7_message->binary_capacity) {
			p7_message->binary_capacity = decompressed_size;
			p7_message->binary_buffer = wi_realloc(p7_message->binary_buffer, p7_message->binary_capacity);
		}
		
		memcpy(p7_message->binary_buffer, p7_socket->compression_buffer, decompressed_size);
		
		p7_message->binary_size = decompressed_size;
	}

    // for(int i = 0; i < 1024; i++) {
    //     printf("%02x", p7_message->binary_buffer[i]);
    // }
    // printf("\n\n");
	
	p7_socket->read_processed_bytes += p7_message->binary_size;
	
	if(p7_socket->checksum_enabled) {
		length = wi_socket_read_buffer(p7_socket->socket, timeout, remote_checksum_buffer, p7_socket->checksum_length);
		
		if(length <= 0)
			return NULL;
		
		_wi_p7_socket_checksum_binary_message(p7_socket, p7_message, local_checksum_buffer);
		
		if(memcmp(remote_checksum_buffer, local_checksum_buffer, p7_socket->checksum_length) != 0) {
			wi_error_set_libwired_error(WI_ERROR_P7_CHECKSUMMISMATCH);
			
			return NULL;
		}
	}

	return p7_message;
}



static wi_p7_message_t * _wi_p7_socket_read_xml_message(wi_p7_socket_t *p7_socket, wi_time_interval_t timeout, wi_string_t *prefix) {
	wi_string_t			*string;
	wi_p7_message_t		*p7_message;
	wi_uinteger_t		length;
	
	p7_message = wi_autorelease(wi_p7_message_init(wi_p7_message_alloc(), p7_socket->merged_spec ? p7_socket->merged_spec : p7_socket->spec));
	
	string = wi_socket_read_to_string(p7_socket->socket, timeout, WI_STR("\r\n"));
	
	if(!string || wi_string_length(string) == 0)
		return NULL;
		
	p7_message->xml_string = wi_mutable_copy(wi_string_by_deleting_surrounding_whitespace(string));

	if(prefix)
		wi_mutable_string_insert_string_at_index(p7_message->xml_string, prefix, 0);
	
	length = wi_string_length(p7_message->xml_string);
	
	p7_socket->read_raw_bytes += length;
	p7_socket->read_processed_bytes += length;

	wi_mutable_string_delete_surrounding_whitespace(p7_message->xml_string);
	
	return p7_message;
}



#pragma mark -

static wi_boolean_t _wi_p7_socket_configure_compression(wi_p7_socket_t *p7_socket) {
	int		err;
	
	p7_socket->deflate_stream.data_type = Z_UNKNOWN;
	
	err = deflateInit(&p7_socket->deflate_stream, Z_DEFAULT_COMPRESSION);
	
	if(err != Z_OK) {
		wi_error_set_zlib_error(err);
		
		return false;
	}
	
	err = inflateInit(&p7_socket->inflate_stream);
	
	if(err != Z_OK) {
		wi_error_set_zlib_error(err);
		
		return false;
	}
	
	p7_socket->compression_enabled = true;
	
	return true;
}



static wi_integer_t _wi_p7_socket_deflate(wi_p7_socket_t *p7_socket, const void *in_buffer, uint32_t in_size) {
	wi_integer_t	bytes;
	size_t			length;
	int				err, enderr;
	
	length = (in_size * 2) + 16;

	if(!p7_socket->compression_buffer) {
		p7_socket->compression_buffer			= wi_malloc(length);
		p7_socket->compression_buffer_length	= length;
	}
	else if(p7_socket->compression_buffer_length < length) {
		p7_socket->compression_buffer			= wi_realloc(p7_socket->compression_buffer, length);
		p7_socket->compression_buffer_length	= length;
	}

	p7_socket->deflate_stream.next_in			= (unsigned char *) in_buffer;
	p7_socket->deflate_stream.avail_in			= in_size;
	p7_socket->deflate_stream.next_out			= p7_socket->compression_buffer;
	p7_socket->deflate_stream.avail_out			= p7_socket->compression_buffer_length;
	
	err		= deflate(&p7_socket->deflate_stream, Z_FINISH);
	bytes	= p7_socket->deflate_stream.total_out;
	enderr	= deflateReset(&p7_socket->deflate_stream);
	
	if(err != Z_STREAM_END) {
		if(err == Z_OK)
			wi_error_set_zlib_error(Z_BUF_ERROR);
		else
			wi_error_set_zlib_error(err);
		
		return -1;
	}
	
	if(enderr != Z_OK) {
		wi_error_set_zlib_error(err);
		
		return -1;
	}
	
	return bytes;
}



static wi_integer_t _wi_p7_socket_inflate(wi_p7_socket_t *p7_socket, const void *in_buffer, uint32_t in_size) {
	wi_uinteger_t	multiple, bytes;
	int				err, enderr;
	
	for(multiple = 2; multiple < 16; multiple++) {
		p7_socket->compression_buffer_length = in_size * (1 << multiple);

		if(!p7_socket->compression_buffer)
			p7_socket->compression_buffer = wi_malloc(p7_socket->compression_buffer_length);
		else
			p7_socket->compression_buffer = wi_realloc(p7_socket->compression_buffer, p7_socket->compression_buffer_length);

		p7_socket->inflate_stream.next_in		= (unsigned char *) in_buffer;
		p7_socket->inflate_stream.avail_in		= in_size;
		p7_socket->inflate_stream.next_out		= (unsigned char *) p7_socket->compression_buffer;
		p7_socket->inflate_stream.avail_out		= p7_socket->compression_buffer_length;
		
		err		= inflate(&p7_socket->inflate_stream, Z_FINISH);
		bytes	= p7_socket->inflate_stream.total_out;
		enderr	= inflateReset(&p7_socket->inflate_stream);
		
		if(err == Z_STREAM_END && enderr != Z_BUF_ERROR)
			break;
	}

	return bytes;
}



#pragma mark -

static void _wi_p7_socket_configure_checksum(wi_p7_socket_t *p7_socket) {	
	if(p7_socket->options & WI_P7_CHECKSUM_SHA1) {
		p7_socket->checksum_length = WI_SHA1_DIGEST_LENGTH;

		p7_socket->checksum_enabled = true;
	}
	else if(p7_socket->options & WI_P7_CHECKSUM_SHA256) {
		p7_socket->checksum_length = WI_SHA256_DIGEST_LENGTH;

		p7_socket->checksum_enabled = true;
	}
}



static void _wi_p7_socket_checksum_binary_message(wi_p7_socket_t *p7_socket, wi_p7_message_t *p7_message, void *out_buffer) {
	_wi_p7_socket_checksum_buffer(p7_socket, p7_message->binary_buffer, p7_message->binary_size, out_buffer);
}



static void _wi_p7_socket_checksum_buffer(wi_p7_socket_t *p7_socket, const void *buffer, uint32_t size, void *out_buffer) {
	if(p7_socket->options & WI_P7_CHECKSUM_SHA1)
		wi_sha1_digest(buffer, size, out_buffer);

	else if(p7_socket->options & WI_P7_CHECKSUM_SHA256)
		wi_sha256_digest(buffer, size, out_buffer);
}



static wi_string_t * _wi_p7_socket_string_checksum(wi_p7_socket_t *p7_socket, wi_string_t *string) {
	if(p7_socket->options & WI_P7_CHECKSUM_SHA1)
		return wi_string_sha1(string);

	else if(p7_socket->options & WI_P7_CHECKSUM_SHA256)
		return wi_string_sha256(string);

	return wi_string_sha1(string);
}



static wi_string_t * _wi_p7_socket_data_checksum(wi_p7_socket_t *p7_socket, wi_data_t *data) {
	if(p7_socket->options & WI_P7_CHECKSUM_SHA1)
		return wi_data_sha1(data);

	else if(p7_socket->options & WI_P7_CHECKSUM_SHA256)
		return wi_data_sha256(data);

	return wi_data_sha1(data);
}



#pragma mark -

wi_boolean_t wi_p7_socket_verify_message(wi_p7_socket_t *p7_socket, wi_p7_message_t *p7_message) {
	return wi_p7_spec_verify_message(p7_socket->merged_spec ? p7_socket->merged_spec : p7_socket->spec, p7_message);
}



#pragma mark -

wi_boolean_t wi_p7_socket_connect(wi_p7_socket_t *p7_socket, wi_time_interval_t timeout, wi_uinteger_t options, wi_p7_serialization_t serialization, wi_string_t *username, wi_string_t *password) {
	p7_socket->serialization = serialization;
        
	if(!_wi_p7_socket_connect_handshake(p7_socket, timeout, options))
		return false;
	
	if(WI_P7_COMPRESSION_ENABLED(p7_socket->options)) {
		if(!_wi_p7_socket_configure_compression(p7_socket))
			return false;
	}
	
	if(WI_P7_CHECKSUM_ENABLED(p7_socket->options))
		_wi_p7_socket_configure_checksum(p7_socket);

	
#ifdef WI_RSA
	if(WI_P7_ENCRYPTION_ENABLED(p7_socket->options)) {
		if(!_wi_p7_socket_connect_key_exchange(p7_socket, timeout, username, password))
			return false;
	}
#endif

	if(p7_socket->remote_compatibility_check) {
		if(!_wi_p7_socket_send_compatibility_check(p7_socket, timeout))
			return false;
	}
	
	if(p7_socket->local_compatibility_check) {
		if(!_wi_p7_socket_receive_compatibility_check(p7_socket, timeout))
			return false;
	}

	return true;
}



wi_boolean_t wi_p7_socket_accept(wi_p7_socket_t *p7_socket, wi_time_interval_t timeout, wi_uinteger_t options) {
	if(!_wi_p7_socket_accept_handshake(p7_socket, timeout, options))
		return false;
	
	if(WI_P7_COMPRESSION_ENABLED(p7_socket->options)) {
		if(!_wi_p7_socket_configure_compression(p7_socket))
			return false;
	}

	if(WI_P7_CHECKSUM_ENABLED(p7_socket->options))
		_wi_p7_socket_configure_checksum(p7_socket);
	
#ifdef WI_RSA
	if(WI_P7_ENCRYPTION_ENABLED(p7_socket->options)) {
		if(!_wi_p7_socket_accept_key_exchange(p7_socket, timeout))
			return false;
	}
#endif
	
	if(p7_socket->local_compatibility_check) {
		if(!_wi_p7_socket_receive_compatibility_check(p7_socket, timeout))
			return false;
	}

	if(p7_socket->remote_compatibility_check) {
		if(!_wi_p7_socket_send_compatibility_check(p7_socket, timeout))
			return false;
	}
	
	return true;
}



void wi_p7_socket_close(wi_p7_socket_t *p7_socket) {
}



#pragma mark -

wi_boolean_t wi_p7_socket_write_message(wi_p7_socket_t *p7_socket, wi_time_interval_t timeout, wi_p7_message_t *p7_message) {
	wi_boolean_t	result;
	
	wi_p7_message_serialize(p7_message, wi_p7_socket_serialization(p7_socket));
	
	if(wi_p7_socket_debug)
		wi_log_debug(WI_STR("Sending %@"), p7_message);
	
	if(p7_socket->serialization == WI_P7_BINARY)
		result = _wi_p7_socket_write_binary_message(p7_socket, timeout, p7_message);
	else
		result = _wi_p7_socket_write_xml_message(p7_socket, timeout, p7_message);
	
	if(!result)
		return false;
	
	if(wi_p7_socket_debug) {
		wi_log_debug(WI_STR("Sent %llu processed bytes, %llu raw bytes, compressed to %.2f%%"),
			p7_socket->sent_processed_bytes,
			p7_socket->sent_raw_bytes,
			((double) p7_socket->sent_processed_bytes / (double) p7_socket->sent_raw_bytes) * 100.0);
	}
	
	if(p7_socket->wrote_message_callback)
		(*p7_socket->wrote_message_callback)(p7_socket, p7_message, p7_socket->wrote_message_context);
	
	return true;
}



wi_p7_message_t * wi_p7_socket_read_message(wi_p7_socket_t *p7_socket, wi_time_interval_t timeout) {
	wi_p7_message_t		*p7_message;
	wi_string_t			*prefix = NULL;
	char				length_buffer[_WI_P7_SOCKET_LENGTH_SIZE];
	
	if(p7_socket->serialization == WI_P7_UNKNOWN || p7_socket->serialization == WI_P7_BINARY) {
		if(p7_socket->message_binary_size == 0) {
			if(wi_socket_read_buffer(p7_socket->socket, timeout, length_buffer, sizeof(length_buffer)) <= 0)
				return NULL;

			p7_socket->message_binary_size = wi_read_swap_big_to_host_int32(length_buffer, 0);
		}
		
		if(p7_socket->serialization == WI_P7_UNKNOWN) {
			if(p7_socket->message_binary_size == _WI_P7_SOCKET_XML_MAGIC) {
				p7_socket->serialization = WI_P7_XML;
				prefix = WI_STR("<?xm");
			}
			else if(p7_socket->message_binary_size < _WI_P7_SOCKET_MAX_BINARY_SIZE) {
				p7_socket->serialization = WI_P7_BINARY;
			}
		}
	}

	if(p7_socket->serialization == WI_P7_BINARY)
		p7_message = _wi_p7_socket_read_binary_message(p7_socket, timeout, p7_socket->message_binary_size);
	else if(p7_socket->serialization == WI_P7_XML)
		p7_message = _wi_p7_socket_read_xml_message(p7_socket, timeout, prefix);
	else {
		wi_error_set_libwired_error_with_format(WI_ERROR_P7_HANDSHAKEFAILED,
			WI_STR("Invalid data from remote host (%u doesn't look like a header)"),
			p7_socket->message_binary_size);
		
		return NULL;
	}
	
	if(!p7_message)
		return NULL;

	if(p7_socket->serialization == WI_P7_BINARY && p7_message->binary_size == 0) {
		wi_error_set_libwired_error_with_format(WI_ERROR_P7_INVALIDMESSAGE,
			WI_STR("Invalid data from remote host (%u doesn't look like a header)"),
			p7_socket->message_binary_size);
		
		return NULL;
	}
	
	wi_p7_message_deserialize(p7_message, p7_socket->serialization);
	
	if(wi_p7_socket_debug) {
		wi_log_debug(WI_STR("Received %@"), p7_message);

		wi_log_debug(WI_STR("Received %llu raw bytes, %llu processed bytes, compressed to %.2f%%"),
			p7_socket->read_raw_bytes,
			p7_socket->read_processed_bytes,
			((double) p7_socket->read_raw_bytes / (double) p7_socket->read_processed_bytes) * 100.0);
	}

	if(p7_socket->read_message_callback)
		(*p7_socket->read_message_callback)(p7_socket, p7_message, p7_socket->read_message_context);

	return p7_message;
}



wi_boolean_t wi_p7_socket_write_oobdata(wi_p7_socket_t *p7_socket, wi_time_interval_t timeout, const void *buffer, uint32_t size) {
	const void			*send_buffer;
	char				length_buffer[_WI_P7_SOCKET_LENGTH_SIZE];
	unsigned char		checksum_buffer[_WI_P7_CHECKSUM_OPTIONS_TO_LENGTH(p7_socket->options)];
	wi_integer_t		compressed_size;
#ifdef WI_RSA
	wi_integer_t		encrypted_size;
#endif
	uint32_t			send_size;
	
	send_size = size;
	send_buffer	= buffer;
	
	if(p7_socket->checksum_enabled)
		_wi_p7_socket_checksum_buffer(p7_socket, send_buffer, send_size, checksum_buffer);

	if(p7_socket->compression_enabled) {
		compressed_size = _wi_p7_socket_deflate(p7_socket, send_buffer, send_size);
		
		if(compressed_size < 0)
			return false;
		
		send_size	= compressed_size;
		send_buffer	= p7_socket->compression_buffer;
	}
	
#ifdef WI_RSA
	if(p7_socket->encryption_enabled) {
		encrypted_size = send_size + wi_cipher_block_size(p7_socket->cipher);
		
		if(!p7_socket->encryption_buffer) {
			p7_socket->encryption_buffer_length = encrypted_size;
			p7_socket->encryption_buffer = wi_malloc(p7_socket->encryption_buffer_length);
		}
		else if((wi_uinteger_t) encrypted_size > p7_socket->encryption_buffer_length) {
			p7_socket->encryption_buffer_length = encrypted_size * 2;
			p7_socket->encryption_buffer = wi_realloc(p7_socket->encryption_buffer, p7_socket->encryption_buffer_length);
		}
		
		encrypted_size = wi_cipher_encrypt_bytes(p7_socket->cipher,
												 send_buffer,
												 send_size,
												 p7_socket->encryption_buffer);
		
		if(encrypted_size < 0)
			return false;
		
		send_size	= encrypted_size;
		send_buffer = p7_socket->encryption_buffer;
	}
#endif

	wi_write_swap_host_to_big_int32(length_buffer, 0, send_size);

	if(wi_socket_write_buffer(p7_socket->socket, timeout, length_buffer, sizeof(length_buffer)) < 0)
		return false;

	if(wi_socket_write_buffer(p7_socket->socket, timeout, send_buffer, send_size) < 0)
		return false;

	if(p7_socket->checksum_enabled) {
		if(wi_socket_write_buffer(p7_socket->socket, timeout, checksum_buffer, p7_socket->checksum_length) < 0)
			return false;
	}
	
	return true;
}



wi_integer_t wi_p7_socket_read_oobdata(wi_p7_socket_t *p7_socket, wi_time_interval_t timeout, void **out_buffer) {
	void				*receive_buffer;
	char				length_buffer[_WI_P7_SOCKET_LENGTH_SIZE];
	unsigned char		local_checksum_buffer[_WI_P7_CHECKSUM_OPTIONS_TO_LENGTH(p7_socket->options)];
	unsigned char		remote_checksum_buffer[_WI_P7_CHECKSUM_OPTIONS_TO_LENGTH(p7_socket->options)];
	wi_integer_t		result, decompressed_size;
#ifdef WI_RSA
	wi_integer_t		decrypted_size;
#endif
	uint32_t			receive_size;
	
	result = wi_socket_read_buffer(p7_socket->socket, timeout, length_buffer, sizeof(length_buffer));
	
	if(result <= 0)
		return result;
	
	receive_size = wi_read_swap_big_to_host_int32(length_buffer, 0);
	
	if(receive_size > _WI_P7_SOCKET_MAX_BINARY_SIZE) {
		wi_error_set_libwired_error_with_format(WI_ERROR_P7_MESSAGETOOLARGE,
			WI_STR("%u bytes"), receive_size);
		
		return -1;
	}
	
	if(!p7_socket->oobdata_read_buffer) {
		p7_socket->oobdata_read_buffer_length = receive_size * 2;
		p7_socket->oobdata_read_buffer = wi_malloc(p7_socket->oobdata_read_buffer_length);
	}
	else if(receive_size > p7_socket->oobdata_read_buffer_length) {
		p7_socket->oobdata_read_buffer_length = receive_size * 2;
		p7_socket->oobdata_read_buffer = wi_realloc(p7_socket->oobdata_read_buffer, p7_socket->oobdata_read_buffer_length);
	}
	
	receive_buffer = p7_socket->oobdata_read_buffer;
	
	result = wi_socket_read_buffer(p7_socket->socket, timeout, receive_buffer, receive_size);
	
	if(result <= 0)
		return false;
	
#ifdef WI_RSA
	if(p7_socket->encryption_enabled) {
		decrypted_size = receive_size + wi_cipher_block_size(p7_socket->cipher);
		
		if(!p7_socket->decryption_buffer) {
			p7_socket->decryption_buffer_length = decrypted_size;
			p7_socket->decryption_buffer = wi_malloc(p7_socket->decryption_buffer_length);
		}
		else if((wi_uinteger_t) decrypted_size > p7_socket->decryption_buffer_length) {
			p7_socket->decryption_buffer_length = decrypted_size * 2;
			p7_socket->decryption_buffer = wi_realloc(p7_socket->decryption_buffer, p7_socket->decryption_buffer_length);
		}
		
		decrypted_size = wi_cipher_decrypt_bytes(p7_socket->cipher,
												 receive_buffer,
												 receive_size,
												 p7_socket->decryption_buffer);
		
		if(decrypted_size < 0)
			return -1;

		receive_size	= decrypted_size;
		receive_buffer	= p7_socket->decryption_buffer;
	}
#endif
	
	if(p7_socket->compression_enabled) {
		decompressed_size = _wi_p7_socket_inflate(p7_socket, receive_buffer, receive_size);
		
		if(decompressed_size < 0)
			return -1;

		receive_size	= decompressed_size;
		receive_buffer	= p7_socket->compression_buffer;
	}
	
	if(p7_socket->checksum_enabled) {
		result = wi_socket_read_buffer(p7_socket->socket, timeout, remote_checksum_buffer, p7_socket->checksum_length);
		
		if(result <= 0)
			return result;
		
		_wi_p7_socket_checksum_buffer(p7_socket, receive_buffer, receive_size, local_checksum_buffer);
		
		if(memcmp(remote_checksum_buffer, local_checksum_buffer, p7_socket->checksum_length) != 0) {
			wi_error_set_libwired_error(WI_ERROR_P7_CHECKSUMMISMATCH);
			
			return -1;
		}
	}
	
	*out_buffer = receive_buffer;
	
	return receive_size;
}

#endif
